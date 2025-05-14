package com.example.ai_asistant

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.openai.SharedData
import android.net.Uri
import com.example.ai_asistant.SpeechRecognitionService

import com.example.svc_mng.ServiceManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ai_assistant/stt"
    private val EVENT_CHANNEL = "com.example.ai_assistant/stt_results"

    private lateinit var messenger: BinaryMessenger
    private lateinit var eventChannel: EventChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        messenger = flutterEngine.dartExecutor.binaryMessenger
        ServiceManager.serviceChannelName = CHANNEL
        ServiceManager.resultEventChannel = EVENT_CHANNEL

        // Method channel for control commands
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    val authToken = call.argument<String>("authToken") ?: ""
                    val projects = call.argument<List<String>>("projects")?.toMutableList() ?: mutableListOf()

                    SharedData.authToken = authToken
                    SharedData.projects = projects

                    ServiceManager.isBound = true
                    ServiceManager.isStoped = false
                    Log.d("MainActivity", "Received auth and projects")

                    if (checkAudioPermission()) {
                        checkBatteryOptimization()  // Ensure battery optimization is disabled
                        startSpeechService()
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "Audio recording permission denied", null)
                    }
                }

                "stopListening" -> {
                    ServiceManager.isStoped = true
                    ServiceManager.isBound = false
                    stopSpeechService()
                    result.success(true)
                }

                "getInfo" -> {

                    val rawTasks = call.argument<List<MutableMap<String, Any>>>("tasks")
                    val taskList = rawTasks ?: emptyList()
                  
           // val taskList = call.argument<List<MutableMapMap<String, Any>>>("tasks") ?: arrayOf() 

           if (SharedData.tasks != taskList) {
                    SharedData.tasks = taskList
           }

                Log.d("TaskListner: " ,"Recived Tasks: ${SharedData.tasks.toString()}")
                    result.success(mutableMapOf("isBound" to ServiceManager.isBound, "isStoped" to ServiceManager.isStoped, "isStandBy" to ServiceManager.isStandBy,"recognizedText" to ServiceManager.recognizedText,"channel" to ServiceManager.serviceChannelName, "result_channel" to ServiceManager.resultEventChannel))
                }

                "isListening" -> {
                    // Since we don’t bind, just return a generic true/false
                    val isRunning = isSpeechServiceRunning()
                    result.success(isRunning)
                }

                else -> result.notImplemented()
            }
        }

        // Event channel for sending recognition results
        eventChannel = EventChannel(messenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {

                SpeechResultListener.eventSink = events
                Log.d("MainActivity", "EventChannel listener attached")
            }

            override fun onCancel(arguments: Any?) {
                SpeechResultListener.eventSink = null
                Log.d("MainActivity", "EventChannel listener removed")
            }
        })
    }

    private fun checkAudioPermission(): Boolean {
        return if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            == PackageManager.PERMISSION_GRANTED) {
            true
        } else {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 1)
            false
        }
    }

    private fun checkBatteryOptimization() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        val packageName = packageName
        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        }
    }

    private fun startSpeechService() {
        val intent = Intent(this, SpeechRecognitionService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        Log.d("MainActivity", "Speech service started")
    }

    private fun stopSpeechService() {
        val intent = Intent(this, SpeechRecognitionService::class.java)
        stopService(intent)
        Log.d("MainActivity", "Speech service stopped")
    }

    private fun isSpeechServiceRunning(): Boolean {
        // Optional: implement check using ActivityManager if needed.
        return true
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1 && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startSpeechService()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("MainActivity", "Activity destroyed")
    }
}

object SpeechResultListener {
    var eventSink: EventChannel.EventSink? = null

    fun sendResult(text: String) {
        eventSink?.success(text)
        Log.d("SpeechResultListener", "Result sent to Flutter: $text")
    }

    fun sendError(error: String) {
        eventSink?.error("SPEECH_ERROR", error, null)
        Log.e("SpeechResultListener", "Error sent to Flutter: $error")
    }
}
