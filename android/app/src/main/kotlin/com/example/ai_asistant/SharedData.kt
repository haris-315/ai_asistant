package com.example.openai

import android.speech.tts.Voice

object SharedData {
    var authToken: String = ""
    var projects: MutableList<String> = mutableListOf()
    var tasks: List<MutableMap<String, Any>> = emptyList()
    var currentVoice: Voice? = null
    var porcupineAK: String = ""
}
