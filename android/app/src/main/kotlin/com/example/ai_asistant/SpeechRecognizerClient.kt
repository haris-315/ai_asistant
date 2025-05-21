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
import androidx.core.content.ContextCompat
import com.example.openai.OpenAIClient
import com.example.openai.SharedData
import com.example.svc_mng.ServiceManager
import com.example.tts_helper.TextToSpeechHelper
import kotlinx.coroutines.*
import okhttp3.*
import okio.ByteString.Companion.toByteString
import org.json.JSONObject
import java.lang.ref.WeakReference
import java.util.concurrent.TimeUnit

class SpeechRecognizerClient private constructor(context: Context) {

    companion object {
        @Volatile
        private var instance: SpeechRecognizerClient? = null

        fun getInstance(context: Context): SpeechRecognizerClient {
            return instance ?: synchronized(this) {
                instance ?: SpeechRecognizerClient(context.applicationContext).also { instance = it }
            }
        }
    }

    private val contextRef = WeakReference(context.applicationContext)
    private val context: Context? get() = contextRef.get()

    private enum class AssistantState {
        STANDBY, LISTENING, PROCESSING, SPEAKING
    }

    private var state = AssistantState.STANDBY
    private var audioRecord: AudioRecord? = null
    private var webSocket: WebSocket? = null
    private var audioJob: Job? = null
    private var isTtsSpeaking = false
    private val sampleRate = 16000
    private val bufferSize = AudioRecord.getMinBufferSize(
        sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
    ) * 2
    private val processingTimeoutMs = 10000L
    private val connectionTimeoutMs = 10000L
    private val inactivityTimeoutMs = 30000L
    private val maxReconnectAttempts = 3
    private var reconnectAttempts = 0
    private val commandBuffer = StringBuilder()
    private val handler = Handler(Looper.getMainLooper())
    private val audioLock = Any()
    private val wakeResponses: List<String> = listOf(
        "Hello, how can I assist you?",
        "What can I help you with today?",
        "Yes, I'm listening. Go ahead.",
        "Hey there! Need something?",
        "At your service. What do you need?",
        "How can I be of help?",
        "Ready when you are. What's on your mind?"
    )

    private var ttsHelper: TextToSpeechHelper? = null

    init {
        context?.let {
            ttsHelper = TextToSpeechHelper(it) { voices ->
                Log.d("TTS", "TTS speaking complete")
                isTtsSpeaking = false
                if (ServiceManager.ttsVoices.isEmpty()) ServiceManager.ttsVoices = voices
                if (state == AssistantState.SPEAKING) transitionTo(AssistantState.LISTENING)
            }

            CoroutineScope(Dispatchers.Main).launch {
                val initialized = ttsHelper?.waitForInitialization(3000L) ?: false
                if (!initialized) {
                    Log.w("SpeechRecognizerClient", "TTS preinitialization failed, retrying")
                    ttsHelper?.reinitialize()
                    ttsHelper?.waitForInitialization(3000L)
                }
            }
        }
    }

    private val hwDetector by lazy {
        context?.let {
            try {
                HotWordDetector(context = it, keywordAssetName = "hey_jarvis.ppn") {
    if (state == AssistantState.STANDBY) {
        Log.d("HWD", "Hotword detected!")

        // Ensure TTS is ready before transitioning
        CoroutineScope(Dispatchers.Main).launch {
            val ttsReady = ttsHelper?.waitForInitialization(2000L) == true
            if (ttsReady) {
                transitionTo(AssistantState.SPEAKING)
                ttsHelper?.speak(wakeResponses.random())
            } else {
                Log.e("HWD", "TTS still not ready. Cannot transition to SPEAKING.")
                ttsHelper?.reinitialize()
                ttsHelper?.waitForInitialization(2000L)
            }
        }
    }
}
            } catch (e: Exception) {
                Log.e("SpeechRecognizerClient", "Failed to initialize HotWordDetector: ${e.message}")
                null
            }
        }
    }

    private val openAiClient by lazy {
        context?.let {
            OpenAIClient(
                context = it,
                apiKey = "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",
                authToken = SharedData.authToken,
                projects = SharedData.projects
            )
        }
    }

    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(0, TimeUnit.MILLISECONDS)
        .build()

    fun initialize(onInitialized: (TextToSpeechHelper?) -> Unit) {
        ServiceManager.initializing = true
        context ?: run {
            Log.e("SpeechRecognizerClient", "Context is null")
            onInitialized(null)
            return
        }
        if (ContextCompat.checkSelfPermission(context!!, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.e("SpeechRecognizerClient", "Microphone permission denied")
            ttsHelper?.speak("Please grant microphone permission.")
            onInitialized(null)
            return
        }

        CoroutineScope(Dispatchers.Main).launch {
            // Start hotword detection
            try {
                hwDetector?.start() ?: run {
                    Log.e("SpeechRecognizerClient", "HotWordDetector is null")
                    ttsHelper?.speak("Hotword detection setup failed.")
                    onInitialized(null)
                    return@launch
                }
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
        ttsHelper?.shutdown()
        hwDetector?.stop()
        state = AssistantState.STANDBY
        reconnectAttempts = 0
        isTtsSpeaking = false
        commandBuffer.clear()
        ServiceManager.isStoped = true
        ServiceManager.isStandBy = true
        handler.removeCallbacksAndMessages(null)
        Log.i("SpeechRecognizerClient", "Shutdown complete")
    }

    private fun transitionTo(newState: AssistantState) {
        if (state == newState) return
        Log.i("SpeechRecognizerClient", "State: $state -> $newState")
        state = newState

        when (newState) {
            AssistantState.STANDBY -> {
                stopAudioStreaming()
                webSocket?.close(1000, "Standby")
                webSocket = null
                handler.removeCallbacksAndMessages(null)
                commandBuffer.clear()
                hwDetector?.start()
                ServiceManager.isStandBy = true
            }
            AssistantState.LISTENING -> {
                hwDetector?.stop()
                ServiceManager.isStoped = false
                ServiceManager.isStandBy = false
                startSpeechRecognition()
                resetInactivityTimeout()
            }
            AssistantState.PROCESSING -> {
                handler.postDelayed({
                    if (state == AssistantState.PROCESSING) {
                        Log.w("SpeechRecognizerClient", "Processing timeout, returning to LISTENING")
                        ttsHelper?.speak("Processing took too long. Returning to listening.")
                        transitionTo(AssistantState.LISTENING)
                    }
                }, processingTimeoutMs)
            }
            AssistantState.SPEAKING -> {
                isTtsSpeaking = true
                stopAudioStreaming()
            }
        }
    }

    private fun resetInactivityTimeout() {
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({
            if (state == AssistantState.LISTENING) {
                Log.d("SpeechRecognizerClient", "Inactivity timeout, transitioning to STANDBY")
                ttsHelper?.speak("No activity detected. Going to standby.")
                transitionTo(AssistantState.STANDBY)
            }
        }, inactivityTimeoutMs)
    }

    @SuppressLint("MissingPermission")
    private fun startSpeechRecognition() {
        if (state != AssistantState.LISTENING) return
        context ?: return

        try {
            synchronized(audioLock) {
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.VOICE_RECOGNITION,
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize
                ).apply {
                    if (state != AudioRecord.STATE_INITIALIZED) {
                        Log.e("SpeechRecognizerClient", "AudioRecord failed to initialize")
                        ttsHelper?.speak("Microphone access failed.")
                        transitionTo(AssistantState.STANDBY)
                        return
                    }
                }
            }
            connectWebSocket()
        } catch (e: Exception) {
            Log.e("SpeechRecognizerClient", "Speech recognition error: ${e.message}")
            ttsHelper?.speak("An error occurred.")
            transitionTo(AssistantState.STANDBY)
        }
    }

    private fun connectWebSocket() {
        if (webSocket != null) {
            Log.d("SpeechRecognizerClient", "WebSocket already connected")
            startAudioStreaming()
            return
        }

        val request = Request.Builder()
            .url("wss://api.assemblyai.com/v2/realtime/ws?sample_rate=$sampleRate&utterances=true")
            .header("Authorization", "4bc0912e299e44b6b3e8ecab340ea0b1")
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
            client.newWebSocket(request, object : WebSocketListener() {
                override fun onOpen(webSocket: WebSocket, response: Response) {
                    handler.removeCallbacks(timeoutRunnable)
                    Log.i("SpeechRecognizerClient", "WebSocket connected")
                    this@SpeechRecognizerClient.webSocket = webSocket
                    val configMessage = JSONObject().put("end_utterance_silence_threshold", 1500).toString()
                    webSocket.send(configMessage)
                    Log.d("SpeechRecognizerClient", "Sent end_utterance_silence_threshold: 1500ms")
                    reconnectAttempts = 0
                    if (state == AssistantState.LISTENING) startAudioStreaming()
                }

                override fun onMessage(webSocket: WebSocket, text: String) {
                    if (state != AssistantState.LISTENING) return
                    try {
                        val json = JSONObject(text)
                        when (json.optString("message_type")) {
                            "FinalTranscript" -> {
                                val transcript = json.optString("text").trim()
                                if (transcript.isNotEmpty()) {
                                    Log.i("SpeechRecognizerClient", "Final: $transcript")
                                    commandBuffer.append(" ").append(transcript)
                                    Log.d("SpeechRecognizerClient", "Utterance finalized: ${commandBuffer.toString()}")
                                    ServiceManager.recognizedText = transcript
                                    SpeechResultListener.sendResult(commandBuffer.toString())
                                    transitionTo(AssistantState.PROCESSING)
                                    processCommand(commandBuffer.toString().trim())
                                    commandBuffer.clear()
                                    resetInactivityTimeout()
                                }
                            }
                            "PartialTranscript" -> {
                                val partial = json.optString("text").trim()
                                if (partial.isNotEmpty()) {
                                    Log.d("SpeechRecognizerClient", "Partial: $partial")
                                    commandBuffer.clear()
                                    commandBuffer.append(partial)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("SpeechRecognizerClient", "Message parse error: ${e.message}")
                        transitionTo(AssistantState.LISTENING)
                    }
                }

                override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                    handler.removeCallbacks(timeoutRunnable)
                    Log.e("SpeechRecognizerClient", "WebSocket failure: ${t.message}")
                    this@SpeechRecognizerClient.webSocket = null
                    if (reconnectAttempts < maxReconnectAttempts && state == AssistantState.LISTENING) {
                        reconnectAttempts++
                        val delay = 1000L * (1 shl reconnectAttempts)
                        handler.postDelayed({ connectWebSocket() }, delay)
                    } else {
                        ttsHelper?.speak("Connection lost.")
                        transitionTo(AssistantState.STANDBY)
                    }
                }

                override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                    this@SpeechRecognizerClient.webSocket = null
                    webSocket.close(1000, "Closing")
                }
            })
        } catch (e: Exception) {
            Log.e("SpeechRecognizerClient", "WebSocket creation error: ${e.message}")
            ttsHelper?.speak("Connection failed.")
            transitionTo(AssistantState.STANDBY)
        }
    }

    private fun startAudioStreaming() {
        audioJob?.cancel()
        audioJob = CoroutineScope(Dispatchers.IO).launch {
            try {
                synchronized(audioLock) {
                    audioRecord?.startRecording() ?: return@launch
                }
                Log.i("SpeechRecognizerClient", "Audio streaming started")
                val buffer = ByteArray(bufferSize)

                while (isActive && state == AssistantState.LISTENING && webSocket != null && !isTtsSpeaking) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0) {
                        webSocket?.send(buffer.copyOf(read).toByteString())
                    }
                }
            } catch (e: Exception) {
                Log.e("SpeechRecognizerClient", "Audio streaming error: ${e.message}")
                withContext(Dispatchers.Main) {
                    ttsHelper?.speak("Audio error.")
                    transitionTo(AssistantState.LISTENING)
                }
            } finally {
                withContext(Dispatchers.Main) { stopAudioStreaming() }
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
                    it.release()
                    Log.d("SpeechRecognizerClient", "AudioRecord released")
                }
            } catch (e: IllegalStateException) {
                Log.w("SpeechRecognizerClient", "AudioRecord stop/release failed: ${e.message}")
            } finally {
                audioRecord = null
                audioJob?.cancel()
                audioJob = null
                Log.d("SpeechRecognizerClient", "Audio streaming fully stopped")
            }
        }
    }

    private fun processCommand(transcript: String) {
        if (transcript.lowercase().contains("standby")) {
            ttsHelper?.speak("Entering standby mode.")
            transitionTo(AssistantState.STANDBY)
            return
        }

        openAiClient?.sendMessage(
            userMessage = transcript,
            onResponse = { response ->
                CoroutineScope(Dispatchers.Main).launch {
                    transitionTo(AssistantState.SPEAKING)
                    ttsHelper?.speak(response)
                }
            },
            onError = {
                CoroutineScope(Dispatchers.Main).launch {
                    ttsHelper?.speak("Sorry, I couldn’t process that.")
                    transitionTo(AssistantState.LISTENING)
                }
            }
        )
    }
}
