package com.example.openai

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.time.LocalDateTime
import java.time.ZonedDateTime

class OpenAIClient(
    private val context: Context,
    private val apiKey: String,
    private val authToken: String,
    private val projects: MutableList<String>
) {
    private val client = OkHttpClient()
    private val messages = mutableListOf<JSONObject>()
    private val apiUrl = "https://api.openai.com/v1/chat/completions"

    private fun buildSystemPrompt(): String {
        return """
        You are a helpful assistant for a task manager app that can also open Android applications. You answer general knowledge questions and hold friendly conversations.

        Your response **must always** be a **strict JSON object**, following these rules:

        1. Always include a "chatres" string: a short, friendly response for TTS.
        2. If the user requests a **task**, include a "tsk" object with:
           {
             "content": "task name",
             "description": "task description",
             "is_completed": false,
             "priority": 1 to 3,
             "project_id": INT,
             "due_date" : ISO-8601 (if specified),
             "reminder_at" : ISO-8601 (10 minutes less than due_date if not specified)
           }
        3. If the user requests a **project**, include a "project" object with:
           {
             "name": "project name",
             "color": "any supported color",
             "is_favorite": false (unless the user asks to favorite it),
             "view_style": "list"
           }
        4. If the user asks to open an Android app, include an "app" object with:
           {
             "package": "app.package.name",
             "name": "App Name" (optional, for display purposes)
           }
        5. If the user makes a general request (not task/project/app), ONLY return the "chatres".
        6. If the user says something like "be quiet", "go to sleep", "stop listening", or anything that implies you should stop responding or listen passively, include "shouldStandBy": true in the response.
        7. If the user says to summarize or note or save the conversation you have had with the user, then you must include "wantSummary" : true in the response.
        
        Rules:
        
        - NEVER add extra fields.
        - NEVER change "view_style" — it must always be "list".
        - "is_favorite" must always be false unless the user specifically says to favorite the project.
        - If user specifies a time, include both due_date and reminder_at in ISO format.
        - If no project matches, assign task to "Inbox" with default id. If asked to assign to special project, available projects: ${projects.toString()}
        - For app opening requests, you MUST provide the exact package name (e.g., "com.google.android.youtube" for YouTube).
        - DO NOT include markdown or explanations — only a single JSON object as a string.

        SOME INFO FOR YOU:
        - Current Time and Today's Date: ${LocalDateTime.now().toString()}. you can use this time as reference to set task reminders or due dates.
        """.trimIndent()
    }

    fun getMessageHistory(): List<JSONObject> = messages.toList()

    fun clearHistory() = messages.clear()

    fun sendMessage(
        userMessage: String,
        model: String = "gpt-4-turbo",
        onResponse: (String) -> Unit,
        onError: (String) -> Unit,
        onStandBy: () -> Unit,
        onSummaryAsked: () -> Unit
    ) {
        val systemObj = JSONObject().apply {
            put("role", "system")
            put("content", buildSystemPrompt())
        }

        val userObj = JSONObject().apply {
            put("role", "user")
            put("content", userMessage)
        }

        // Only keep one system prompt (always updated)
        messages.removeAll { it.optString("role") == "system" }
        messages.add(0, systemObj)
        messages.add(userObj)

        val requestBody = JSONObject().apply {
            put("model", model)
            put("messages", JSONArray(messages))
            put("response_format", JSONObject().apply {
                put("type", "json_object")
            })
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
                    val body = response.body?.string() ?: "{}"
                    val content = JSONObject(body)
                        .getJSONArray("choices")
                        .getJSONObject(0)
                        .getJSONObject("message")
                        .getString("content")

                    val reply = JSONObject(content)
                    val chatres = reply.optString("chatres", "Okay.")
                    val taskJson = reply.optJSONObject("tsk")
                    val projectJson = reply.optJSONObject("project")
                    val appJson = reply.optJSONObject("app")
                    val shouldStandBy = reply.optBoolean("shouldStandBy", false)
                    val hasAskedForSummary = reply.optBoolean("wantSummary")
                    messages.add(JSONObject().apply {
                        put("role", "assistant")
                        put("content", chatres)
                    })

                    taskJson?.let { createTask(it) }
                    projectJson?.let { createProject(it) }
                    appJson?.let { openApp(it.getString("package")) { success ->
                        if (!success) onResponse("I couldn't open that app.")
                    }}

                    if (shouldStandBy) onStandBy() else if (hasAskedForSummary) onSummaryAsked() else onResponse(chatres)

                } catch (e: Exception) {
                    onResponse("Sorry, I didn’t quite get that.")
                } finally {
                    response.close()
                }
            }
        })
    }

    fun generateMeetingSummary(
        transcript: String,
        model: String = "gpt-4-turbo",
        onDone: (title: String, summary: String) -> Unit,
        onError: (String) -> Unit
    ) {
        val chunkSize = 3000
        val transcriptChunks = transcript.chunked(chunkSize)
        val partialSummaries = mutableListOf<String>()

        val basePrompt = """
        You are a smart assistant. The user will give you a transcript of a meeting or a chat (done with chatgpt). Your job is to summarize it clearly short and in points like what needs to be done and what are the key points and generate a relevant title.

        Respond in this JSON format:
        {
          "title": "Brief meeting title",
          "summary": "points and sentences based short summary"
        }

        DO NOT include any markdown or explanations. Respond with ONLY the JSON string.
    """.trimIndent()

        fun summarizeChunk(index: Int) {
            if (index >= transcriptChunks.size) {
                // All partial summaries collected. Now generate the final summary.
                val mergePrompt = """
                You will now receive multiple partial summaries from a long meeting. Combine them into one coherent meeting summary and generate a suitable title.

                Respond in this JSON format:
                {
                  "title": "Final title",
                  "summary": "Merged summary paragraph"
                }

                Partial Summaries:
                ${partialSummaries.joinToString("\n")}
            """.trimIndent()

                val finalBody = JSONObject().apply {
                    put("model", model)
                    put("messages", JSONArray().apply {
                        put(JSONObject().apply {
                            put("role", "system")
                            put("content", mergePrompt)
                        })
                    })
                }

                val finalRequest = Request.Builder()
                    .url(apiUrl)
                    .addHeader("Authorization", "Bearer $apiKey")
                    .addHeader("Content-Type", "application/json")
                    .post(finalBody.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                client.newCall(finalRequest).enqueue(object : Callback {
                    override fun onFailure(call: Call, e: IOException) {
                        onError("Final summary error: ${e.message}")
                    }

                    override fun onResponse(call: Call, response: Response) {
                        try {
                            val content = JSONObject(response.body?.string() ?: "{}")
                                .getJSONArray("choices")
                                .getJSONObject(0)
                                .getJSONObject("message")
                                .getString("content")

                            val json = JSONObject(content)
                            val finalTitle = json.getString("title")
                            val finalSummary = json.getString("summary")
                            onDone(finalTitle, finalSummary)
                        } catch (e: Exception) {
                            onError("Error parsing final summary.")
                        } finally {
                            response.close()
                        }
                    }
                })

                return
            }

            val requestBody = JSONObject().apply {
                put("model", model)
                put("messages", JSONArray().apply {
                    put(JSONObject().apply {
                        put("role", "system")
                        put("content", basePrompt)
                    })
                    put(JSONObject().apply {
                        put("role", "user")
                        put("content", "Part ${index + 1} of the meeting transcript:\n${transcriptChunks[index]}")
                    })
                })
            }

            val request = Request.Builder()
                .url(apiUrl)
                .addHeader("Authorization", "Bearer $apiKey")
                .addHeader("Content-Type", "application/json")
                .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                .build()

            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    onError("Error summarizing part ${index + 1}: ${e.message}")
                }

                override fun onResponse(call: Call, response: Response) {
                    try {
                        val content = JSONObject(response.body?.string() ?: "{}")
                            .getJSONArray("choices")
                            .getJSONObject(0)
                            .getJSONObject("message")
                            .getString("content")

                        val summaryJson = JSONObject(content)
                        val partSummary = summaryJson.getString("summary")
                        partialSummaries.add(partSummary)
                        summarizeChunk(index + 1)
                    } catch (e: Exception) {
                        onError("Error parsing summary part ${index + 1}")
                    } finally {
                        response.close()
                    }
                }
            })
        }

        summarizeChunk(0)
    }


    fun insertOrUpdateSummary(
        context: Context,
        id: String,
        title: String,
        startTime: LocalDateTime,
        endTime: LocalDateTime,
        actualTranscript: String,
        summary: String
    ) {
        val dbPath = context.getDatabasePath("meeting.db").path
        val db = SQLiteDatabase.openOrCreateDatabase(dbPath, null)

        db.execSQL("""
            CREATE TABLE IF NOT EXISTS meetings (
                id TEXT PRIMARY KEY,
                title TEXT,
                startTime TEXT,
                endTime TEXT,
                actualTranscript TEXT,
                summary TEXT
            )
        """)

        val stmt = db.compileStatement("""
            INSERT OR REPLACE INTO meetings (id, title, startTime, endTime, actualTranscript, summary) 
            VALUES (?, ?, ?, ?, ?, ?)
        """)
        stmt.bindString(1, id)
        stmt.bindString(2, title)
        stmt.bindString(3, startTime.toString())
        stmt.bindString(4, endTime.toString())
        stmt.bindString(5, actualTranscript)
        stmt.bindString(6, summary)
        stmt.executeInsert()
        db.close()
    }

    private fun openApp(packageName: String, callback: (Boolean) -> Unit) {
        try {
            val intent: Intent? = context.packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                callback(true)
            } else {
                callback(false)
            }
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error opening app: ${e.message}")
            callback(false)
        }
    }

    private fun createTask(taskBody: JSONObject): Boolean {
        return try {
            val body = taskBody.toString().toRequestBody("application/json".toMediaType())
            val request = Request.Builder()
                .url("https://ai-assistant-backend-dk0q.onrender.com/todo/tasks")
                .post(body)
                .addHeader("Authorization", "Bearer $authToken")
                .addHeader("Content-Type", "application/json")
                .build()
            val response = client.newCall(request).execute()
            response.close()
            response.isSuccessful
        } catch (e: Exception) {
            false
        }
    }

    private fun createProject(projectBody: JSONObject): Boolean {
        return try {
            val body = projectBody.toString().toRequestBody("application/json".toMediaType())
            val request = Request.Builder()
                .url("https://ai-assistant-backend-dk0q.onrender.com/todo/projects")
                .post(body)
                .addHeader("Authorization", "Bearer $authToken")
                .addHeader("Content-Type", "application/json")
                .build()
            val response = client.newCall(request).execute()
            response.close()
            response.isSuccessful
        } catch (e: Exception) {
            false
        }
    }
}
