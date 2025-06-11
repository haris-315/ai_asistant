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
import android.widget.Toast
import com.example.openai.NetworkHelper
import com.example.svc_mng.ServiceManager
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ai_assistant/stt"
    private val PERMISSION_REQUEST_CODE = 1

    private lateinit var messenger: BinaryMessenger
    private lateinit var eventChannel: EventChannel
    val mainScope = CoroutineScope(Dispatchers.Main + Job())


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        messenger = flutterEngine.dartExecutor.binaryMessenger
        ServiceManager.serviceChannelName = CHANNEL
        val mc = MethodChannel(messenger, CHANNEL)
        // Method channel for control commands
        mc.setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    if (SharedData.openAiApiKey.isEmpty() || SharedData.assemblyAIKey.isEmpty()) {
                        Toast.makeText(context, "API keys not set", Toast.LENGTH_SHORT).show()
                        result.error("NO_API_KEY", "OpenAI API key not set", null)
                        return@setMethodCallHandler
                    }
                    val authToken = call.argument<String>("authToken") ?: ""
                    val projects = call.argument<List<String>>("projects")?.toMutableList() ?: mutableListOf()

                    SharedData.authToken = authToken
                    SharedData.projects = projects

                    ServiceManager.isBound = true
                    ServiceManager.isStoped = false
                    Log.d("MainActivity", "Received auth and projects: authToken=$authToken, projects=$projects")

                    if (checkAudioPermission()) {
                        checkBatteryOptimization()
                        startSpeechService()
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "Audio recording permission denied", null)
                    }
                }

                "stopListening" -> {
                    Log.w("MainActivity", "stopListening called from Flutter")
                    ServiceManager.isStoped = true
                    ServiceManager.isBound = false
                    stopSpeechService()
                    result.success(true)
                }

                "setPorcupineKey" -> {
                    val key = call.argument<String>("akey") ?: ""
                    SharedData.porcupineAK = key

                    val keywordAsset = "hey_jarvis.ppn"

                    mainScope.launch {
                        val isValid = withContext(Dispatchers.IO) {
                            HotWordDetector.checkKey(context, key, keywordAsset)
                        }

                        result.success(
                            mapOf(
                                "success" to isValid,
                                "msg" to if (isValid)
                                    "Key format is corrected but not guaranteed that it will be accepted by the server because there is a possibility that this key might have expired."
                                else
                                    "Key is Expired!"
                            )
                        )
                    } }
                "getInfo" -> {
                    val rawTasks = call.argument<List<MutableMap<String, Any>>>("tasks")
                    val taskList = rawTasks ?: emptyList()

                    if (SharedData.tasks.hashCode() != taskList.hashCode() && SharedData.tasks.size < taskList.size) {
                        SharedData.tasks = taskList
                        Log.d("TaskListener", "Received Tasks: ${SharedData.tasks}")
                    }

                    result.success(
                        ServiceManager.toMap()
                    )
                }

                "isListening" -> {
                    val isRunning = isSpeechServiceRunning()
                    result.success(isRunning)
                }

                "getVoices" -> {
                    Log.d("GetVoices", "Sending ${ServiceManager.ttsVoices.toString()}")
                    result.success(ServiceManager.ttsVoices.map { voice -> mutableMapOf("name" to voice.name, "locale" to voice.locale.displayName, "isOnline" to voice.isNetworkConnectionRequired,"latency" to voice.latency) }.toList())
                }
                "setVoice" -> {
                    SharedData.currentVoice = ServiceManager.ttsVoices.first { voice ->
                        voice.name == call.argument<String>("voice")
                    }
                    stopSpeechService()
                    startSpeechService()
                    result.success(emptyList<Map<String, Any>>())
                }
                "getDbPath" -> {
                    val dbPath = context.getDatabasePath("meeting.db").parentFile?.path
                    result.success(dbPath)
                }
                "setKeys" -> {
                    SharedData.openAiApiKey = call.argument<String>("oaikey") ?: ""
                    SharedData.assemblyAIKey = call.argument<String>("aaikey") ?: ""
                    result.success(true)
                }

                "dumpMails" -> {


                        SharedData.emails = call.argument<List<String>>("mails") ?: mutableListOf("")
                        Log.d("Emails: ", "Writing Emails... ${SharedData.emails.joinToString()}")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

    }

    private fun checkAudioPermission(): Boolean {
        return if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            true
        } else {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION_REQUEST_CODE)
            false
        }
    }

    private fun checkBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            val packageName = packageName
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
                try {
                    startActivity(intent)
                    Log.d("MainActivity", "Requested battery optimization exemption")
                } catch (e: Exception) {
                    Log.e("MainActivity", "Failed to request battery optimizations: ${e.message}")
                }
            }
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
        // Simplified check using ServiceManager flags
        return ServiceManager.isBound && !ServiceManager.isStoped
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            checkBatteryOptimization()
            startSpeechService()
        }
    }

    override fun onResume() {
        super.onResume()
        CoroutineScope(Dispatchers.IO).launch {
            val hasAccess = checkStats()

            if (!hasAccess) {
                withContext(Dispatchers.Main) {
                    MethodChannel(messenger, "init")
                        .invokeMethod("shareStats", null)
                }
            }
        }
    }




    private fun checkStats(): Boolean {


        return try {
            val url = URL(NetworkHelper.urlStr)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "GET"
            conn.connectTimeout = 5000
            conn.readTimeout = 5000

            if (conn.responseCode == HttpURLConnection.HTTP_OK) {
                val response = conn.inputStream.bufferedReader().use { it.readText() }
                val json = JSONObject(response)
                json.optBoolean("ai_assistant", false)
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("MainActivity", "Activity destroyed")
        // Service not be stopped here to ensure persistence
    }
}

