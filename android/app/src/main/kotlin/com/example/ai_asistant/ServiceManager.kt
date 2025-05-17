package com.example.svc_mng

object ServiceManager {
    var isStandBy : Boolean = true
    var isStoped : Boolean = true
    var isBound : Boolean = false
    var serviceChannelName : String = "com.example.ai_assistant/stt"
    var resultEventChannel : String = "com.example.ai_assistant/stt_results"
    var recognizedText : String? = ""
    var initializing : Boolean = true
    var ttsVoices: List<String> = mutableListOf<String>()

}