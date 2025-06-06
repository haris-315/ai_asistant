package com.example.openai

import android.speech.tts.Voice

object SharedData {
    var authToken: String = ""
    var projects: MutableList<String> = mutableListOf()
    var tasks: List<MutableMap<String, Any>> = emptyList()
    var currentVoice: Voice? = null
    var porcupineAK: String = ""
    var openAiApiKey: String = ""
    var assemblyAIKey: String = "";
    var baseUrl = "https://ai-assistant-backend-blue.vercel.app/"

}


object EmailsData {
    var emails: List<String> = mutableListOf("RRRR")
    fun hashCodeId(other: List<String>) : Boolean {
        return fakeHashCode(other) == fakeHashCode(emails)
    }

    fun fakeHashCode(elements: List<String>) : String {
        val fakehash: String = elements.fold(initial = "RRRR") { init, it -> (init + it.first()) ?: "R" }
        return fakehash
    }
}
