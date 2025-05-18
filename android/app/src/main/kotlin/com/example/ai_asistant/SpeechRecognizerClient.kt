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
import kotlin.math.abs

class SpeechRecognizerClient private constructor(context: Context) {

    companion object {

        var instance: SpeechRecognizerClient? = null

        fun getInstance(context: Context): SpeechRecognizerClient {
            return instance ?: synchronized(this) {
                instance ?: SpeechRecognizerClient(context.applicationContext).also { instance = it }
            }
        }
    }

    private val contextRef = WeakReference(context.applicationContext)
    private val context: Context?
        get() = contextRef.get()

    private enum class AssistantState {
        STANDBY, LISTENING, PROCESSING, SPEAKING
    }

    private var state: AssistantState = AssistantState.STANDBY // Start in STANDBY to ensure clean initialization
    private var audioRecord: AudioRecord? = null
    private var webSocket: WebSocket? = null
    private var job: Job? = null
    private var silenceStartTime: Long = 0
    private var isSendingAudio = false
    private val sampleRate = 16000
    private val bufferSize = AudioRecord.getMinBufferSize(
        sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
    ) * 2
    private val silenceThreshold = 200
    private val silenceTimeoutMs = 5000L
    private val commandTimeoutMs = 15000L
    private val reconnectDelayMs = 1000L
    private val maxReconnectAttempts = 3
    private var reconnectAttempts = 0

    private val openAiClient by lazy {
        context?.let {
            OpenAIClient(
                context = it,
                apiKey = "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",
                authToken = SharedData.authToken,
                projects = SharedData.projects,
            )
        }
    }

    private val ttsHelper by lazy {
        context?.let {
            TextToSpeechHelper(it) { voices ->
                Log.d("TTS", "TTS done, transitioning to LISTENING")
                if (ServiceManager.ttsVoices.isEmpty()) {
                    ServiceManager.ttsVoices = voices
                    Log.d("Voices", "Available voices are: ${ServiceManager.ttsVoices.toString()} and from getter ${voices.toString()}")
                }
                if (state == AssistantState.SPEAKING) {
                    transitionTo(AssistantState.LISTENING)
                }
            }
        }
    }

    private val client = OkHttpClient.Builder()
        .readTimeout(0, TimeUnit.MILLISECONDS)
        .build()

    private val handler = Handler(Looper.getMainLooper())

    fun initialize(onInitialized: (TextToSpeechHelper) -> Unit) {
        context?.let { it ->
            if (ContextCompat.checkSelfPermission(it, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                Log.e("SpeechRecognizerClient", "RECORD_AUDIO permission not granted")
                ttsHelper?.speak("Please grant microphone permission.")
                return
            }

            CoroutineScope(Dispatchers.Main).launch {
                // Ensure TTS is initialized
                if (!ttsHelper?.waitForInitialization(5000L)!!) {
                    Log.w("SpeechRecognizerClient", "TTS not ready after timeout, reinitializing")
                    ttsHelper?.reinitialize()
                    // Wait again after reinitialization
                    if (!ttsHelper?.waitForInitialization(5000L)!!) {
                        Log.e("SpeechRecognizerClient", "TTS initialization failed")
                        ttsHelper?.speak("Sorry, text-to-speech initialization failed.")
                        return@launch
                    }
                }

                // Force a clean start
                if (state == AssistantState.LISTENING) {
                    Log.d("SpeechRecognizerClient", "Already in LISTENING, ensuring audio streaming")
                    stopSpeechRecognition() // Stop any existing audio streaming
                    startSpeechRecognition() // Restart to ensure WebSocket and audio are active
                } else {
                    Log.i("SpeechRecognizerClient", "Initialized in STANDBY mode")
                    transitionTo(AssistantState.LISTENING)
                }
                ttsHelper?.let { onInitialized(it) }
            }
        }
    }

    fun stateSpeaking() {
        transitionTo(AssistantState.SPEAKING)
    }

    fun shutdown() {
        job?.cancel()
        stopSpeechRecognition()
        webSocket?.close(1000, "Client shutdown")
        webSocket = null
        ttsHelper?.shutdown()
        state = AssistantState.STANDBY
        ServiceManager.isStoped = true
        ServiceManager.isStandBy = true
        reconnectAttempts = 0 // Reset reconnect attempts
        Log.i("SpeechRecognizerClient", "Shutdown complete")
    }

    private fun transitionTo(newState: AssistantState) {
        if (state == newState) {
            Log.d("SpeechRecognizerClient", "Already in state $newState")
            return
        }

        Log.i("SpeechRecognizerClient", "Transitioning from $state to $newState")
        state = newState

        when (newState) {
            AssistantState.STANDBY -> {
                stopSpeechRecognition()
                ttsHelper?.stop()
                webSocket?.close(1000, "Entering standby")
                webSocket = null
                ServiceManager.isStandBy = true
                isSendingAudio = false
            }

            AssistantState.LISTENING -> {
                ServiceManager.isStandBy = false
                ServiceManager.isStoped = false
                startSpeechRecognition()
            }

            AssistantState.PROCESSING -> {
                stopSpeechRecognition()
                isSendingAudio = false
            }

            AssistantState.SPEAKING -> {
                stopSpeechRecognition()
                isSendingAudio = false
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun startSpeechRecognition() {
        if (state != AssistantState.LISTENING) {
            Log.d("SpeechRecognizerClient", "Cannot start speech recognition, state: $state")
            return
        }

        context?.let {
            try {
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.VOICE_RECOGNITION,
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize
                )
                ServiceManager.recognizedText = ""

                if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                    Log.e("SpeechRecognizerClient", "AudioRecord initialization failed")
                    ttsHelper?.speak("Sorry, I couldn't access the microphone.")
                    transitionTo(AssistantState.STANDBY)
                    return
                }

                if (webSocket != null) {
                    Log.d("SpeechRecognizerClient", "WebSocket already connected, starting audio streaming")
                    startAudioStreaming()
                } else {
                    connectWebSocket()
                }
            } catch (e: Exception) {
                Log.e("SpeechRecognizerClient", "Failed to start speech recognition: ${e.message}")
                ttsHelper?.speak("Sorry, something went wrong.")
                transitionTo(AssistantState.STANDBY)
            }
        }
    }

    private fun connectWebSocket() {
        CoroutineScope(Dispatchers.Main).launch {
            // Ensure TTS is ready before speaking
            if (!ttsHelper?.waitForInitialization(5000L)!!) {
                Log.w("SpeechRecognizerClient", "TTS not ready for connect message, reinitializing")
                ttsHelper?.reinitialize()
            }
            ttsHelper?.speak("Please wait while I connect.")
        }

        val request = Request.Builder()
            .url("wss://api.assemblyai.com/v2/realtime/ws?sample_rate=$sampleRate")
            .header("Authorization", "4bc0912e299e44b6b3e8ecab340ea0b1")
            .build()

        client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                Log.i("SpeechRecognizerClient", "WebSocket connected")
                this@SpeechRecognizerClient.webSocket = webSocket
                reconnectAttempts = 0
                ServiceManager.initializing = false
                if (state == AssistantState.LISTENING) {
                    startAudioStreaming()
                }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                try {
                    if (state != AssistantState.LISTENING) {
                        Log.d("SpeechRecognizerClient", "Ignoring WebSocket message in state: $state")
                        return
                    }
                    val json = JSONObject(text)
                    val type = json.optString("message_type")
                    if (type == "FinalTranscript") {
                        val transcript = json.optString("text").trim()
                        if (transcript.isNotEmpty()) {
                            Log.i("SpeechRecognizerClient", "Final Transcript: $transcript")
                            ServiceManager.recognizedText = transcript
                            com.example.ai_asistant.SpeechResultListener.sendResult(transcript)
                            transitionTo(AssistantState.PROCESSING)
                            processCommand(transcript)
                        }
                    } else if (type == "PartialTranscript") {
                        val partial = json.optString("text").trim()
                        if (partial.isNotEmpty()) {
                            ServiceManager.recognizedText = partial
                            Log.d("SpeechRecognizerClient", "Partial Transcript: $partial")
                        }
                    }
                } catch (e: Exception) {
                    Log.e("SpeechRecognizerClient", "Failed to parse WebSocket message: ${e.message}")
                    com.example.ai_asistant.SpeechResultListener.sendError("Failed to parse WebSocket message")
                    transitionTo(AssistantState.LISTENING)
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e("SpeechRecognizerClient", "WebSocket error: ${t.message}")
                this@SpeechRecognizerClient.webSocket = null
                if (reconnectAttempts < maxReconnectAttempts) {
                    reconnectAttempts++
                    val delay = reconnectDelayMs * (1 shl reconnectAttempts)
                    handler.postDelayed({ connectWebSocket() }, delay)
                } else {
                    ttsHelper?.speak("Connection lost. Returning to standby.")
                    com.example.ai_asistant.SpeechResultListener.sendError("WebSocket connection lost")
                    transitionTo(AssistantState.STANDBY)
                }
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                webSocket.close(1000, null)
                this@SpeechRecognizerClient.webSocket = null
            }
        })
    }

    private fun startAudioStreaming() {
        job?.cancel()
        job = CoroutineScope(Dispatchers.IO + SupervisorJob()).launch {
            try {
                audioRecord?.startRecording()
                Log.i("SpeechRecognizerClient", "Audio streaming started")
                isSendingAudio = true
                silenceStartTime = 0
                val buffer = ByteArray(bufferSize)
                var hasSpeech = false // Track if we've detected any speech

                while (isActive && state == AssistantState.LISTENING && audioRecord != null) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0 && isSendingAudio) {
                        webSocket?.send(buffer.toByteString(0, read))

                        if (isSilence(buffer, read)) {
                            if (silenceStartTime == 0L) silenceStartTime = System.currentTimeMillis()

                            // Only consider processing if we've had speech before
                            if (hasSpeech && System.currentTimeMillis() - silenceStartTime >= silenceTimeoutMs) {
                                Log.d("SpeechRecognizerClient", "Natural pause in speech detected")
                                // Let the WebSocket handle the final transcript
                                silenceStartTime = 0L
                                hasSpeech = false
                            }
                        } else {
                            hasSpeech = true
                            silenceStartTime = 0L
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("SpeechRecognizerClient", "Audio streaming error: ${e.message}")
                withContext(Dispatchers.Main) {
                    ttsHelper?.speak("Sorry, an error occurred.")
                    com.example.ai_asistant.SpeechResultListener.sendError("Audio streaming error")
                    transitionTo(AssistantState.LISTENING)
                }
            } finally {
                withContext(Dispatchers.Main) {
                    stopAudioStreaming()
                }
            }
        }
    }

    private fun isSilence(buffer: ByteArray, bytesRead: Int): Boolean {
        for (i in 0 until bytesRead step 2) {
            val sample = (buffer[i].toInt() and 0xFF) or (buffer[i + 1].toInt() shl 8)
            if (abs(sample) > silenceThreshold) return false
        }
        return true
    }

    private fun processCommand(transcript: String) {
        if (transcript.lowercase().contains("standby")) {
            Log.i("SpeechRecognizerClient", "Standby command detected")
            ttsHelper?.speak("Going to standby mode.")
            transitionTo(AssistantState.STANDBY)
            return
        }

        openAiClient?.sendMessage(
            userMessage = transcript,
            onResponse = { response ->
                CoroutineScope(Dispatchers.Main).launch {
                    Log.d("SpeechRecognizerClient", "OpenAI response: $response")
                    transitionTo(AssistantState.SPEAKING)
                    // Ensure TTS is ready before speaking
                    if (!ttsHelper?.waitForInitialization(5000L)!!) {
                        Log.w("SpeechRecognizerClient", "TTS not ready, reinitializing")
                        ttsHelper?.reinitialize()
                        if (!ttsHelper?.waitForInitialization(5000L)!!) {
                            Log.e("SpeechRecognizerClient", "TTS initialization failed")
                            ttsHelper?.speak("Sorry, text-to-speech initialization failed.")
                            transitionTo(AssistantState.LISTENING)
                            return@launch
                        }
                    }
                    ttsHelper?.speak(response)
                }
            },
            onError = { error ->
                Log.e("SpeechRecognizerClient", "OpenAI error: $error")
                com.example.ai_asistant.SpeechResultListener.sendError("OpenAI error: $error")
                CoroutineScope(Dispatchers.Main).launch {
                    // Ensure TTS is ready before speaking error
                    if (!ttsHelper?.waitForInitialization(5000L)!!) {
                        Log.w("SpeechRecognizerClient", "TTS not ready, reinitializing")
                        ttsHelper?.reinitialize()
                    }
                    ttsHelper?.speak("Sorry, I couldn't process your request.")
                    transitionTo(AssistantState.LISTENING)
                }
            }
        )
    }

    private fun stopSpeechRecognition() {
        isSendingAudio = false
        job?.cancel()
        job = null
        stopAudioStreaming()
    }

    private fun stopAudioStreaming() {
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        Log.d("SpeechRecognizerClient", "Audio streaming stopped")
    }

    fun interrupt() {
        if (state == AssistantState.SPEAKING) {
            ttsHelper?.stop()
            transitionTo(AssistantState.LISTENING)
        }
    }
}