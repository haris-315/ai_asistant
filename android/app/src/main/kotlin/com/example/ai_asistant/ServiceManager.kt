package com.example.svc_mng

import android.speech.tts.Voice
import com.example.openai.SharedData
import java.security.MessageDigest



object ServiceManager {

    fun computeListHash(list: List<String>): String {
        val sortedList = list.sorted()
        val joined = sortedList.joinToString(",")
        val bytes = MessageDigest.getInstance("MD5").digest(joined.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }

    var isStandBy: Boolean = true
    var isStoped: Boolean = true
    var isBound: Boolean = false
    var serviceChannelName: String = "com.example.ai_assistant/stt"
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
            "recognizedText" to recognizedText,
            "initializing" to initializing,
            "isWarmingTts" to isWarmingTts,
            "mailsSyncHash" to computeListHash(SharedData.emails),
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
