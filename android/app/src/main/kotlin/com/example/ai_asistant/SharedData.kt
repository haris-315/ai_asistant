package com.example.openai

object SharedData {
    var authToken: String = ""
    var projects: MutableList<String> = mutableListOf()
    var tasks: List<MutableMap<String, Any>> = emptyList()
    var currentVoice: String? = null
}
