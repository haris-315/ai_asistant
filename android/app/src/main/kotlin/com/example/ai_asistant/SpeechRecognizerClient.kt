package com.example.ai_asistant

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.core.content.ContextCompat
import com.example.openai.OpenAIClient
import com.example.openai.SharedData
import com.example.svc_mng.ServiceManager
import com.example.tts_helper.TextToSpeechHelper
import java.lang.ref.WeakReference
import java.time.LocalDateTime
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.*
import okhttp3.*
import okio.ByteString.Companion.toByteString
import org.json.JSONObject

class SpeechRecognizerClient private constructor(context: Context) {

    companion object {
        @Volatile private var instance: SpeechRecognizerClient? = null

        fun getInstance(context: Context): SpeechRecognizerClient {
            return instance
                    ?: synchronized(this) {
                        instance
                                ?: SpeechRecognizerClient(context.applicationContext).also {
                                    instance = it
                                }
                    }
        }
    }

    private val contextRef = WeakReference(context.applicationContext)
    private val context: Context?
        get() = contextRef.get()
    private var ttsHelper: TextToSpeechHelper? = null

    private enum class AssistantState {
        STANDBY,
        LISTENING,
        PROCESSING,
        SPEAKING,
        MEETING
    }

    private var state = AssistantState.STANDBY
    private var isManualStandby = false
    private var audioRecord: AudioRecord? = null
    private var webSocket: WebSocket? = null
    private var audioJob: Job? = null
    private var isTtsSpeaking = false
    private val sampleRate = 16000
    private val bufferSize =
            AudioRecord.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
            ) * 2
    private val processingTimeoutMs = 30000L // Increased timeout for long responses
    private val connectionTimeoutMs = 10000L
    private val inactivityTimeoutMs = 45000L // Increased timeout to prevent premature standby
    private val maxReconnectAttempts = 3
    private var lastMeetingStartTime: LocalDateTime = LocalDateTime.now()
    private var reconnectAttempts = 0
    private val commandBuffer = StringBuilder()
    private val meetingTranscriptBuffer = StringBuilder()
    private val handler = Handler(Looper.getMainLooper())
    private val audioLock = Any()
    private val wakeResponses: List<String> =
        listOf(
            "Hello, how may I assist you today?",
            "What can I help you with?",
            "I'm here to assist—how can I support you?",
            "Please let me know how I can be of service.",
            "How may I be of assistance?",
            "At your service. What do you need?",
            "I’m ready to help. What would you like to do?",
            "What can I do for you today?",
            "How can I support you at this moment?",
            "Is there anything specific you'd like assistance with?",
            "I'm available—how may I help?",
            "Feel free to tell me what you need help with.",
            "How can I make your task easier today?",
            "Let me know how I can assist you effectively."
        )


    private var hwDetector: HotWordDetector? = null
    private var isProcessingLongResponse = false

    init {
        context?.let {
            // Initialize TTS on background thread
            ServiceManager.isWarmingTts = true
            ttsHelper =
                    TextToSpeechHelper(it) { voices ->
                        Log.d("TTS", "TTS speaking complete at ${System.currentTimeMillis()}")
                        isTtsSpeaking = false
                        if (ServiceManager.ttsVoices.isEmpty()) ServiceManager.ttsVoices = voices
                        ServiceManager.isWarmingTts = false
                        if (state == AssistantState.SPEAKING && !isManualStandby) {
                            transitionTo(AssistantState.LISTENING)
                        } else if (state == AssistantState.SPEAKING) {
                            transitionTo(AssistantState.STANDBY)
                        }
                    }
        }
    }

    val openAiClient by lazy {
        context?.let {
            OpenAIClient(
                    context = it,
                    apiKey = SharedData.openAiApiKey,
                    authToken = SharedData.authToken,
                    projects = SharedData.projects
            )
        }
    }

    private val client =
            OkHttpClient.Builder()
                    .connectTimeout(10, TimeUnit.SECONDS)
                    .readTimeout(0, TimeUnit.MILLISECONDS)
                    .pingInterval(30, TimeUnit.SECONDS)
                    .build()

    @SuppressLint("MissingPermission")
    fun initialize(onInitialized: (TextToSpeechHelper?) -> Unit) {


        ServiceManager.initializing = true
        context
                ?: run {
                    Log.e("SpeechRecognizerClient", "Context is null")
                    onInitialized(null)
                    return
                }
        if (ContextCompat.checkSelfPermission(context!!, Manifest.permission.RECORD_AUDIO) !=
                        PackageManager.PERMISSION_GRANTED
        ) {
            Log.e("SpeechRecognizerClient", "Microphone permission denied")
            ttsHelper?.speak("Please grant microphone permission.")
            onInitialized(null)
            return
        }

        CoroutineScope(Dispatchers.Main).launch {
            // Wait for TTS initialization
            if (!ttsHelper?.waitForInitialization(10000L)!!) {
                Log.e("SpeechRecognizerClient", "TTS initialization failed")
                ttsHelper?.speak("Text-to-speech setup failed.")
                onInitialized(null)
                return@launch
            }

            // Initialize HotWordDetector and wait for completion
            try {
                if (SharedData.porcupineAK.isNullOrBlank()) {
                    Log.e("SpeechRecognizerClient", "Picovoice access key is missing")
                    ttsHelper?.speak("Hotword detection key is missing.")
                    onInitialized(null)
                    return@launch
                }

                // Verify asset exists
                val assets = context!!.assets.list("")?.toList() ?: emptyList()
                if (!assets.contains("hey_jarvis.ppn")) {
                    Log.e(
                            "SpeechRecognizerClient",
                            "Hotword asset hey_jarvis.ppn not found in assets"
                    )
                    ttsHelper?.speak("Hotword detection asset missing.")
                    onInitialized(null)
                    return@launch
                }

                hwDetector =
                        HotWordDetector(context!!, "hey_jarvis.ppn") {
                            if (state == AssistantState.STANDBY) {
                                Log.d("HWD", "Hotword detected at ${System.currentTimeMillis()}")
                                isManualStandby = false
                                transitionTo(AssistantState.SPEAKING)
                                ttsHelper?.speak(wakeResponses.random())
                            }
                        }

                // Wait for HotWordDetector to initialize
                if (!hwDetector!!.waitForInitialization(10000L)) {
                    Log.e("SpeechRecognizerClient", "HotWordDetector initialization failed")
                    ttsHelper?.speak("Hotword detection setup failed.")
                    hwDetector = null
                    onInitialized(null)
                    return@launch
                }
            } catch (e: Exception) {
                Log.e("SpeechRecognizerClient", "HotWordDetector init failed: ${e.message}")
                ttsHelper?.speak("Hotword detection setup failed.")
                hwDetector = null
                onInitialized(null)
                return@launch
            }

            // Initialize AudioRecord
            try {
                synchronized(audioLock) {
                    audioRecord =
                            AudioRecord(
                                            MediaRecorder.AudioSource.VOICE_RECOGNITION,
                                            sampleRate,
                                            AudioFormat.CHANNEL_IN_MONO,
                                            AudioFormat.ENCODING_PCM_16BIT,
                                            bufferSize
                                    )
                                    .apply {
                                        if (state != AudioRecord.STATE_INITIALIZED) {
                                            Log.e(
                                                    "SpeechRecognizerClient",
                                                    "AudioRecord failed to initialize"
                                            )
                                            ttsHelper?.speak("Microphone access failed.")
                                            release()
                                            onInitialized(null)
                                            return@launch
                                        }
                                    }
                }
            } catch (e: Exception) {
                Log.e("SpeechRecognizerClient", "AudioRecord initialization error: ${e.message}")
                ttsHelper?.speak("Microphone setup failed.")
                onInitialized(null)
                return@launch
            }

            // Start HotWordDetector
            try {
                hwDetector?.start()
            } catch (e: Exception) {
                Log.e("SpeechRecognizerClient", "Hotword detection failed to start: ${e.message}")
                ttsHelper?.speak("Hotword detection setup failed.")
                onInitialized(null)
                return@launch
            }

            onInitialized(ttsHelper)
            transitionTo(AssistantState.STANDBY)
            ServiceManager.initializing = false
        }
    }

    fun shutdown() {
        audioJob?.cancel()
        stopAudioStreaming()
        webSocket?.close(1000, "Shutdown")
        webSocket = null
        SharedData.emails = mutableListOf()
        ttsHelper?.shutdown()
        hwDetector?.release()
        synchronized(audioLock) {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        }
        state = AssistantState.STANDBY
        isManualStandby = false
        reconnectAttempts = 0
        isTtsSpeaking = false
        isProcessingLongResponse = false
        commandBuffer.clear()
        meetingTranscriptBuffer.clear()
        ServiceManager.isStoped = true
        ServiceManager.isStandBy = true
        handler.removeCallbacksAndMessages(null)
        Log.i("SpeechRecognizerClient", "Shutdown complete")
    }

    private fun transitionTo(newState: AssistantState, fromManualStandby: Boolean = false) {
        if (state == newState) return
        Log.i("SpeechRecognizerClient", "State: $state -> $newState")

        // Cancel any pending inactivity timeouts when transitioning to non-standby states
        if (newState != AssistantState.STANDBY) {
            handler.removeCallbacksAndMessages(null)
        }

        state = newState

        when (newState) {
            AssistantState.STANDBY -> {
                stopAudioStreaming()
                if (fromManualStandby || isManualStandby) {
                    webSocket?.close(1000, "Manual standby")
                    webSocket = null
                }
                commandBuffer.clear()
                meetingTranscriptBuffer.clear()
                try {
                    hwDetector?.start()
                } catch (e: Exception) {
                    Log.e(
                            "SpeechRecognizerClient",
                            "Failed to start HotWordDetector in STANDBY: ${e.message}"
                    )
                    ttsHelper?.speak("Hotword detection failed.")
                }
                ServiceManager.isStandBy = true
                isProcessingLongResponse = false
            }
            AssistantState.LISTENING -> {
                hwDetector?.stop()
                ServiceManager.isStoped = false
                ServiceManager.isStandBy = false
                startSpeechRecognition()
                resetInactivityTimeout()
            }
            AssistantState.PROCESSING -> {
                stopAudioStreaming()
                isProcessingLongResponse = true
                handler.postDelayed(
                        {
                            if (state == AssistantState.PROCESSING) {
                                Log.w("SpeechRecognizerClient", "Processing timeout")
                                isProcessingLongResponse = false
                                ttsHelper?.speak("Processing took too long.")
                                transitionTo(AssistantState.LISTENING)
                            }
                        },
                        processingTimeoutMs
                )
                ServiceManager.isStoped = false
                ServiceManager.isStandBy = false
            }
            AssistantState.SPEAKING -> {
                stopAudioStreaming()
                isTtsSpeaking = true
                ServiceManager.isStoped = false
                ServiceManager.isStandBy = false
                isProcessingLongResponse = false
            }
            AssistantState.MEETING -> {
                hwDetector?.stop()
                meetingTranscriptBuffer.clear()
                ServiceManager.isStoped = false
                ServiceManager.isStandBy = false
                // Set longer silence threshold for meeting mode
                webSocket?.let {
                    val configMessage =
                            JSONObject().put("end_utterance_silence_threshold", 10000).toString()
                    it.send(configMessage)
                    Log.d(
                            "SpeechRecognizerClient",
                            "Sent end_utterance_silence_threshold: 10000ms for MEETING"
                    )
                }
                startSpeechRecognition()
                resetInactivityTimeout()
            }
        }
    }

    private fun resetInactivityTimeout() {
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed(
                {
                    if (state != AssistantState.STANDBY &&
                                    state != AssistantState.MEETING &&
                                    !isProcessingLongResponse
                    ) {
                        Log.d(
                                "SpeechRecognizerClient",
                                "Inactivity timeout, transitioning to STANDBY"
                        )
                        isManualStandby = false
                        ttsHelper?.speak("No activity detected. Going to standby.")
                        transitionTo(AssistantState.STANDBY)
                    } else if (isProcessingLongResponse) {
                        // Extend timeout if we're processing a long response
                        resetInactivityTimeout()
                    }
                },
                inactivityTimeoutMs
        )
    }

    @SuppressLint("MissingPermission")
    private fun startSpeechRecognition() {
        if (state != AssistantState.LISTENING && state != AssistantState.MEETING) return
        context ?: return

        synchronized(audioLock) {
            if (audioRecord == null || audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                try {
                    audioRecord?.release()
                    audioRecord =
                            AudioRecord(
                                            MediaRecorder.AudioSource.VOICE_RECOGNITION,
                                            sampleRate,
                                            AudioFormat.CHANNEL_IN_MONO,
                                            AudioFormat.ENCODING_PCM_16BIT,
                                            bufferSize
                                    )
                                    .apply {
                                        if (state != AudioRecord.STATE_INITIALIZED) {
                                            Log.e(
                                                    "SpeechRecognizerClient",
                                                    "AudioRecord failed to initialize"
                                            )
                                            ttsHelper?.speak("Microphone access failed.")
                                            release()
                                            transitionTo(AssistantState.STANDBY)
                                            return
                                        }
                                    }
                    Log.d("SpeechRecognizerClient", "AudioRecord recreated")
                } catch (e: Exception) {
                    Log.e(
                            "SpeechRecognizerClient",
                            "AudioRecord initialization error: ${e.message}"
                    )
                    ttsHelper?.speak("Microphone setup failed.")
                    transitionTo(AssistantState.STANDBY)
                    return
                }
            }
        }

        if (webSocket == null) {
            connectWebSocket()
        } else {
            startAudioStreaming()
        }
    }

    private fun connectWebSocket() {
        if (webSocket != null) {
            Log.d("SpeechRecognizerClient", "WebSocket already connected")
            if (state == AssistantState.LISTENING || state == AssistantState.MEETING)
                    startAudioStreaming()
            return
        }

        val request =
                Request.Builder()
                        .url(
                                "wss://api.assemblyai.com/v2/realtime/ws?sample_rate=$sampleRate&utterances=true"
                        )
                        .header("Authorization", SharedData.assemblyAIKey)
                        .build()

        val timeoutRunnable = Runnable {
            if (webSocket == null) {
                Log.e("SpeechRecognizerClient", "WebSocket connection timed out")
                ttsHelper?.speak("Connection timed out.")
                transitionTo(AssistantState.STANDBY)
            }
        }
        handler.postDelayed(timeoutRunnable, connectionTimeoutMs)

        try {
            client.newWebSocket(
                    request,
                    object : WebSocketListener() {
                        override fun onOpen(webSocket: WebSocket, response: Response) {
                            handler.removeCallbacks(timeoutRunnable)
                            Log.i(
                                    "SpeechRecognizerClient",
                                    "WebSocket connected at ${System.currentTimeMillis()}"
                            )
                            this@SpeechRecognizerClient.webSocket = webSocket
                            val threshold = if (state == AssistantState.MEETING) 10000 else 1000
                            val configMessage =
                                    JSONObject()
                                            .put("end_utterance_silence_threshold", threshold)
                                            .toString()
                            webSocket.send(configMessage)
                            Log.d(
                                    "SpeechRecognizerClient",
                                    "Sent end_utterance_silence_threshold: ${threshold}ms"
                            )
                            reconnectAttempts = 0
                            if (state == AssistantState.LISTENING || state == AssistantState.MEETING
                            )
                                    startAudioStreaming()
                        }

                        override fun onMessage(webSocket: WebSocket, text: String) {
                            if (state != AssistantState.LISTENING && state != AssistantState.MEETING
                            )
                                    return
                            try {
                                val json = JSONObject(text)
                                when (json.optString("message_type")) {
                                    "FinalTranscript" -> {
                                        val transcript = json.optString("text").trim()
                                        if (transcript.isNotEmpty()) {
                                            Log.i("SpeechRecognizerClient", "Final: $transcript")
                                            if (state == AssistantState.MEETING) {
                                                meetingTranscriptBuffer
                                                        .append(" ")
                                                        .append(transcript)
                                                Log.d(
                                                        "SpeechRecognizerClient",
                                                        "Meeting transcript: ${meetingTranscriptBuffer.toString()}"
                                                )
                                                if (transcript
                                                                .lowercase()
                                                                .contains("stop meeting mode") ||
                                                                transcript
                                                                        .lowercase()
                                                                        .contains(
                                                                                "stop meeting mood"
                                                                        )
                                                ) {
                                                    val fullTranscript =
                                                            meetingTranscriptBuffer
                                                                    .toString()
                                                                    .trim()
                                                    transitionTo(AssistantState.PROCESSING)
                                                    summarizeMeeting(fullTranscript)
                                                }
                                            } else {
                                                commandBuffer.append(" ").append(transcript)
                                                Log.d(
                                                        "SpeechRecognizerClient",
                                                        "Utterance finalized: ${commandBuffer.toString()}"
                                                )
                                                ServiceManager.recognizedText = transcript
                                                transitionTo(AssistantState.PROCESSING)
                                                processCommand(commandBuffer.toString().trim())
                                                commandBuffer.clear()
                                            }
                                            resetInactivityTimeout()
                                        }
                                    }
                                    "PartialTranscript" -> {
                                        val partial = json.optString("text").trim()
                                        if (partial.isNotEmpty()) {
                                            Log.d("SpeechRecognizerClient", "Partial: $partial")
                                            if (state == AssistantState.MEETING) {
                                                // Do not clear meetingTranscriptBuffer
                                            } else {
                                                commandBuffer.clear()
                                                commandBuffer.append(partial)
                                            }
                                        }
                                    }
                                }
                            } catch (e: Exception) {
                                Log.e("SpeechRecognizerClient", "Message parse error: ${e.message}")
                                if (state == AssistantState.LISTENING) {
                                    transitionTo(AssistantState.LISTENING)
                                }
                            }
                        }

                        override fun onFailure(
                                webSocket: WebSocket,
                                t: Throwable,
                                response: Response?
                        ) {
                            handler.removeCallbacks(timeoutRunnable)
                            Log.e("SpeechRecognizerClient", "WebSocket failure: ${t.message}")
                            this@SpeechRecognizerClient.webSocket = null
                            if (reconnectAttempts < maxReconnectAttempts &&
                                            (state == AssistantState.LISTENING ||
                                                    state == AssistantState.MEETING)
                            ) {
                                reconnectAttempts++
                                val delay = 1000L * (1 shl reconnectAttempts)
                                handler.postDelayed({ connectWebSocket() }, delay)
                            } else {
                                ttsHelper?.speak("Connection lost.")
                                transitionTo(AssistantState.STANDBY)
                            }
                        }

                        override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                            Log.i("SpeechRecognizerClient", "WebSocket closing: $reason")
                            this@SpeechRecognizerClient.webSocket = null
                            webSocket.close(1000, "Closing")
                        }

                        override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                            Log.i("SpeechRecognizerClient", "WebSocket closed: $reason")
                            this@SpeechRecognizerClient.webSocket = null
                        }
                    }
            )
        } catch (e: Exception) {
            Log.e("SpeechRecognizerClient", "WebSocket creation error: ${e.message}")
            ttsHelper?.speak("Connection failed.")
            transitionTo(AssistantState.STANDBY)
        }
    }

    private fun startAudioStreaming() {
        audioJob?.cancel()
        audioJob =
                CoroutineScope(Dispatchers.IO).launch {
                    var shouldStopStreaming = false
                    try {
                        synchronized(audioLock) {
                            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                                Log.e("SpeechRecognizerClient", "AudioRecord not initialized")
                                shouldStopStreaming = true
                                return@synchronized
                            }
                            audioRecord?.startRecording()
                                    ?: run {
                                        Log.e(
                                                "SpeechRecognizerClient",
                                                "Failed to start AudioRecord"
                                        )
                                        shouldStopStreaming = true
                                        return@synchronized
                                    }
                        }
                        if (shouldStopStreaming) {
                            CoroutineScope(Dispatchers.Main).launch {
                                ttsHelper?.speak("Microphone error.")
                                transitionTo(AssistantState.STANDBY)
                            }
                            return@launch
                        }
                        Log.i(
                                "SpeechRecognizerClient",
                                "Audio streaming started at ${System.currentTimeMillis()}"
                        )
                        val buffer = ByteArray(bufferSize)

                        while (isActive &&
                                (state == AssistantState.LISTENING ||
                                        state == AssistantState.MEETING) &&
                                webSocket != null &&
                                !isTtsSpeaking) {
                            val read = audioRecord?.read(buffer, 0, buffer.size) ?: -1
                            if (read > 0) {
                                if (webSocket?.send(buffer.copyOf(read).toByteString()) != true) {
                                    Log.w("SpeechRecognizerClient", "WebSocket send failed")
                                    break
                                }
                            } else if (read < 0) {
                                Log.e("SpeechRecognizerClient", "AudioRecord read error: $read")
                                break
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("SpeechRecognizerClient", "Audio streaming error: ${e.message}")
                        CoroutineScope(Dispatchers.Main).launch {
                            ttsHelper?.speak("Audio error.")
                            transitionTo(AssistantState.STANDBY)
                        }
                    } finally {
                        CoroutineScope(Dispatchers.Main).launch { stopAudioStreaming() }
                    }
                }
    }

    private fun stopAudioStreaming() {
        synchronized(audioLock) {
            try {
                audioRecord?.let {
                    if (it.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                        it.stop()
                        Log.d("SpeechRecognizerClient", "AudioRecord stopped")
                    }
                }
            } catch (e: IllegalStateException) {
                Log.w("SpeechRecognizerClient", "AudioRecord stop failed: ${e.message}")
            } finally {
                audioJob?.cancel()
                audioJob = null
                Log.d("SpeechRecognizerClient", "Audio streaming stopped")
            }
        }
    }

    private fun processCommand(transcript: String) {
        val transcriptLower = transcript.lowercase()
        if (transcriptLower.contains("meeting mode") || transcriptLower.contains("meeting mood")) {
            CoroutineScope(Dispatchers.Main).launch {
                ttsHelper?.speak("Entering meeting mode.")
                lastMeetingStartTime = LocalDateTime.now()
                transitionTo(AssistantState.MEETING)
            }
            return
        }

        openAiClient?.sendMessage(
                userMessage = transcript,
                onResponse = { response ->
                    CoroutineScope(Dispatchers.Main).launch {
                        if (state == AssistantState.STANDBY && isManualStandby) {
                            Log.d(
                                    "SpeechRecognizerClient",
                                    "Ignoring OpenAI response in STANDBY: $response"
                            )
                            return@launch
                        }
                        transitionTo(AssistantState.SPEAKING)
                        ttsHelper?.speak(response)
                    }
                },
                onError = { err ->
                    CoroutineScope(Dispatchers.Main).launch {
                        if (state == AssistantState.STANDBY && isManualStandby) {
                            Log.d("SpeechRecognizerClient", "Ignoring OpenAI error in STANDBY")
                            return@launch
                        }
                        transitionTo(AssistantState.SPEAKING)
                        ttsHelper?.speak("Sorry, I couldn't process that.")
                        Toast.makeText(context, "$err", Toast.LENGTH_LONG).show()
                    }
                },
                onStandBy = {
                    CoroutineScope(Dispatchers.Main).launch {
                        isManualStandby = true
                        ttsHelper?.speak("Entering standby mode.")
                        transitionTo(AssistantState.STANDBY, fromManualStandby = true)
                    }
                },
                onSummaryAsked = {
                    transitionTo(AssistantState.PROCESSING)
                    var chats = openAiClient?.getMessageHistory()?.drop(0)
                    summarizeMeeting(chats.toString(), forChat = true)
                }
        )
    }

    private fun summarizeMeeting(transcript: String, forChat: Boolean = false) {
        if (transcript.isBlank()) {
            Log.w("SpeechRecognizerClient", "Meeting transcript is empty, skipping summarization")
            ttsHelper?.speak("No data to summarize.")
            transitionTo(AssistantState.STANDBY)
            return
        }

        ttsHelper?.speak("Please Let me summarize the information.")

        openAiClient?.generateMeetingSummary(
                transcript = transcript,
                onDone = { title, summary, keypoints ->
                    CoroutineScope(Dispatchers.Main).launch {
                        Log.i("SpeechRecognizerClient", "Meeting summary: $summary")
//                        context?.let { ctx ->
//                            openAiClient?.dbHelper?.insertOrUpdateSummary(
//                                    id = UUID.randomUUID().toString(),
//                                    title = title,
//                                    startTime =
//                                            if (forChat) LocalDateTime.now()
//                                            else lastMeetingStartTime,
//                                    endTime = LocalDateTime.now(),
//                                    actualTranscript =
//                                            if (forChat)
//                                                    "This Summary is generated from the conversation with chat gpt so it has no transcript."
//                                            else transcript,
//                                    summary = summary,
//                                    keypoints = keypoints
//                            )
//                        }

                        ttsHelper?.speak("summary completed.")
                        transitionTo(AssistantState.STANDBY)
                    }
                },
                onError = {
                    CoroutineScope(Dispatchers.Main).launch {
                        Log.e("SpeechRecognizerClient", "Failed to summarize meeting")
                        ttsHelper?.speak(
                                "Sorry, I couldn't summarize the meeting but, the info is stored so you can later summarize it from the app."
                        )
                        transitionTo(AssistantState.STANDBY)
                    }
                },
        )
    }
}
