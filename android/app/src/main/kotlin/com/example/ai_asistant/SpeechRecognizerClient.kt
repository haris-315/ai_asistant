package com.example.ai_asistant

import android.content.Context
import android.util.Log
import com.example.openai.OpenAIClient
import com.example.openai.SharedData
import com.example.tts_helper.TextToSpeechHelper
import java.io.File
import java.io.FileOutputStream
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService

class SpeechRecognizerClient(private val context: Context, private val callback: Callback) :
    RecognitionListener {

    interface Callback {
        fun onSpeechResult(text: String)
        fun onSpeechPartial(text: String)
        fun onSpeechError(error: String)
    }

    // State flags
    private var shouldProcessSpeech = true
    private var isTtsSpeaking = false
    private var isProcessingRequest = false

    // Components
    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var speechService: SpeechService? = null

    private val ttsHelper: TextToSpeechHelper =
        TextToSpeechHelper(context) {
            Log.d("TTS Helper", "Speech completed")
            isTtsSpeaking = false
            // Re-enable speech processing when TTS is done
            shouldProcessSpeech = true
        }

    private val openAIClient: OpenAIClient =
        OpenAIClient(
            context,
            "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", // Should be stored securely
            SharedData.authToken,
            SharedData.projects
        )

    private val sampleRate = 16000.0f
    private val modelDirName = "model-en-us"

    private val modelPath: String
        get() = File(context.filesDir, modelDirName).absolutePath

    fun initialize(onReady: () -> Unit) {
        if (model != null) {
            onReady()
            return
        }

        val modelDir = File(context.filesDir, modelDirName)
        if (!modelDir.exists() || !File(modelDir, "conf").exists()) {
            try {
                copyAssets(modelDirName)
                Log.d("SpeechRecognizer", "Model copied to ${modelDir.absolutePath}")
            } catch (e: Exception) {
                callback.onSpeechError("Model copy failed: ${e.message}")
                return
            }
        }

        try {
            model = Model(modelPath)
            onReady()
        } catch (e: Exception) {
            callback.onSpeechError("Model load failed: ${e.message}")
        }
    }

    fun startRecognition() {
        if (speechService != null) return

        try {
            recognizer = Recognizer(model, sampleRate)
            speechService = SpeechService(recognizer, sampleRate)
            speechService?.startListening(this)
            shouldProcessSpeech = true
            Log.d("SpeechRecognizer", "Recognition started")
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
        ttsHelper.shutdown()
    }

    override fun onPartialResult(hypothesis: String?) {
        if (!shouldProcessSpeech) return

        try {
            hypothesis?.let { jsonString ->
                // Safely parse JSON and extract text
                val json = JSONObject(jsonString)
                if (json.has("partial")) {
                    val partialText = json.getString("partial")
                    if (partialText.isNotBlank()) {
                        Log.d("SpeechRecognizer", "Partial: $partialText")
                        callback.onSpeechPartial(partialText)
                    }
                } else if (json.has("text")) {
                    val text = json.getString("text")
                    if (text.isNotBlank()) {
                        Log.d("SpeechRecognizer", "Partial (text): $text")
                        callback.onSpeechPartial(text)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("SpeechRecognizer", "Partial result parsing error", e)
            // Don't send error callback for partial results to avoid interrupting flow
        }
    }

    override fun onResult(hypothesis: String?) {
        if (!shouldProcessSpeech) return

        try {
            hypothesis?.let { jsonString ->
                val json = JSONObject(jsonString)
                val text =
                    if (json.has("text")) json.getString("text") else json.getString("partial")

                if (text.isNotBlank()) {
                    Log.d("SpeechRecognizer", "Result: $text")

                    // Disable further processing while handling this request
                    shouldProcessSpeech = false
                    isProcessingRequest = true

                    processUserInput(text)
                    callback.onSpeechResult(text)
                }
            }
        } catch (e: Exception) {
            Log.e("SpeechRecognizer", "Result parsing error", e)
            callback.onSpeechError("Failed to parse speech result")
            // Re-enable processing on error
            shouldProcessSpeech = true
        }
    }

    private fun processUserInput(text: String) {
        openAIClient.sendMessage(
            userMessage = text,
            onResponse = { response ->
                try {
                    isTtsSpeaking = true
                    ttsHelper.speak(response.toString())
                } catch (e: Exception) {
                    Log.e("SpeechRecognizer", "TTS error", e)
                    // Re-enable processing if TTS fails
                    shouldProcessSpeech = true
                    isProcessingRequest = false
                }
            },
            onError = { error ->
                Log.e("OpenAI", "API error: ${error ?: "Unknown error"}")
                ttsHelper.speak("Sorry, I encountered an error")
                // Re-enable processing on API error
                shouldProcessSpeech = true
                isProcessingRequest = false
            }
        )
    }

    override fun onFinalResult(hypothesis: String?) {
        // Optional implementation
    }

    override fun onError(e: Exception?) {
        callback.onSpeechError("Recognition error: ${e?.message ?: "Unknown error"}")
        // Re-enable processing on error
        shouldProcessSpeech = true
    }

    override fun onTimeout() {
        callback.onSpeechError("Recognition timed out")
        // Re-enable processing on timeout
        shouldProcessSpeech = true
    }

    private fun copyAssets(folderName: String) {
        val assetManager = context.assets
        val outDir = File(context.filesDir, folderName)
        outDir.mkdirs()

        assetManager.list(folderName)?.forEach { filename ->
            val inPath = "$folderName/$filename"
            val outFile = File(outDir, filename)

            if (assetManager.list(inPath)?.isNotEmpty() == true) {
                copyAssets(inPath)
            } else if (!outFile.exists()) {
                assetManager.open(inPath).use { input ->
                    FileOutputStream(outFile).use { output -> input.copyTo(output) }
                }
            }
        }
            ?: throw Exception("No files in asset folder $folderName")
    }
}
