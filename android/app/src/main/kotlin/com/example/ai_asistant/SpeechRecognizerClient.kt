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
    private var hasSpokenConnectMessage = false
    private val sampleRate = 16000
    private val bufferSize = AudioRecord.getMinBufferSize(
        sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
    ) * 2
    private val silenceThreshold = 500
    private val silenceTimeoutMs = 4000L
    private val processingTimeoutMs = 10000L
    private val connectionTimeoutMs = 10000L
    private val maxReconnectAttempts = 3
    private var reconnectAttempts = 0
    private val handler = Handler(Looper.getMainLooper())
    private val audioLock = Any() // Synchronization lock for audioRecord

    private val ttsHelper by lazy {
        context?.let {
            TextToSpeechHelper(it) { voices ->
                Log.d("TTS", "TTS speaking complete")
                isTtsSpeaking = false
                if (ServiceManager.ttsVoices.isEmpty()) ServiceManager.ttsVoices = voices
                if (state == AssistantState.SPEAKING) transitionTo(AssistantState.LISTENING)
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
        context ?: return
        if (ContextCompat.checkSelfPermission(context!!, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.e("SpeechRecognizerClient", "Microphone permission denied")
            ttsHelper?.speak("Please grant microphone permission.")
            return
        }

        CoroutineScope(Dispatchers.Main).launch {
            if (!ttsHelper?.waitForInitialization(5000L)!!) {
                Log.w("SpeechRecognizerClient", "TTS initialization failed, retrying")
                ttsHelper?.reinitialize()
                if (!ttsHelper?.waitForInitialization(5000L)!!) {
                    Log.e("SpeechRecognizerClient", "TTS initialization failed")
                    ttsHelper?.speak("Text-to-speech setup failed.")
                    return@launch
                }
            }
            onInitialized(ttsHelper)
            transitionTo(AssistantState.LISTENING)
        }
    }

    fun shutdown() {
        audioJob?.cancel()
        stopAudioStreaming()
        webSocket?.close(1000, "Shutdown")
        webSocket = null
        ttsHelper?.shutdown()
        state = AssistantState.STANDBY
        hasSpokenConnectMessage = false
        reconnectAttempts = 0
        isTtsSpeaking = false
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
            }
            AssistantState.LISTENING -> {
                ServiceManager.isStoped = false
                ServiceManager.isStandBy = false
                startSpeechRecognition()
            }
            AssistantState.PROCESSING -> {
                // Add timeout to prevent getting stuck
                handler.postDelayed({
                    if (state == AssistantState.PROCESSING) {
                        Log.w("SpeechRecognizerClient", "Processing timeout, returning to LISTENING")
                        transitionTo(AssistantState.LISTENING)
                    }
                }, processingTimeoutMs)
            }
            AssistantState.SPEAKING -> {
                isTtsSpeaking = true
                synchronized(audioLock) {
                    audioRecord?.stop()
                }
            }
        }
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

        if (!hasSpokenConnectMessage) {
            CoroutineScope(Dispatchers.Main).launch {
                ttsHelper?.speak("Please wait while I connect.")
                hasSpokenConnectMessage = true
            }
        }

        val request = Request.Builder()
            .url("wss://api.assemblyai.com/v2/realtime/ws?sample_rate=$sampleRate")
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
                                    // Filter known TTS phrases
                                    if (transcript.equals("Please wait while I connect.", ignoreCase = true) ||
                                        transcript.equals("An error occurred.", ignoreCase = true) ||
                                        transcript.equals("Connection timed out.", ignoreCase = true) ||
                                        transcript.equals("Text-to-speech setup failed.", ignoreCase = true)
                                    ) {
                                        Log.d("SpeechRecognizerClient", "Ignoring TTS output: $transcript")
                                        transitionTo(AssistantState.LISTENING)
                                        return
                                    }
                                    ServiceManager.recognizedText = transcript
                                    com.example.ai_asistant.SpeechResultListener.sendResult(transcript)
                                    transitionTo(AssistantState.PROCESSING)
                                    processCommand(transcript)
                                }
                            }
                            "PartialTranscript" -> {
                                val partial = json.optString("text").trim()
                                if (partial.isNotEmpty()) {
                                    Log.d("SpeechRecognizerClient", "Partial: $partial")
                                    ServiceManager.recognizedText = partial
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
                    if (read > 0 && !isSilence(buffer, read)) {
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

    private fun isSilence(buffer: ByteArray, bytesRead: Int): Boolean {
        for (i in 0 until bytesRead step 2) {
            val sample = (buffer[i].toInt() and 0xFF) or (buffer[i + 1].toInt() shl 8)
            if (abs(sample) > silenceThreshold) return false
        }
        return true
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