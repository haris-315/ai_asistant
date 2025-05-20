package com.example.ai_asistant

import ai.picovoice.porcupine.*
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import java.io.IOException
import android.Manifest
import com.example.openai.SharedData

class HotWordDetector(
    private val context: Context,
    private val keywordAssetName: String,
    private val onWakeWordDetected: () -> Unit
) {
    private var porcupineManager: PorcupineManager? = null

    fun start() {
        if (porcupineManager != null) {
            Log.d("HWD", "HotWordDetector already running")
            return
        }

        // Check microphone permission
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.e("HWD", "Microphone permission denied")
            throw SecurityException("Microphone permission required for hotword detection")
        }

        // Validate asset file existence
        try {
            context.assets.open(keywordAssetName).use {
                Log.d("HWD", "Keyword asset $keywordAssetName found")
            }
        } catch (e: IOException) {
            Log.e("HWD", "Keyword asset $keywordAssetName not found: ${e.message}")
            throw IOException("Keyword asset $keywordAssetName not found")
        }

        try {
            porcupineManager = PorcupineManager.Builder()
                .setKeywordPath(keywordAssetName)
                .setSensitivity(0.7f)
                .setAccessKey(SharedData.porcupineAK)
                .build(context) { onWakeWordDetected() }

            porcupineManager?.start()
            Log.i("HWD", "HotWordDetector started successfully")
        } catch (e: PorcupineException) {
            Log.e("HWD", "Failed to initialize PorcupineManager: ${e.message}")
            throw e
        } catch (e: Exception) {
            Log.e("HWD", "Unexpected error initializing PorcupineManager: ${e.message}")
            throw e
        }
    }

    fun stop() {
        try {
            porcupineManager?.stop()
            porcupineManager?.delete()
            Log.i("HWD", "HotWordDetector stopped successfully")
        } catch (e: Exception) {
            Log.w("HWD", "Error stopping HotWordDetector: ${e.message}")
        } finally {
            porcupineManager = null
        }
    }

    val isRunning: Boolean
        get() = porcupineManager != null
}