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
        tts = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale.US
                tts?.voice = getEnglishVoices().firstOrNull { voice -> voice.name == SharedData.currentVoice?.name} ?: getEnglishVoices().first()

                isInitialized = true
                tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {}
                    override fun onDone(utteranceId: String?) {
                        Log.d("TTS", "Utterance completed: $utteranceId")
                        onDone(getEnglishVoices())
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
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, text.hashCode().toString())
        Log.d("TTS", "Speaking: $text")
    }

    fun stop() {
        tts?.stop()
        Log.d("TTS", "TTS stopped")
    }
    fun getEnglishVoices(): List<Voice> {
        return tts?.voices
            ?.filter { it.locale.language == Locale.ENGLISH.language }
            ?.toList() ?: emptyList()
    }

    fun shutdown() {
        tts?.shutdown()
        tts = null
        isInitialized = false
        Log.d("TTS", "TTS shutdown")
    }
}