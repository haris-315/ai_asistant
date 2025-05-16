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
import com.example.sp_client.SpeechRecognizerClient

class SpeechRecognitionService : Service() {

    private lateinit var recognizerClient: SpeechRecognizerClient
    private val channelId = "speech_service_channel"
    private val notificationId = 1

    override fun onCreate() {
        super.onCreate()
        recognizerClient = SpeechRecognizerClient.getInstance(applicationContext)
        createNotificationChannel()
        startForeground(notificationId, createNotification("Up & Running"))
        recognizerClient.initialize()
        Log.d("SpeechRecognitionService", "Service created and initialized")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("SpeechRecognitionService", "Service started with intent: $intent")
        // Ensure the service restarts if killed by the system
        return START_STICKY
    }

    override fun onDestroy() {
        recognizerClient.shutdown()
        stopForeground(STOP_FOREGROUND_REMOVE)
        Log.d("SpeechRecognitionService", "Service destroyed")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Speech Recognition",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notification for Speech Recognition Service"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(text: String): Notification {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
                .setContentTitle("Voice Assistant Running")
                .setContentText(text)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Voice Assistant")
                .setContentText(text)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build()
        }
    }

    fun updateNotification(text: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, createNotification(text))
        Log.d("SpeechRecognitionService", "Notification updated: $text")
    }
}