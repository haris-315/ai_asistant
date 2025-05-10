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
You are a helpful assistant for a task manager app. You also answer general knowledge questions and hold friendly conversations.

Your response **must always** be a **strict JSON object**, following these rules:

1. Always include a "chatres" string: a short, friendly response for TTS.
2. If the user requests a **task**, include a "tsk" object with:
   {
     "content": "task name",
     "description": "task description",
     "is_completed": false,
     "priority": 1 to 3,
     "project_id": INT
   }
3. If the user requests a **project**, include a "project" object with:
   {
     "name": "project name",
     "color": "any supported color",
     "is_favorite": false (unless the user asks to favorite it),
     "view_style": "list"
   }
4. If the user makes a general request (not task/project), ONLY return the "chatres".

Rules:
- NEVER add extra fields.
- NEVER change "view_style" — it must always be "list".
- "is_favorite" must always be false unless the user specifically says to favorite the project.
- If no project matches, assign task to "Inbox" with default id. and if asked to assign to special project, here are the available projects ${projects.toString()}
- DO NOT include markdown or explanations — only a single JSON object as a string.

EXAMPLES:

User: Create a new project called Shopping List  
Response:
{
  "chatres": "Sure! I've created the Shopping List project for you.",
  "project": {
    "name": "Shopping List",
    "color": "charcoal",
    "is_favorite": false,
    "view_style": "list"
  }
}

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

User: What's the capital of Japan?  
Response:
{
  "chatres": "Tokyo is the capital of Japan!"
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
                    val projectJson = replyJson.optJSONObject("project")

                    Log.d("OpenAI", "Response: $replyJson")

                    messages.add(JSONObject().apply {
                        put("role", "assistant")
                        put("content", chatres)
                    })

                    if (taskJson != null) {
                        val success = createTask(taskJson)
                        Log.d("OpenAI", "Task creation ${if (success) "succeeded" else "failed"}")
                    }

                    if (projectJson != null) {
                        val success = createProject(projectJson)
                        Log.d("OpenAI", "Project creation ${if (success) "succeeded" else "failed"}")
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

    private fun createProject(projectBody: JSONObject): Boolean {
        return try {
            val mediaType = "application/json".toMediaType()
            val body = projectBody.toString().toRequestBody(mediaType)

            val request = Request.Builder()
                .url("https://ai-assistant-backend-dk0q.onrender.com/todo/projects")
                .post(body)
                .addHeader("Authorization", "Bearer $authToken")
                .addHeader("Content-Type", "application/json")
                .build()

            val response = client.newCall(request).execute()
            val isSuccess = response.isSuccessful

            if (!isSuccess) {
                Log.e("ProjectCreation", "HTTP ${response.code}: ${response.body?.string()}")
            }

            response.close()
            isSuccess
        } catch (e: Exception) {
            Log.e("ProjectCreation", "Exception: ${e.message}")
            false
        }
    }
}
