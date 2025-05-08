package com.example.ai_asistant

import android.app.*
import android.content.Intent
import android.os.*
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.openai.OpenAIClient
import com.example.openai.SharedData // ✅ Import shared object
import com.example.tts_helper.TextToSpeechHelper

class SpeechRecognitionService : Service() {
    private lateinit var speechRecognizer: SpeechRecognizer
    private var isListening = false
    private lateinit var recognizerIntent: Intent
    private lateinit var openAIClient: OpenAIClient
    private lateinit var ttsHelper: TextToSpeechHelper
    inner class LocalBinder : Binder() {
        fun getService(): SpeechRecognitionService = this@SpeechRecognitionService
    }

    private val binder = LocalBinder()

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForegroundService()
        initializeSpeechRecognizer()

        // ✅ Initialize OpenAIClient with API key, authToken, and projects
        openAIClient = OpenAIClient(
            apiKey = "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",
            authToken = SharedData.authToken,
            projects = SharedData.projects
        )
        ttsHelper = TextToSpeechHelper(this)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "speech_recognition_channel",
                "Speech Recognition",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }

    private fun startForegroundService() {
        val notification: Notification = NotificationCompat.Builder(this, "speech_recognition_channel")
            .setContentTitle("Speech Recognition")
            .setContentText("Listening for voice commands")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .build()
        startForeground(1, notification)
    }

    private fun initializeSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}

            override fun onError(error: Int) {
                if (isListening) restartListening()
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    val userMessage = matches[0]
                    Log.d("SpeechRecognizer", "Recognized: $userMessage")

                    openAIClient.sendMessage(
                        userMessage,
                        onResponse = { reply ->
                            Log.d("OpenAI", "Assistant: $reply")
                            ttsHelper.speak(reply)

                        },
                        onError = { error ->
                            Log.e("OpenAI", "Error: $error")
                        }
                    )

                    SpeechResultListener.sendResult(userMessage)
                }
                if (isListening) restartListening()
            }

            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
            putExtra("android.speech.extra.DICTATION_MODE", true)
        }

        startListening()
    }

    private fun startListening() {
        isListening = true
        speechRecognizer.startListening(recognizerIntent)
    }

    private fun restartListening() {
        speechRecognizer.cancel()
        speechRecognizer.startListening(recognizerIntent)
    }

    private fun stopListening() {
        isListening = false
        speechRecognizer.stopListening()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopListening()
        speechRecognizer.destroy()
    }
}
