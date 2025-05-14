package com.example.ai_asistant

import android.content.Context
import android.util.Log
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService
import java.io.File
import java.io.FileOutputStream

class SpeechRecognizerClient(
    private val context: Context,
    private val callback: Callback
) : RecognitionListener {

    interface Callback {
        fun onSpeechResult(text: String)
        fun onSpeechPartial(text: String)
        fun onSpeechError(error: String)
    }

    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var speechService: SpeechService? = null

    private val sampleRate = 16000.0f
    private val modelDirName = "model-en-us"

    private val modelPath: String
        get() = File(context.filesDir, modelDirName).absolutePath

    /**
     * Initialize the speech recognizer by checking and copying the model if needed.
     */
    fun initialize(onReady: () -> Unit) {
        if (model != null) {
            onReady()
            return
        }

        val modelDir = File(context.filesDir, modelDirName)
        if (!modelDir.exists() || !File(modelDir, "conf").exists()) {
            try {
                copyAssets(modelDirName)
                Log.d("SpeechRecognizerClient", "Model copied to ${modelDir.absolutePath}")
            } catch (e: Exception) {
                callback.onSpeechError("Model copy failed: ${e.message}")
                return
            }
        }

        try {
            Log.d("SpeechRecognizerClient", "Loading model from $modelPath")
            model = Model(modelPath)
            onReady()
        } catch (e: Exception) {
            callback.onSpeechError("Model load failed: ${e.message}")
        }
    }

    private fun copyAssets(folderName: String) {
        val assetManager = context.assets
        val outDir = File(context.filesDir, folderName)
        outDir.mkdirs()
        val files = assetManager.list(folderName) ?: throw Exception("No files in asset folder $folderName")

        for (filename in files) {
            val inPath = "$folderName/$filename"
            val outFile = File(outDir, filename)

            // Recursively copy subfolders
            if (assetManager.list(inPath)?.isNotEmpty() == true) {
                copyAssets(inPath)
            } else {
                if (!outFile.exists()) {
                    assetManager.open(inPath).use { input ->
                        FileOutputStream(outFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                }
            }
        }
    }

    fun startRecognition() {
        stopRecognition()
        try {
            recognizer = Recognizer(model, sampleRate)
            speechService = SpeechService(recognizer, sampleRate)
            speechService?.startListening(this)
        } catch (e: Exception) {
            callback.onSpeechError("Recognition error: ${e.message}")
        }
    }

    fun stopRecognition() {
        speechService?.stop()
        speechService = null
    }

    fun shutdown() {
        stopRecognition()
        recognizer?.close()
        recognizer = null
        model?.close()
        model = null
    }

    override fun onPartialResult(hypothesis: String?) {
        hypothesis?.let {
            Log.d("SpeechRecognizerClient", "Partial: $it")
            callback.onSpeechPartial(it)
        }
    }

    override fun onResult(hypothesis: String?) {
        hypothesis?.let {
            Log.d("SpeechRecognizerClient", "Result: $it")
            callback.onSpeechResult(it)
        }
    }

    override fun onFinalResult(hypothesis: String?) {
        // Optional
    }

    override fun onError(e: Exception?) {
        callback.onSpeechError("Engine error: ${e?.message ?: "unknown error"}")
    }

    override fun onTimeout() {
        callback.onSpeechError("Recognition timed out.")
    }
}
