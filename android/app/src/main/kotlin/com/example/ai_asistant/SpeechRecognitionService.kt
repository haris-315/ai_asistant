package com.example.ai_asistant

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import com.example.openai.SharedData
import com.example.tts_helper.TextToSpeechHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.Duration
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

class SpeechRecognitionService : Service() {

    private lateinit var recognizerClient: SpeechRecognizerClient
    private val channelId = "speech_service_channel"
    private val notificationId = 1
    private lateinit var ttsHelper: TextToSpeechHelper

    override fun onCreate() {
        super.onCreate()
        recognizerClient = SpeechRecognizerClient.getInstance(applicationContext)
        createNotificationChannel()
        startForeground(notificationId, createNotification("Up & Running"))
        recognizerClient.initialize(onInitialized = { tts ->
            if (tts != null)
                ttsHelper = tts
            startNotifier()
        })
        Log.d("SpeechRecognitionService", "Service created and initialized")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("SpeechRecognitionService", "Service started with intent: $intent")
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
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notification for Speech Recognition Service"
                setShowBadge(true)
                enableVibration(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private var notifierJob: Job? = null

    private fun startNotifier() {
        if (notifierJob?.isActive == true) return

        notifierJob = CoroutineScope(Dispatchers.IO).launch {
            val notifiedTasks = mutableSetOf<String>()

            while (true) {
                val now = Instant.now()

                SharedData.tasks.forEach { task ->
                    val reminderAt = task["reminder_at"] as? String ?: return@forEach
                    val content = task["content"] as? String ?: "Reminder"

                    if (notifiedTasks.contains(reminderAt)) return@forEach

                    try {
                        val reminderTime = Instant.parse(reminderAt)
                        val secondsDiff = Duration.between(now, reminderTime).seconds

                        if (secondsDiff in -15..15) {
                            sendTaskNotification(content)
                            ttsHelper.speak("Reminder: $content is due soon")
                            notifiedTasks.add(reminderAt)
                            Log.d("Notifier", "Sent reminder for task: $content at $reminderAt")
                        }
                    } catch (e: Exception) {
                        Log.e("Notifier", "Error parsing reminder time: $reminderAt", e)
                    }
                }

                delay(5000)
            }
        }
    }

    private fun sendTaskNotification(message: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = Notification.Builder(this, channelId)
            .setContentTitle("Task Reminder")
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_HIGH)
            .setDefaults(Notification.DEFAULT_SOUND or Notification.DEFAULT_VIBRATE)
            .build()

        val id = (SystemClock.uptimeMillis() % Int.MAX_VALUE).toInt()
        manager.notify(id, notification)
    }

    private fun createNotification(text: String): Notification {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
                .setContentTitle("Voice Assistant Running")
                .setContentText(text)
                .setSmallIcon(R.drawable.ic_launcher_foreground)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Voice Assistant")
                .setContentText(text)
                .setSmallIcon(R.drawable.ic_launcher_foreground)
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