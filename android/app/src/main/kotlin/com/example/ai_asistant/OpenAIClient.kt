package com.example.openai

import android.util.Log
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException

class OpenAIClient(
    private val apiKey: String,
    private val authToken: String,
    private val projects: MutableList<String>
) {

    private val client = OkHttpClient()
    private val messages = mutableListOf<JSONObject>()
    private val apiUrl = "https://api.openai.com/v1/chat/completions"
    val systemPrompt = """
You are a friendly assistant for a task manager app and you also provide general information and talk to users to give them knowledge they want and to provide them with information they require.

Your response **must** always be in this strict JSON format:
{
  "chatres": "short and friendly message for the user (for TTS)",
  "tsk": {
    "content": "task name",
    "description": "task description",
    "is_completed": false,
    "priority": 1 to 3,
    "project_id": INT
  }
}

- If the user asks you to add a task, you MUST include both "chatres" and "tsk".
- If the user doesn’t request a task, respond with only "chatres" (and omit "tsk").
- If the project name mentioned by the user matches one of these available projects, use its ID:
${projects.joinToString(", ")}

- If no matching project is found, default to: (Inbox) id.
- NEVER add extra fields or text outside the JSON.
- NEVER omit "chatres".

EXAMPLES:

User: Add a task to buy milk for my Grocery project  
Response:
{
  "chatres": "Sure, I’ve added it to your Grocery project!",
  "tsk": {
    "content": "Buy milk",
    "description": "Task to buy milk for Grocery project",
    "is_completed": false,
    "priority": 1,
    "project_id": 42
  }
}
""".trimIndent()

    fun getMessageHistory(): List<JSONObject> = messages.toList()

    fun clearHistory() = messages.clear()

    fun sendMessage(
        userMessage: String,
        model: String = "gpt-4-turbo",
        onResponse: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        messages.add(JSONObject().apply {
            put("role", "user")
            put("content", userMessage)
        })
        messages.add(JSONObject().apply {
            put("role", "system")
            put("content", systemPrompt)
        })

        val requestBody = JSONObject().apply {
            put("model", model)
            put("messages", JSONArray(messages))
        }

        val request = Request.Builder()
            .url(apiUrl)
            .addHeader("Authorization", "Bearer $apiKey")
            .addHeader("Content-Type", "application/json")
            .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                onError("Network Error: ${e.message}")
            }

            override fun onResponse(call: Call, response: Response) {
                if (!response.isSuccessful) {
                    onError("API Error: ${response.code} ${response.message}")
                    return
                }

                try {
                    val responseBody = response.body?.string() ?: "{}"
                    val replyContent = JSONObject(responseBody)
                        .getJSONArray("choices")
                        .getJSONObject(0)
                        .getJSONObject("message")
                        .getString("content")

                    val replyJson = JSONObject(replyContent)
                    val chatres = replyJson.optString("chatres", "Okay.")
                    val taskJson = replyJson.optJSONObject("tsk")

                    Log.d("Gpt-3.5-turbo", "Response: $replyJson")

                    messages.add(JSONObject().apply {
                        put("role", "assistant")
                        put("content", chatres)
                    })

                    if (taskJson != null) {
                        val success = createTask(taskJson)
                        Log.d("OpenAI", "Task creation ${if (success) "succeeded" else "failed"}")
                    }

                    onResponse(chatres)
                } catch (e: Exception) {
                    Log.e("OpenAI", "Parsing error: ${e.message}")
                    onResponse("Sorry, I didn’t quite get that. Please try again.")
                } finally {
                    response.close()
                }
            }
        })
    }

    private fun createTask(taskBody: JSONObject): Boolean {
        return try {
            val mediaType = "application/json".toMediaType()
            val body = taskBody.toString().toRequestBody(mediaType)

            val request = Request.Builder()
                .url("https://ai-assistant-backend-dk0q.onrender.com/todo/tasks")
                .post(body)
                .addHeader("Authorization", "Bearer $authToken")
                .addHeader("Content-Type", "application/json")
                .build()

            val response = client.newCall(request).execute()
            val isSuccess = response.isSuccessful

            if (!isSuccess) {
                Log.e("TaskCreation", "HTTP ${response.code}: ${response.body?.string()}")
            }

            response.close()
            isSuccess
        } catch (e: Exception) {
            Log.e("TaskCreation", "Exception: ${e.message}")
            false
        }
    }
}
