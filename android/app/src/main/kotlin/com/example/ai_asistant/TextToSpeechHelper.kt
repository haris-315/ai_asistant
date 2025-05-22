package com.example.tts_helper

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import android.util.Log
import com.example.openai.SharedData
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull
import java.lang.ref.WeakReference
import java.util.Locale

class TextToSpeechHelper(
    context: Context,
    private val onDone: (List<Voice>) -> Unit
) {
    private val contextRef = WeakReference(context.applicationContext)
    private var tts: TextToSpeech? = null
    private var isInitialized = false
    private val initTimeoutMs = 10000L
    private val maxInitAttempts = 3
    private var initializationInProgress = false

    init {
        initializeTTS()
    }

    private fun initializeTTS(attempt: Int = 1) {
        if (initializationInProgress) {
            Log.d("TTS", "TTS initialization already in progress")
            return
        }
        initializationInProgress = true
        val ctx = contextRef.get() ?: run {
            Log.e("TTS", "Context is null, cannot initialize TTS")
            initializationInProgress = false
            return
        }
        try {
            tts = TextToSpeech(ctx) { status ->
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

                    Log.d("TTS", "TTS initialized successfully on attempt $attempt")
                    preWarm()
                    initializationInProgress = false
                } else {
                    Log.e("TTS", "TTS initialization failed with status $status on attempt $attempt")
                    isInitialized = false
                    retryInitialization(attempt)
                }
            }
        } catch (e: Exception) {
            Log.e("TTS", "TTS initialization crashed on attempt $attempt: ${e.message}")
            isInitialized = false
            retryInitialization(attempt)
        }
    }

    private fun preWarm() {
        if (!isInitialized) {
            Log.w("TTS", "Cannot pre-warm TTS: not initialized")
            return
        }
        try {
            tts?.setSpeechRate(1.0f)
            tts?.setPitch(1.0f)
            tts?.speak("", TextToSpeech.QUEUE_FLUSH, null, "prewarm_${System.currentTimeMillis()}")
            Log.d("TTS", "TTS pre-warmed with silent utterance")
        } catch (e: Exception) {
            Log.e("TTS", "Pre-warm failed: ${e.message}")
        }
    }

    private fun retryInitialization(attempt: Int) {
        if (attempt >= maxInitAttempts) {
            Log.e("TTS", "Max TTS initialization attempts reached")
            initializationInProgress = false
            return
        }
        Log.d("TTS", "Retrying TTS initialization, attempt ${attempt + 1}")
        initializeTTS(attempt + 1)
    }

    fun reinitialize() {
        Log.d("TTS", "Reinitializing TTS")
        shutdown()
        initializeTTS()
    }

    fun isInitialized(): Boolean = isInitialized

    suspend fun waitForInitialization(timeoutMs: Long = initTimeoutMs): Boolean {
        if (isInitialized) return true
        if (!initializationInProgress) {
            Log.w("TTS", "TTS initialization not in progress, triggering reinitialization")
            reinitialize()
        }
        return withTimeoutOrNull(timeoutMs) {
            while (!isInitialized) {
                delay(100)
            }
            true
        } ?: false
    }

    fun speak(text: String) {
        if (!isInitialized) {
            Log.e("TTS", "TTS not initialized, attempting reinitialization")
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
            reinitialize()
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
            tts?.stop()
            tts?.shutdown()
        } catch (e: Exception) {
            Log.e("TTS", "Shutdown failed: ${e.message}")
        } finally {
            tts = null
            isInitialized = false
            initializationInProgress = false
            Log.d("TTS", "TTS shutdown")
        }
    }
}