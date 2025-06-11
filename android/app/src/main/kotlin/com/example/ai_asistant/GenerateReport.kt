package com.example.openai

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import org.json.JSONArray

fun getEmailReport(emails: List<String>, apiKey: String, onDone: (String) -> Unit): String {
    val client = OkHttpClient()
    val emailListString = emails.joinToString("\n" )
    val systemPrompt = """
    You are an email analysis assistant. Given the following list of emails, provide a detailed report summarizing all emails, including each email's sender and subject in the summary points. Respond strictly in JSON format with a single key "report" containing the full summary as a string. Do not include any other fields or deviate from this format.
    example response body: {"report" : "report of the emails."}
    Email List:
    $emailListString
""".trimIndent()

    val requestBodyJson = JSONObject()
        .put("model", "gpt-4-turbo")
        .put("messages", JSONArray().put(JSONObject()
            .put("role", "system")
            .put("content", systemPrompt)))
        .toString()

    val request = Request.Builder()
        .url("https://api.openai.com/v1/chat/completions")
        .header("Authorization", "Bearer $apiKey")
        .header("Content-Type", "application/json")
        .post(requestBodyJson.toRequestBody("application/json".toMediaType()))
        .build()

    client.newCall(request).execute().use { response ->
        val responseBody = response.body?.string() ?: throw Exception("No response body")
        val jsonResponse = JSONObject(responseBody)
        val choices = jsonResponse.getJSONArray("choices")
        val messageContent = choices.getJSONObject(0).getJSONObject("message").getString("content")
        val reportJson = JSONObject(messageContent)
        onDone(reportJson.getString("report"))
        return reportJson.getString("report")
    }
}