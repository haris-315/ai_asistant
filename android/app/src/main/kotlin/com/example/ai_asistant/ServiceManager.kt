package com.example.svc_mng

import android.speech.tts.Voice

object ServiceManager {
    var isStandBy: Boolean = true
    var isStoped: Boolean = true
    var isBound: Boolean = false
    var serviceChannelName: String = "com.example.ai_assistant/stt"
    var resultEventChannel: String = "com.example.ai_assistant/stt_results"
    var recognizedText: String? = ""
    var initializing: Boolean = false
    var ttsVoices: List<Voice> = mutableListOf<Voice>()
    var isWarmingTts: Boolean = false

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "isStandBy" to isStandBy,
            "isStoped" to isStoped,
            "isBound" to isBound,
            "serviceChannelName" to serviceChannelName,
            "resultEventChannel" to resultEventChannel,
            "recognizedText" to recognizedText,
            "initializing" to initializing,
            "isWarmingTts" to isWarmingTts,
            "ttsVoices" to ttsVoices.map {
                mapOf(
                    "name" to it.name,
                    "locale" to it.locale.toString(),
                    "quality" to it.quality,
                    "latency" to it.latency,
                    "isOnline" to it.isNetworkConnectionRequired,
                )
            }
        )
    }
}
