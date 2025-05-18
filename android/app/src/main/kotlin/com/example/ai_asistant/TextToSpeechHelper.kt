package com.example.tts_helper

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import android.util.Log
import com.example.openai.SharedData
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull
import java.util.Locale

class TextToSpeechHelper(
    private val context: Context,
    private val onDone: (List<Voice>) -> Unit
) {
    private var tts: TextToSpeech? = null
    private var isInitialized = false

    init {
        initializeTTS()
    }

    private fun initializeTTS() {
        try {
            tts = TextToSpeech(context) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    isInitialized = true
                    tts?.language = Locale.US

                    try {
                        val voices = getEnglishVoices()
                        val preferredVoice = voices.firstOrNull {
                            it.name == SharedData.currentVoice?.name
                        }
                        if (voices.isNotEmpty()) {
                            tts?.voice = preferredVoice ?: voices.first()
                        } else {
                            Log.w("TTS", "No English voices available")
                        }
                    } catch (e: Exception) {
                        Log.e("TTS", "Failed to set voice: ${e.message}")
                    }

                    tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) {}
                        override fun onDone(utteranceId: String?) {
                            try {
                                onDone(getEnglishVoices())
                            } catch (e: Exception) {
                                Log.e("TTS", "onDone voice retrieval failed: ${e.message}")
                            }
                        }
                        override fun onError(utteranceId: String?) {
                            Log.e("TTS", "Utterance error: $utteranceId")
                        }
                    })

                    Log.d("TTS", "TTS initialized successfully")
                } else {
                    Log.e("TTS", "TTS initialization failed: $status")
                    isInitialized = false
                }
            }
        } catch (e: Exception) {
            Log.e("TTS", "TTS initialization crashed: ${e.message}")
            isInitialized = false
        }
    }

    fun reinitialize() {
        Log.d("TTS", "Reinitializing TTS")
        shutdown()
        initializeTTS()
    }

    fun isInitialized(): Boolean = isInitialized

    suspend fun waitForInitialization(timeoutMs: Long): Boolean {
        if (isInitialized) return true
        return withTimeoutOrNull(timeoutMs) {
            while (!isInitialized) {
                delay(100)
            }
            true
        } ?: false
    }

    fun speak(text: String) {
        if (!isInitialized) {
            Log.e("TTS", "TTS not initialized")
            reinitialize()
            return
        }
        if (text.isBlank()) {
            Log.e("TTS", "Empty text provided")
            return
        }
        try {
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, text.hashCode().toString())
            Log.d("TTS", "Speaking: $text")
        } catch (e: Exception) {
            Log.e("TTS", "Speak failed: ${e.message}")
        }
    }

    fun stop() {
        try {
            tts?.stop()
            Log.d("TTS", "TTS stopped")
        } catch (e: Exception) {
            Log.e("TTS", "Stop failed: ${e.message}")
        }
    }

    fun getEnglishVoices(): List<Voice> {
        return try {
            tts?.voices
                ?.filter { it.locale.language == Locale.ENGLISH.language }
                ?.toList() ?: emptyList()
        } catch (e: Exception) {
            Log.e("TTS", "Error getting voices: ${e.message}")
            emptyList()
        }
    }

    fun shutdown() {
        try {
            tts?.shutdown()
        } catch (e: Exception) {
            Log.e("TTS", "Shutdown failed: ${e.message}")
        } finally {
            tts = null
            isInitialized = false
            Log.d("TTS", "TTS shutdown")
        }
    }
}
