package com.example.sp_client

import android.content.Context
import android.util.Log
import com.example.openai.OpenAIClient
import com.example.openai.SharedData
import com.example.tts_helper.TextToSpeechHelper
import com.example.ai_asistant.HotWordDetector

class SpeechRecognizerClient(private val context: Context){
    private var hotWordDetector : HotWordDetector = HotWordDetector(
        context = context,
        keywordAssetName = "hey_jarvis.ppn",
        onWakeWordDetected = {
            Log.i("Porcupine: ", "Hot Word Detected!")
        }
    )

    fun initialize() {
        try {
        hotWordDetector.start()
            Log.i("Porcupine: ", "Hot Word Detection Started...")

        } catch (e: Exception) {
            Log.e("Error-Procupine", "Details: ${e.toString()}")
        }
    }


    fun shutdown() {
        hotWordDetector.stop();
    }
}