package com.example.ai_asistant

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.openai.SharedData


class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ai_assistant/stt"
    private val EVENT_CHANNEL = "com.example.ai_assistant/stt_results"
    
    private lateinit var messenger: BinaryMessenger
    private lateinit var eventChannel: EventChannel
    
    // Service connection variables
    private var isServiceBound = false
    private var speechRecognitionService: SpeechRecognitionService? = null
    
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as SpeechRecognitionService.LocalBinder
            speechRecognitionService = binder.getService()
            isServiceBound = true
            Log.d("MainActivity", "Service connected")
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            isServiceBound = false
            speechRecognitionService = null
            Log.d("MainActivity", "Service disconnected")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        messenger = flutterEngine.dartExecutor.binaryMessenger
        
        // Method Channel for commands
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    val authToken = call.argument<String>("authToken") ?: ""
                    val projects = call.argument<List<String>>("projects")?.toMutableList() ?: mutableListOf()

                    // ✅ Set shared data before starting the service
                    SharedData.authToken = authToken
                    SharedData.projects = projects
                    Log.d("SPS", "Received Data: $authToken ${projects.toString()}")
                    if (checkAudioPermission()) {
                        startService()
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "Audio recording permission denied", null)
                    }
                }
                "stopListening" -> {
                    stopService()
                    result.success(true)
                }
                "isListening" -> {
                    result.success(isServiceBound && speechRecognitionService != null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Event Channel for results
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

    private fun startService() {

        val serviceIntent = Intent(this, SpeechRecognitionService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
        bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)
        Log.d("MainActivity", "Service started")
    }

    private fun stopService() {
        val serviceIntent = Intent(this, SpeechRecognitionService::class.java)
        try {
            if (isServiceBound) {
                unbindService(serviceConnection)
                isServiceBound = false
            }
            stopService(serviceIntent)
            speechRecognitionService = null
            Log.d("MainActivity", "Service stopped")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error stopping service", e)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1 && grantResults.isNotEmpty() && 
            grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startService()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopService()
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