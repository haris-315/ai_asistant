package com.example.openai

import android.speech.tts.Voice

object SharedData {
    var authToken: String = ""
    var projects: MutableList<String> = mutableListOf()
    var tasks: List<MutableMap<String, Any>> = emptyList()
    var currentVoice: Voice? = null
    var porcupineAK: String = ""

}


object EmailsData {
    var emails: List<String> = mutableListOf("")
    fun hashCodeId(other: List<String>) : Boolean {
        return fakeHashCode(other) == fakeHashCode(emails)
    }

    fun fakeHashCode(elements: List<String>) : String {
        val fakehash: String = elements.fold(initial = "") { init, it -> (init + it.first()) ?: "R" }
        return fakehash
    }
}
