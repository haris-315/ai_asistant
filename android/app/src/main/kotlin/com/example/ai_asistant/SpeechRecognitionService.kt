package com.example.ai_asistant

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.*
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.openai.OpenAIClient
import com.example.openai.SharedData
import com.example.tts_helper.TextToSpeechHelper
import com.example.svc_mng.ServiceManager

class SpeechRecognitionService : Service() {
    private lateinit var speechRecognizer: SpeechRecognizer
    private lateinit var recognizerIntent: Intent
    private var isListening = false
    private var isStandby = false
    private lateinit var audioManager: AudioManager
    private var originalSystemVolume: Int = -1

    private lateinit var openAIClient: OpenAIClient
    private lateinit var ttsHelper: TextToSpeechHelper

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForegroundService()

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        initializeSpeechRecognizer()

        openAIClient = OpenAIClient(
            apiKey = "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",
            authToken = SharedData.authToken,
            projects = SharedData.projects
        )

        ttsHelper = TextToSpeechHelper(this) {
            resumeListening()
        }
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
            .setContentTitle("Jarvis Assistant")
            .setContentText("Listening in standby mode")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .build()
        startForeground(1, notification)
    }

    private fun muteSystemSounds() {
        try {
            originalSystemVolume = audioManager.getStreamVolume(AudioManager.STREAM_SYSTEM)
            audioManager.setStreamVolume(AudioManager.STREAM_SYSTEM, 0, 0)
        } catch (e: Exception) {
            Log.e("SpeechRecognizer", "Error muting system sounds: ${e.message}")
        }
    }

    private fun restoreSystemSounds() {
        try {
            if (originalSystemVolume != -1) {
                audioManager.setStreamVolume(AudioManager.STREAM_SYSTEM, originalSystemVolume, 0)
            }
        } catch (e: Exception) {
            Log.e("SpeechRecognizer", "Error restoring system sounds: ${e.message}")
        }
    }

    private fun initializeSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                muteSystemSounds()
            }

            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {
                restoreSystemSounds()
            }

            override fun onError(error: Int) {
                restoreSystemSounds()
                resumeListening()
            }

            override fun onResults(results: Bundle?) {
                restoreSystemSounds()
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val text = matches?.firstOrNull()?.lowercase()?.trim()

                Log.d("SpeechRecognizer", "Recognized: $text")

                if (text == null) {
                    resumeListening()
                    return
                }

                ServiceManager.recognizedText = text

                when {
                    text.contains("hey jarvis") || text.contains("jarvis") || text.contains("hey") || text.contains("hi") || text.contains("hello") || text.contains("gpt") -> {
                        isStandby = false
                        ServiceManager.isStandBy = false
                        ttsHelper.speak("I'm listening")
                        Log.d("Jarvis", "Activated from standby")
                    }
                    text.contains("standby") || text.contains("sleep") || text.contains("bye") || text.contains("thank") -> {
                        isStandby = true
                        ServiceManager.isStandBy = true
                        ttsHelper.speak("Going into standby mode")
                        Log.d("Jarvis", "Switched to standby")
                    }
                    
                    !isStandby -> {
                        openAIClient.sendMessage(
                            text,
                            onResponse = { reply ->
                                Log.d("OpenAI", "Assistant: $reply")
                                ttsHelper.speak(reply)

                            },
                            onError = { error ->
                                Log.e("OpenAI", "Error: $error")
                                ttsHelper.speak("Sorry, there was a problem.")
                            }
                        )
                    }
                    else -> {
                        Log.d("Jarvis", "In standby, input ignored.")
                    }
                }
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
        Handler(Looper.getMainLooper()).post {
            speechRecognizer.startListening(recognizerIntent)
        }
    }

    private fun restartListening() {
        Handler(Looper.getMainLooper()).post {
            speechRecognizer.cancel()
            speechRecognizer.startListening(recognizerIntent)
        }
    }

    private fun resumeListening() {
        if (isListening) {
            Handler(Looper.getMainLooper()).post {
                restartListening()
            }
        }
    }

    private fun stopListening() {
        isListening = false
        Handler(Looper.getMainLooper()).post {
            speechRecognizer.stopListening()
            restoreSystemSounds()
        }
    }

    override fun onDestroy() {
        stopListening()
        speechRecognizer.destroy()
        restoreSystemSounds()
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }
}
