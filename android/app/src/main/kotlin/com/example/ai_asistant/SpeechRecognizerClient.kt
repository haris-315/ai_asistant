package com.example.sp_client

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import androidx.core.content.ContextCompat
import com.example.ai_asistant.HotWordDetector
import com.example.openai.OpenAIClient
import com.example.openai.SharedData
import com.example.svc_mng.ServiceManager
import com.example.tts_helper.TextToSpeechHelper
import kotlinx.coroutines.*
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString.Companion.toByteString

class SpeechRecognizerClient(private val context: Context) {

    private var openAiClient: OpenAIClient =
            OpenAIClient(
                    context = context,
                    apiKey = "",
                    authToken = SharedData.authToken,
                    projects = SharedData.projects
            )
    private var ttsHelper: TextToSpeechHelper =
            TextToSpeechHelper(
                    context = context,
                    {
                        Log.d("TextToSpeechHelper", "Message: Speech Done!")
                        resumeListening()
                    }
            )
    private var hotWordDetector: HotWordDetector =
            HotWordDetector(
                    context = context,
                    keywordAssetName = "hey_jarvis.ppn",
                    onWakeWordDetected = {
                        Log.i("Porcupine", "Hot Word Detected!")
                        standbyMode = false
                        ServiceManager.isStandBy = false
                        ttsHelper.speak("Hello! How can I help you today?")
                        startSpeechRecognition()
                    }
            )
    private var audioRecord: AudioRecord? = null
    private var webSocket: WebSocket? = null
    private var standbyMode = true
    private val sampleRate = 16000
    private val bufferSize =
            AudioRecord.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
            )

    private val apiKey = ""
    private val client = OkHttpClient()

    fun initialize() {
        try {
            hotWordDetector.start()
            Log.i("Porcupine", "Hot Word Detection Started...")
        } catch (e: Exception) {
            Log.e("SpeechRecognizerClient", "Initialization error: ${e.message}")
        }
    }

    fun shutdown() {
        hotWordDetector.stop()
        ServiceManager.isStoped = true
        ServiceManager.isStandBy = true
        stopSpeechRecognition()
        webSocket?.close(1000, "Client shutdown")
    }

    private fun startSpeechRecognition() {
        ServiceManager.isStoped = false
        if (standbyMode) return

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) !=
                        PackageManager.PERMISSION_GRANTED
        ) {
            Log.e("SpeechRecognizerClient", "RECORD_AUDIO permission not granted")
            return
        }

        try {
            audioRecord =
                    AudioRecord(
                            MediaRecorder.AudioSource.MIC,
                            sampleRate,
                            AudioFormat.CHANNEL_IN_MONO,
                            AudioFormat.ENCODING_PCM_16BIT,
                            bufferSize
                    )

            val request =
                    Request.Builder()
                            .url("wss://api.assemblyai.com/v2/realtime/ws?sample_rate=$sampleRate")
                            .header("Authorization", apiKey)
                            .build()

            client.newWebSocket(
                    request,
                    object : WebSocketListener() {
                        override fun onOpen(webSocket: WebSocket, response: okhttp3.Response) {
                            Log.i("SpeechRecognizerClient", "WebSocket connection established")
                            this@SpeechRecognizerClient.webSocket = webSocket
                            CoroutineScope(Dispatchers.IO).launch {
                                audioRecord?.startRecording()
                                hotWordDetector.stop()
                                Log.i("SpeechRecognizerClient", "Started listening")

                                val buffer = ByteArray(bufferSize)
                                while (!standbyMode) {
                                    val bytesRead = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                                    if (bytesRead > 0) {
                                        webSocket.send(buffer.toByteString(0, bytesRead))
                                    }
                                }
                            }
                        }

                        override fun onMessage(webSocket: WebSocket, text: String) {
                            try {
                                val json = org.json.JSONObject(text)
                                val messageType = json.optString("message_type", "")
                                if (messageType == "FinalTranscript") {
                                    val transcript = json.optString("text", "").trim()
                                    if (transcript.isNotEmpty()) {
                                        Log.i(
                                                "SpeechRecognizerClient",
                                                "Final Transcript: $transcript"
                                        )

                                        // Pause audio input during processing
                                        audioRecord?.stop()

                                        // Stop hotword detection just in case
                                        hotWordDetector.stop()

                                        // Send user message to OpenAI and handle response
                                        openAiClient.sendMessage(
                                                userMessage = transcript,
                                                onResponse = { response ->
                                                    CoroutineScope(Dispatchers.Main).launch {
                                                        Log.d(
                                                                "SpeechRecognizerClient",
                                                                "OpenAI Response: $response"
                                                        )

                                                        // Speak the response synchronously
                                                        ttsHelper.speak(response)
                                                    }
                                                },
                                                onError = { error ->
                                                    Log.e(
                                                            "SpeechRecognizerClient",
                                                            "OpenAI Error: $error"
                                                    )
                                                    resumeListening()
                                                }
                                        )
                                    }
                                } else {
                                    Log.d(
                                            "SpeechRecognizerClient",
                                            "Partial or irrelevant message ignored"
                                    )
                                }
                            } catch (e: Exception) {
                                Log.e(
                                        "SpeechRecognizerClient",
                                        "Failed to parse WebSocket message: ${e.message}"
                                )
                            }
                        }

                        override fun onFailure(
                                webSocket: WebSocket,
                                t: Throwable,
                                response: okhttp3.Response?
                        ) {
                            Log.e("SpeechRecognizerClient", "WebSocket error: ${t.message}")
                            resetToStandby()
                        }

                        override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                            webSocket.close(1000, null)
                        }
                    }
            )
        } catch (e: Exception) {
            Log.e("SpeechRecognizerClient", "Failed to start listening: ${e.message}")
            resetToStandby()
        }
    }

    private fun stopSpeechRecognition() {
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
    }
    private fun resumeListening() {
        standbyMode = false
        ServiceManager.isStandBy = false
        ServiceManager.isStoped = false

        CoroutineScope(Dispatchers.IO).launch {
            try {
                audioRecord?.startRecording()
                Log.i("SpeechRecognizerClient", "Resumed audio recording")

                val buffer = ByteArray(bufferSize)
                while (!standbyMode) {
                    val bytesRead = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (bytesRead > 0) {
                        webSocket?.send(buffer.toByteString(0, bytesRead))
                    }
                }
            } catch (e: Exception) {
                Log.e("SpeechRecognizerClient", "Error resuming listening: ${e.message}")
                resetToStandby()
            }
        }
    }

    private fun resetToStandby() {
        CoroutineScope(Dispatchers.Main).launch {
            standbyMode = true
            ServiceManager.isStandBy = true
            ServiceManager.isStoped = true
            stopSpeechRecognition()
            hotWordDetector.start()
            Log.i("SpeechRecognizerClient", "Returned to standby mode")
        }
    }
}
