package com.example.ai_asistant

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

class SpeechRecognitionService : Service(), SpeechRecognizerClient.Callback {

    private lateinit var recognizerClient: SpeechRecognizerClient
    private val channelId = "speech_service_channel"
    private val notificationId = 1

    override fun onCreate() {
        super.onCreate()
        recognizerClient = SpeechRecognizerClient(applicationContext, this)
        createNotificationChannel()
        startForeground(notificationId, createNotification("Initializing..."))

        recognizerClient.initialize { startRecognition() }
    }

    private fun startRecognition() {
        recognizerClient.startRecognition()
        updateNotification("Listening for speech...")
    }

    private fun stopRecognition() {
        recognizerClient.stopRecognition()
        updateNotification("Recognition stopped.")
    }

    override fun onDestroy() {
        super.onDestroy()
        recognizerClient.shutdown()
        stopForeground(true)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                    NotificationChannel(
                            channelId,
                            "Speech Recognition",
                            NotificationManager.IMPORTANCE_LOW
                    )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(text: String): Notification {
        val builder =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Notification.Builder(this, channelId)
                            .setContentTitle("Voice Assistant Running")
                            .setContentText(text)
                            .setSmallIcon(R.mipmap.ic_launcher) // ✅ Safe built-in icon
                            .setOngoing(true)
                } else {
                    @Suppress("DEPRECATION")
                    Notification.Builder(this)
                            .setContentTitle("Voice Assistant Running")
                            .setContentText(text)
                            .setSmallIcon(R.mipmap.ic_launcher)
                            .setOngoing(true)
                }

        return builder.build()
    }

    private fun updateNotification(text: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, createNotification(text))
    }

    // Vosk Recognition Callbacks
    override fun onSpeechResult(text: String) {
        Log.i("SpeechService", "Final Result: $text")
        SpeechResultListener.sendResult(text)
    }

    override fun onSpeechPartial(text: String) {
        Log.i("SpeechService", "Partial: $text")
        SpeechResultListener.sendResult(text)
    }

    override fun onSpeechError(error: String) {
        Log.e("SpeechService", "Error: $error")
        SpeechResultListener.sendError(error)
    }
}
