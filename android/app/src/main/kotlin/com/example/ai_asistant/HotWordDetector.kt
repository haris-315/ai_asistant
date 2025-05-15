package com.example.ai_asistant

import ai.picovoice.porcupine.*
import android.content.Context
import java.io.IOException

class HotWordDetector(
        private val context: Context,
        private val keywordAssetName: String,
        private val onWakeWordDetected: () -> Unit
) {
    private var porcupineManager: PorcupineManager? = null

    fun start() {
        if (porcupineManager != null) return

        try {
            porcupineManager =
                    PorcupineManager.Builder()
                            .setKeywordPath(keywordAssetName)
                            .setSensitivity(0.7f)
                            .setAccessKey("")
                            .build(context) { onWakeWordDetected() }

            porcupineManager?.start()
        } catch (e: IOException) {
            e.printStackTrace()
        } catch (e: PorcupineException) {
            e.printStackTrace()
        }
    }

    fun stop() {
        porcupineManager?.stop()
        porcupineManager?.delete()
        porcupineManager = null
    }

    val isRunning: Boolean
        get() = porcupineManager != null
}
