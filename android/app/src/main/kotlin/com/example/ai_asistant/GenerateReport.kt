package com.example.openai

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import org.json.JSONArray

fun getEmailReport(emails: List<String>, apiKey: String, onDone: (List<String>) -> Unit): List<String> {
    val client = OkHttpClient()
    val prompt = """
        You are an email assistant. Summarize the following emails as bullet-point keypoints.
        Each point must include the sender and subject. Respond ONLY with JSON: {"report": ["• point 1", "• point 2"]}
        Emails:\n${emails.joinToString("\n")}
    """.trimIndent()

    val body = JSONObject().put("model", "gpt-4-turbo")
        .put("messages", JSONArray().put(JSONObject().put("role", "system").put("content", prompt)))
        .toString()
        .toRequestBody("application/json".toMediaType())

    val request = Request.Builder()
        .url("https://api.openai.com/v1/chat/completions")
        .header("Authorization", "Bearer $apiKey")
        .post(body)
        .build()

    client.newCall(request).execute().use { res ->
        val json = JSONObject(res.body?.string() ?: error("No response"))
        val content = json.getJSONArray("choices")
            .getJSONObject(0).getJSONObject("message").getString("content")
        val keypoints = JSONObject(content).getJSONArray("report")
        return List(keypoints.length()) { i -> keypoints.getString(i) }.also { onDone(it) }
    }
}
