package com.example.tts_helper

import android.content.Context
import android.speech.tts.TextToSpeech
import android.util.Log
import java.util.Locale

class TextToSpeechHelper(
    context: Context,
    private val onDoneCallback: () -> Unit
) : TextToSpeech.OnInitListener {

    private var tts: TextToSpeech? = null
    private var isReady = false

    init {
        tts = TextToSpeech(context.applicationContext, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = tts?.setLanguage(Locale.US)
            isReady = result != TextToSpeech.LANG_MISSING_DATA && result != TextToSpeech.LANG_NOT_SUPPORTED
            Log.d("TTS", if (isReady) "TTS initialized successfully" else "TTS language not supported")
        } else {
            Log.e("TTS", "TTS initialization failed")
        }
    }

    fun speak(text: String) {
        if (isReady && text.isNotBlank()) {
            val utteranceId = System.currentTimeMillis().toString()
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
            tts?.setOnUtteranceProgressListener(object : android.speech.tts.UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    Log.d("TTS", "Speech started")
                }

                override fun onDone(utteranceId: String?) {
                    Log.d("TTS", "Speech done")
                    onDoneCallback()
                }

                override fun onError(utteranceId: String?) {
                    Log.e("TTS", "Speech error")
                    onDoneCallback()
                }
            })
        } else {
            Log.e("TTS", "TTS not ready or empty text")
            onDoneCallback()
        }
    }

    fun shutdown() {
        tts?.stop()
        tts?.shutdown()
    }
}
