package com.example.ai_asistant

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import ai.picovoice.porcupine.*
import com.example.openai.SharedData
import com.example.tts_helper.TextToSpeechHelper
import kotlinx.coroutines.*
import java.io.File

class HotWordDetector(
    private val context: Context,
    private val keywordAssetName: String,
    private val onHotwordDetected: () -> Unit
) {
    private var porcupine: Porcupine? = null
    private var audioRecord: android.media.AudioRecord? = null
    private var detectionJob: Job? = null
    private val sampleRate = 16000
    private val bufferSize = 512 // Hardcoded Porcupine frame length
    @Volatile
    private var isRunning = false
    @Volatile
    private var isInitialized = false
    private var initializationInProgress = false

    init {
        // Initialize on background thread
        CoroutineScope(Dispatchers.Default).launch {
            initializePorcupine()
        }
    }

    private suspend fun initializePorcupine(attempt: Int = 1, maxAttempts: Int = 3) {
        if (initializationInProgress) {
            Log.d("HWD", "Porcupine initialization already in progress")
            return
        }
        initializationInProgress = true
        try {
            // File operations on IO thread
            withContext(Dispatchers.IO) {
                val assetFile = context.assets.open(keywordAssetName)
                val keywordFile = File(context.filesDir, keywordAssetName)
                assetFile.copyTo(keywordFile.outputStream())
                assetFile.close()
                Log.d("HWD", "Keyword asset $keywordAssetName found")
            }

            porcupine = Porcupine.Builder()
                .setAccessKey(SharedData.porcupineAK ?: throw IllegalStateException("Picovoice access key is null"))
                .setKeywordPaths(arrayOf(File(context.filesDir, keywordAssetName).absolutePath))
                .setSensitivities(floatArrayOf(0.4f))
                .build(context)

            isInitialized = true
            Log.d("HWD", "Porcupine initialized successfully on attempt $attempt")
        } catch (e: Exception) {
            Log.e("HWD", "Failed to initialize Porcupine on attempt $attempt: ${e.message}")
            if (attempt < maxAttempts) {
                Log.d("HWD", "Retrying Porcupine initialization, attempt ${attempt + 1}")
                delay(1000L)
                initializePorcupine(attempt + 1, maxAttempts)
            } else {
                Log.e("HWD", "Max retry attempts reached for Porcupine initialization")
                withContext(Dispatchers.Main) {
                    TextToSpeechHelper(context) {}.speak("Hotword detection setup failed.")
                }
            }
        } finally {
            initializationInProgress = false
        }
    }

    suspend fun waitForInitialization(timeoutMs: Long = 10000L): Boolean {
        if (isInitialized) return true
        if (!initializationInProgress) {
            Log.w("HWD", "HotWordDetector initialization not in progress, triggering")
            initializePorcupine()
        }
        return withTimeoutOrNull(timeoutMs) {
            while (!isInitialized && initializationInProgress) {
                delay(100)
            }
            isInitialized
        } ?: false
    }

    @SuppressLint("MissingPermission")
    fun start() {
        if (isRunning || porcupine == null || !isInitialized) {
            Log.w("HWD", "HotWordDetector already running or not initialized")
            if (porcupine == null && !initializationInProgress) {
                CoroutineScope(Dispatchers.Default).launch {
                    initializePorcupine()
                }
            }
            return
        }

        // Start detection on background thread
        detectionJob?.cancel()
        detectionJob = CoroutineScope(Dispatchers.IO).launch {
            try {
                // Create AudioRecord on IO thread
                audioRecord?.release()
                audioRecord = android.media.AudioRecord(
                    android.media.MediaRecorder.AudioSource.MIC,
                    sampleRate,
                    android.media.AudioFormat.CHANNEL_IN_MONO,
                    android.media.AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize * 2
                )

                if (audioRecord?.state != android.media.AudioRecord.STATE_INITIALIZED) {
                    Log.e("HWD", "Failed to initialize AudioRecord")
                    audioRecord?.release()
                    audioRecord = null
                    withContext(Dispatchers.Main) {
                        TextToSpeechHelper(context) {}.speak("Microphone access failed.")
                    }
                    return@launch
                }

                audioRecord?.startRecording()
                isRunning = true
                Log.i("HWD", "HotWordDetector started successfully")

                val buffer = ShortArray(bufferSize)
                while (isRunning && isActive) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0) {
                        try {
                            porcupine?.process(buffer)?.let { keywordIndex ->
                                if (keywordIndex >= 0) {
                                    withContext(Dispatchers.Main) {
                                        Log.d("HWD", "Hotword detected at ${System.currentTimeMillis()}")
                                        onHotwordDetected()
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            Log.e("HWD", "Error processing audio: ${e.message}")
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("HWD", "Failed to start HotWordDetector: ${e.message}")
                withContext(Dispatchers.Main) {
                    TextToSpeechHelper(context) {}.speak("Hotword detection failed.")
                }
            } finally {
                stopInternal()
                Log.i("HWD", "HotWordDetector stopped")
            }
        }
    }

    private fun stopInternal() {
        try {
            isRunning = false
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        } catch (e: Exception) {
            Log.e("HWD", "Error stopping HotWordDetector: ${e.message}")
        }
    }

    fun stop() {
        detectionJob?.cancel()
        stopInternal()
    }

    fun release() {
        stop()
        try {
            porcupine?.delete()
            porcupine = null
            isInitialized = false
            initializationInProgress = false
            Log.d("HWD", "Porcupine released")
        } catch (e: Exception) {
            Log.e("HWD", "Error releasing Porcupine: ${e.message}")
        }
    }

    companion object {
        fun checkKey(context: Context, key: String, keywordAssetName: String): Boolean {
            return try {
                val testManager = PorcupineManager.Builder()
                    .setKeywordPath(keywordAssetName)
                    .setSensitivity(0.5f)
                    .setAccessKey(key)
                    .build(context) { /* no-op */ }

                testManager.start()
                testManager.stop()
                testManager.delete()
                Log.i("HWD", "Access key is valid")
                true
            } catch (e: Exception) {
                Log.e("HWD", "Access key check failed: ${e.message}")
                false
            }
        }
    }
}