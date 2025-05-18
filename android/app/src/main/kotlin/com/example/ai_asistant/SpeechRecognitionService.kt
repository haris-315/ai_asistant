package com.example.ai_asistant
import android.os.SystemClock
import kotlinx.coroutines.delay
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.Duration
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import com.example.openai.SharedData
import com.example.tts_helper.TextToSpeechHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId

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
        recognizerClient.initialize(onInitialized = {tts -> ttsHelper = tts
            startNotifier()})
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

    private fun startNotifier() {
        CoroutineScope(Dispatchers.IO).launch {
            val notifiedTasks = mutableSetOf<String>() // Track notified task IDs or reminder strings

            while (true) {
                val now = Instant.now()

                SharedData.tasks.forEach { task ->
                    val reminderAt = task["reminder_at"] as? String ?: return@forEach
                    val content = task["content"] as? String ?: "Reminder"

                    // Use a unique ID (reminderAt or task["id"] if available)
                    if (notifiedTasks.contains(reminderAt)) return@forEach

                    try {
                        val reminderTime = LocalDateTime.parse(
                            reminderAt,
                            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS")
                        ).atZone(ZoneId.systemDefault()).toInstant()

                        val secondsDiff = Duration.between(now, reminderTime).seconds

                        if (secondsDiff in -15..15) {
                            sendSilentNotification(content)
                            recognizerClient.stateSpeaking()
                            ttsHelper.speak("You have an upcoming task in 10 minutes, $content")
                            notifiedTasks.add(reminderAt) // Mark as notified
                            Log.d("Notifier", "Sent reminder for task: $content")
                        }

                    } catch (e: Exception) {
                        Log.e("Notifier", "Error parsing reminder time: $reminderAt", e)
                    }
                }

                delay(5000) // Check every 5 seconds
            }
        }
    }
    private fun sendSilentNotification(message: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val silentNotification = Notification.Builder(this, channelId)
            .setContentTitle("Task Reminder")
            .setContentText(message)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_LOW)
            .setDefaults(0) // No sound or vibration
            .build()

        val id = (SystemClock.uptimeMillis() % Int.MAX_VALUE).toInt()
        manager.notify(id, silentNotification)
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