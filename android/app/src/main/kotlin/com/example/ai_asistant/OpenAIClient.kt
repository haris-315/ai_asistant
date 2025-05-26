package com.example.openai

import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.time.LocalDateTime
import java.util.UUID
import java.util.concurrent.TimeUnit

class OpenAIClient(
    private val context: Context,
    private val apiKey: String,
    private val authToken: String,
    private val projects: MutableList<String>
) {
    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(120, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()
    private val messages = mutableListOf<JSONObject>()
    private val maxMessages = 50
    private var lastMeetingTime = LocalDateTime.now()

    // SharedData placeholder (replace with your actual implementation)
    object SharedData {
        var tasks: List<Map<String, Any>> = emptyList()
    }

    interface FunctionDefinition {
        val name: String
        val description: String
        val parameters: JSONObject
        fun execute(args: JSONObject, client: OpenAIClient): Boolean
    }

    private val functionDefinitions = listOf(
        object : FunctionDefinition {
            override val name = "create_task"
            override val description = "Create a new task in the task manager."
            override val parameters = JSONObject().apply {
                put("type", "object")
                put("properties", JSONObject().apply {
                    put("content", JSONObject().apply { put("type", "string"); put("description", "Task name") })
                    put("description", JSONObject().apply { put("type", "string"); put("description", "Task description") })
                    put("priority", JSONObject().apply {
                        put("type", "integer")
                        put("description", "Priority (1-3)")
                        put("enum", JSONArray().apply { put(1); put(2); put(3) })
                    })
                    put("project_id", JSONObject().apply {
                        put("type", "integer")
                        put("description", "Project ID (use 0 for Inbox)")
                    })
                    put("due_date", JSONObject().apply { put("type", "string"); put("description", "Due date in ISO-8601 format (optional)") })
                    put("reminder_at", JSONObject().apply { put("type", "string"); put("description", "Reminder time in ISO-8601 format (optional)") })
                })
                put("required", JSONArray().apply { put("content"); put("description"); put("priority"); put("project_id") })
            }
            override fun execute(args: JSONObject, client: OpenAIClient): Boolean = client.createTask(args)
        },
        object : FunctionDefinition {
            override val name = "update_task"
            override val description = "Update an existing task."
            override val parameters = JSONObject().apply {
                put("type", "object")
                put("properties", JSONObject().apply {
                    put("id", JSONObject().apply { put("type", "string"); put("description", "Task ID") })
                    put("content", JSONObject().apply { put("type", "string"); put("description", "Task name") })
                    put("description", JSONObject().apply { put("type", "string"); put("description", "Task description") })
                    put("is_completed", JSONObject().apply { put("type", "boolean"); put("description", "Completion status") })
                    put("priority", JSONObject().apply { put("type", "integer"); put("description", "Priority (1-3)") })
                    put("project_id", JSONObject().apply { put("type", "integer"); put("description", "Project ID") })
                    put("due_date", JSONObject().apply { put("type", "string"); put("description", "Due date in ISO-8601 format (optional)") })
                    put("reminder_at", JSONObject().apply { put("type", "string"); put("description", "Reminder time in ISO-8601 format (optional)") })
                })
                put("required", JSONArray().apply { put("id"); put("content"); put("description"); put("is_completed"); put("priority"); put("project_id") })
            }
            override fun execute(args: JSONObject, client: OpenAIClient): Boolean = client.updateTask(args)
        },
        object : FunctionDefinition {
            override val name = "create_project"
            override val description = "Create a new project."
            override val parameters = JSONObject().apply {
                put("type", "object")
                put("properties", JSONObject().apply {
                    put("name", JSONObject().apply { put("type", "string"); put("description", "Project name") })
                    put("color", JSONObject().apply { put("type", "string"); put("description", "Project color") })
                    put("is_favorite", JSONObject().apply { put("type", "boolean"); put("description", "Favorite status (default false)") })
                    put("view_style", JSONObject().apply {
                        put("type", "string")
                        put("description", "View style (always 'list')")
                        put("enum", JSONArray().apply { put("list") })
                    })
                })
                put("required", JSONArray().apply { put("name"); put("color"); put("is_favorite"); put("view_style") })
            }
            override fun execute(args: JSONObject, client: OpenAIClient): Boolean = client.createProject(args)
        },
        object : FunctionDefinition {
            override val name = "open_app"
            override val description = "Open an Android app by package name."
            override val parameters = JSONObject().apply {
                put("type", "object")
                put("properties", JSONObject().apply {
                    put("package", JSONObject().apply { put("type", "string"); put("description", "App package name (e.g., com.google.android.youtube)") })
                    put("name", JSONObject().apply { put("type", "string"); put("description", "App name (optional)") })
                })
                put("required", JSONArray().apply { put("package") })
            }
            override fun execute(args: JSONObject, client: OpenAIClient): Boolean {
                var success = false
                client.openApp(args.getString("package")) { result -> success = result }
                return success
            }
        },
        object : FunctionDefinition {
            override val name = "standby"
            override val description = "Enter standby mode."
            override val parameters = JSONObject().apply { put("type", "object"); put("properties", JSONObject()) }
            override fun execute(args: JSONObject, client: OpenAIClient): Boolean = true
        },
        object : FunctionDefinition {
            override val name = "summarize_conversation"
            override val description = "Summarize the conversation history."
            override val parameters = JSONObject().apply { put("type", "object"); put("properties", JSONObject()) }
            override fun execute(args: JSONObject, client: OpenAIClient): Boolean = true
        }
    )

    private fun buildSystemPrompt(): String {
        return """
        You are a helpful assistant for a task manager app that can also open Android apps. You answer general knowledge questions and hold friendly conversations.

        Your response **must always be a plain text string (suitable response suitable for text-to-speech), and you must use function calls to handle specific actions. Do not include JSON or action details in the response text.

        Actions to handle via function calls:
        - Creating a task: Use `create_task`.
        - Updating a task: Use `update_task`.
        - Creating a project: Use `create_project`.
        - Opening an Android app: Use `open_app`.
        - Entering standby mode: Use `standby`.
        - Summarizing conversation: Use `summarize_conversation`.

        Rules:
        - Return short, friendly text responses for text-to-speech.
        - Use function calls for actions; do not embed details in text.
        - For apps, use exact package names (e.g., "com.google.android.youtube").
        - Assign tasks to "Inbox" (project_id=0) if no project matches.
        - Available projects: ${projects.joinToString()}
        - Current time: ${LocalDateTime.now()}
        - Current tasks: ${SharedData.tasks.joinToString()}
        - No markdown or explanations in responses.

        Examples:
        - "What time is it?": "The current time is 08:48 PM."
        - "Create a task to buy milk": "Task created to buy milk." + call `create_task`.
        - "Stop listening": "Entering standby mode." + call `standby`.
        """.trimIndent()
    }

    private fun buildTools(): JSONArray {
        val tools = JSONArray()
        functionDefinitions.forEach { def ->
            tools.put(JSONObject().apply {
                put("type", "function")
                put("function", JSONObject().apply {
                    put("name", def.name)
                    put("description", def.description)
                    put("parameters", def.parameters)
                })
            })
        }
        return tools
    }

    fun getMessageHistory(): List<JSONObject> = messages.subList(1, messages.size.coerceAtLeast(1))

    fun clearHistory() {
        messages.clear()
        Log.d("OpenAIClient", "Message history cleared")
    }

    fun sendMessage(
        userMessage: String,
        model: String = "gpt-4-turbo",
        onResponse: (String) -> Unit,
        onError: (String) -> Unit,
        onStandBy: () -> Unit,
        onSummaryAsked: () -> Unit
    ) {
        if (userMessage.isBlank()) {
            Log.w("OpenAIClient", "Empty user message")
            onError("Please provide a valid message")
            return
        }

        // Add user message
        messages.add(JSONObject().apply {
            put("role", "user")
            put("content", userMessage)
        })
        if (messages.size > maxMessages) {
            messages.removeAt(0)
        }

        // Validate message history
        val validMessages = mutableListOf<JSONObject>()
        val activeToolCallIds = mutableSetOf<String>()
        messages.forEach { msg ->
            if (msg.optString("role") == "assistant" && msg.has("tool_calls")) {
                val toolCalls = msg.getJSONArray("tool_calls")
                for (i in 0 until toolCalls.length()) {
                    activeToolCallIds.add(toolCalls.getJSONObject(i).getString("id"))
                }
            }
            if (msg.optString("role") == "tool" && !activeToolCallIds.contains(msg.optString("tool_call_id"))) {
                Log.d("OpenAIClient", "Skipping stale tool message: ${msg.optString("tool_call_id")}")
                return@forEach
            }
            validMessages.add(msg)
        }

        // Build initial request
        val body = JSONObject().apply {
            put("model", model)
            put("messages", JSONArray().apply {
                put(JSONObject().apply {
                    put("role", "system")
                    put("content", buildSystemPrompt())
                })
                validMessages.forEach { put(it) }
            })
            put("tools", buildTools())
            put("tool_choice", "auto")
        }

        val request = Request.Builder()
            .url("https://api.openai.com/v1/chat/completions")
            .addHeader("Authorization", "Bearer $apiKey")
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()

        executeWithRetry(
            request = request,
            onSuccess = { response ->
                try {
                    val responseBody = response.body?.string() ?: throw IOException("Empty response")
                    val content = JSONObject(responseBody)
                        .getJSONArray("choices")
                        .getJSONObject(0)
                        .getJSONObject("message")
                    val chatres = content.optString("content", "").trim()
                    val toolCalls = content.optJSONArray("tool_calls") ?: JSONArray()

                    // Add assistant message
                    messages.add(content)
                    if (messages.size > maxMessages) {
                        messages.removeAt(0)
                    }

                    // Speak initial response
                    if (chatres.isNotEmpty()) {
                        onResponse(chatres)
                    }

                    // Process tool calls
                    if (toolCalls.length() > 0) {
                        val toolResponses = mutableListOf<JSONObject>()
                        for (i in 0 until toolCalls.length()) {
                            val toolCall = toolCalls.getJSONObject(i)
                            val toolCallId = toolCall.getString("id")
                            val function = toolCall.getJSONObject("function")
                            val name = function.getString("name")
                            try {
                                val args = JSONObject(function.getString("arguments"))
                                val functionDef = functionDefinitions.find { it.name == name }
                                if (functionDef != null) {
                                    val success = functionDef.execute(args, this)
                                    if (name == "standby") {
                                        onStandBy()
                                        toolResponses.add(JSONObject().apply {
                                            put("role", "tool")
                                            put("content", JSONObject().put("status", "standby").toString())
                                            put("tool_call_id", toolCallId)
                                            put("name", "standby")
                                        })
                                    } else if (name == "summarize_conversation") {
                                        onSummaryAsked()
                                        toolResponses.add(JSONObject().apply {
                                            put("role", "tool")
                                            put("content", JSONObject().put("status", "summary_requested").toString())
                                            put("tool_call_id", toolCallId)
                                            put("name", "summarize_conversation")
                                        })
                                    } else if (!success) {
                                        toolResponses.add(JSONObject().apply {
                                            put("role", "tool")
                                            put("content", JSONObject().put("error", "Failed to execute $name").toString())
                                            put("tool_call_id", toolCallId)
                                            put("name", name)
                                        })
                                    }
                                } else {
                                    Log.w("OpenAIClient", "Unknown function: $name")
                                    toolResponses.add(JSONObject().apply {
                                        put("role", "tool")
                                        put("content", JSONObject().put("error", "Unknown function $name").toString())
                                        put("tool_call_id", toolCallId)
                                        put("name", name)
                                    })
                                }
                            } catch (e: Exception) {
                                Log.e("OpenAIClient", "Error processing tool call $name: ${e.message}")
                                toolResponses.add(JSONObject().apply {
                                    put("role", "tool")
                                    put("content", JSONObject().put("error", "Error: ${e.message}").toString())
                                    put("tool_call_id", toolCallId)
                                    put("name", name)
                                })
                            }
                        }

                        // Add tool responses
                        toolResponses.forEach { messages.add(it) }
                        if (messages.size > maxMessages) {
                            messages.removeAt(0)
                        }

                        // Send follow-up request
                        val followUpBody = JSONObject().apply {
                            put("model", model)
                            put("messages", JSONArray().apply {
                                put(JSONObject().apply {
                                    put("role", "system")
                                    put("content", buildSystemPrompt())
                                })
                                messages.forEach { put(it) }
                            })
                            put("tools", buildTools())
                            put("tool_choice", "auto")
                        }

                        val followUpRequest = Request.Builder()
                            .url("https://api.openai.com/v1/chat/completions")
                            .addHeader("Authorization", "Bearer $apiKey")
                            .addHeader("Content-Type", "application/json")
                            .post(followUpBody.toString().toRequestBody("application/json".toMediaType()))
                            .build()

                        executeWithRetry(
                            request = followUpRequest,
                            onSuccess = { followUpResponse ->
                                try {
                                    val followUpBody = followUpResponse.body?.string() ?: throw IOException("Empty follow-up response")
                                    val followUpContent = JSONObject(followUpBody)
                                        .getJSONArray("choices")
                                        .getJSONObject(0)
                                        .getJSONObject("message")
                                    val followUpChatres = followUpContent.optString("content", "").trim()
                                    if (followUpChatres.isNotEmpty()) {
                                        messages.add(JSONObject().apply {
                                            put("role", "assistant")
                                            put("content", followUpChatres)
                                        })
                                        if (messages.size > maxMessages) {
                                            messages.removeAt(0)
                                        }
                                        onResponse(followUpChatres)
                                    } else {
                                        Log.w("OpenAIClient", "Empty follow-up response")
                                        onError("No response received after processing action")
                                    }
                                } catch (e: Exception) {
                                    Log.e("OpenAIClient", "Error parsing follow-up response: ${e.message}")
                                    onError("Error processing response: ${e.message}")
                                } finally {
                                    followUpResponse.close()
                                }
                            },
                            onFailure = { error ->
                                Log.e("OpenAIClient", "Follow-up request failed: $error")
                                onError("Request failed: $error")
                            }
                        )
                    } else if (chatres.isEmpty()) {
                        Log.w("OpenAIClient", "Empty response and no tool calls")
                        onError("No response received")
                    }
                } catch (e: Exception) {
                    Log.e("OpenAIClient", "Error parsing response: ${e.message}")
                    onError("Error processing response: ${e.message}")
                } finally {
                    response.close()
                }
            },
            onFailure = { error ->
                Log.e("OpenAIClient", "Request failed: $error")
                onError("Request failed: $error")
            }
        )
    }

    fun generateMeetingSummary(
        transcript: String,
        model: String = "gpt-4-turbo",
        onDone: (String, String, List<String>) -> Unit,
        onError: (String) -> Unit
    ) {
        if (transcript.isBlank()) {
            Log.w("OpenAIClient", "Empty transcript")
            onError("No transcript provided")
            insertOrUpdateSummary(
                context = context,
                id = UUID.randomUUID().toString(),
                title = "Not Summarized",
                startTime = lastMeetingTime,
                endTime = LocalDateTime.now(),
                actualTranscript = "",
                summary = "No transcript provided",
                keypoints = emptyList()
            )
            return
        }

        lastMeetingTime = LocalDateTime.now()
        val chunkSize = 3000
        val chunks = transcript.chunked(chunkSize)
        val partialSummaries = mutableListOf<JSONObject>()

        val basePrompt = """
        You are a smart assistant. Summarize the provided meeting transcript clearly and concisely, identify key points, and generate a relevant title.

        Respond in JSON format:
        {
          "title": "Brief meeting title",
          "summary": "Summary paragraph (short)",
          "keypoints": ["Key point 1", "Key point 2", ...]
        }
        """.trimIndent()

        fun summarizeChunk(index: Int) {
            if (index >= chunks.size) {
                val mergePrompt = """
                Combine these partial summaries into one coherent meeting summary, consolidate the keypoints, and generate a suitable title.

                Respond in JSON format:
                {
                  "title": "Final title",
                  "summary": "Merged summary paragraph",
                  "keypoints": ["Consolidated key point 1", "Consolidated key point 2", ...]
                }

                Partial Summaries:
                ${partialSummaries.joinToString("\n") { it.toString() }}
                """.trimIndent()

                val request = Request.Builder()
                    .url("https://api.openai.com/v1/chat/completions")
                    .addHeader("Authorization", "Bearer $apiKey")
                    .addHeader("Content-Type", "application/json")
                    .post(JSONObject().apply {
                        put("model", model)
                        put("messages", JSONArray().apply {
                            put(JSONObject().apply {
                                put("role", "system")
                                put("content", mergePrompt)
                            })
                        })
                    }.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                executeWithRetry(
                    request = request,
                    onSuccess = { response ->
                        try {
                            val content = JSONObject(response.body?.string() ?: "{}")
                                .getJSONArray("choices")
                                .getJSONObject(0)
                                .getJSONObject("message")
                                .getString("content")
                            val json = JSONObject(content)
                            val finalTitle = json.getString("title")
                            val finalSummary = json.getString("summary")
                            val keypointsArray = json.getJSONArray("keypoints")
                            val keypoints = (0 until keypointsArray.length()).map { keypointsArray.getString(it) }

                            insertOrUpdateSummary(
                                context = context,
                                id = UUID.randomUUID().toString(),
                                title = finalTitle,
                                startTime = lastMeetingTime,
                                endTime = LocalDateTime.now(),
                                actualTranscript = transcript,
                                summary = finalSummary,
                                keypoints = keypoints
                            )
                            onDone(finalTitle, finalSummary, keypoints)
                        } catch (e: Exception) {
                            Log.e("OpenAIClient", "Error parsing final summary: ${e.message}")
                            onError("Error generating final summary")
                            insertOrUpdateSummary(
                                context = context,
                                id = UUID.randomUUID().toString(),
                                title = "Not Summarized",
                                startTime = lastMeetingTime,
                                endTime = LocalDateTime.now(),
                                actualTranscript = transcript,
                                summary = "Failed summarizing",
                                keypoints = emptyList()
                            )
                        } finally {
                            response.close()
                        }
                    },
                    onFailure = { error ->
                        Log.e("OpenAIClient", "Final summary error: $error")
                        onError("Final summary error: $error")
                        insertOrUpdateSummary(
                            context = context,
                            id = UUID.randomUUID().toString(),
                            title = "Not Summarized",
                            startTime = lastMeetingTime,
                            endTime = LocalDateTime.now(),
                            actualTranscript = transcript,
                            summary = "Failed summarizing",
                            keypoints = emptyList()
                        )
                    }
                )
                return
            }

            val request = Request.Builder()
                .url("https://api.openai.com/v1/chat/completions")
                .addHeader("Authorization", "Bearer $apiKey")
                .addHeader("Content-Type", "application/json")
                .post(JSONObject().apply {
                    put("model", model)
                    put("messages", JSONArray().apply {
                        put(JSONObject().apply {
                            put("role", "system")
                            put("content", basePrompt)
                        })
                        put(JSONObject().apply {
                            put("role", "user")
                            put("content", "Part ${index + 1} of the meeting transcript:\n${chunks[index]}")
                        })
                    })
                }.toString().toRequestBody("application/json".toMediaType()))
                .build()

            executeWithRetry(
                request = request,
                onSuccess = { response ->
                    try {
                        val content = JSONObject(response.body?.string() ?: "{}")
                            .getJSONArray("choices")
                            .getJSONObject(0)
                            .getJSONObject("message")
                            .getString("content")
                        partialSummaries.add(JSONObject(content))
                        summarizeChunk(index + 1)
                    } catch (e: Exception) {
                        Log.e("OpenAIClient", "Error parsing summary part ${index + 1}: ${e.message}")
                        onError("Error summarizing part ${index + 1}")
                        insertOrUpdateSummary(
                            context = context,
                            id = UUID.randomUUID().toString(),
                            title = "Not Summarized",
                            startTime = lastMeetingTime,
                            endTime = LocalDateTime.now(),
                            actualTranscript = transcript,
                            summary = "Failed summarizing part ${index + 1}",
                            keypoints = emptyList()
                        )
                    } finally {
                        response.close()
                    }
                },
                onFailure = { error ->
                    Log.e("OpenAIClient", "Error summarizing part ${index + 1}: $error")
                    onError("Error summarizing part ${index + 1}")
                    insertOrUpdateSummary(
                        context = context,
                        id = UUID.randomUUID().toString(),
                        title = "Not Summarized",
                        startTime = lastMeetingTime,
                        endTime = LocalDateTime.now(),
                        actualTranscript = transcript,
                        summary = "Failed summarizing part ${index + 1}",
                        keypoints = emptyList()
                    )
                }
            )
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
        summary: String,
        keypoints: List<String>
    ) {
        var retryCount = 0
        val maxRetries = 3
        while (retryCount < maxRetries) {
            try {
                val dbPath = context.getDatabasePath("meeting.db").path
                val db = SQLiteDatabase.openOrCreateDatabase(dbPath, null)

                db.execSQL("""
                    CREATE TABLE IF NOT EXISTS meetings (
                        id TEXT PRIMARY KEY,
                        title TEXT,
                        startTime TEXT,
                        endTime TEXT,
                        actualTranscript TEXT,
                        summary TEXT,
                        keypoints TEXT
                    )
                """.trimIndent())

                val stmt = db.compileStatement("""
                    INSERT OR REPLACE INTO meetings (id, title, startTime, endTime, actualTranscript, summary, keypoints)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """.trimIndent())
                stmt.bindString(1, id)
                stmt.bindString(2, title)
                stmt.bindString(3, startTime.toString())
                stmt.bindString(4, endTime.toString())
                stmt.bindString(5, actualTranscript)
                stmt.bindString(6, summary)
                stmt.bindString(7, JSONArray(keypoints).toString())
                stmt.executeInsert()
                db.close()
                Log.d("OpenAIClient", "Summary inserted/updated: $title")
                return
            } catch (e: Exception) {
                retryCount++
                Log.e("OpenAIClient", "Error inserting summary (attempt $retryCount): ${e.message}")
                if (retryCount == maxRetries) {
                    Log.e("OpenAIClient", "Max retries reached for summary insertion")
                }
                Thread.sleep(500)
            }
        }
    }

    private fun openApp(packageName: String, callback: (Boolean) -> Unit) {
        try {
            val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                Log.d("OpenAIClient", "Opened app: $packageName")
                callback(true)
            } else {
                Log.w("OpenAIClient", "No launch intent for package: $packageName")
                callback(false)
            }
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error opening app: ${e.message}")
            callback(false)
        }
    }

    private fun createTask(args: JSONObject): Boolean {
        try {
            val taskBody = JSONObject().apply {
                put("content", args.getString("content"))
                put("description", args.getString("description"))
                put("is_completed", false)
                put("priority", args.getInt("priority"))
                put("project_id", args.getInt("project_id"))
                if (args.has("due_date")) put("due_date", args.getString("due_date"))
                if (args.has("reminder_at")) put("reminder_at", args.getString("reminder_at"))
            }
            val body = taskBody.toString().toRequestBody("application/json".toMediaType())
            val request = Request.Builder()
                .url("https://ai-assistant-backend-nine.vercel.app/todo/tasks/")
                .post(body)
                .addHeader("Authorization", "Bearer $authToken")
                .addHeader("Content-Type", "application/json")
                .build()

            var success = false
            executeWithRetry(
                request = request,
                onSuccess = { response ->
                    try {
                        if (response.isSuccessful) {
                            val responseBody = response.body?.string() ?: throw IOException("Empty response body")
                            val taskId = JSONObject(responseBody).optString("id")
                            val taskMap = mutableMapOf<String, Any>().apply {
                                put("id", taskId)
                                put("content", taskBody.getString("content"))
                                put("description", taskBody.getString("description"))
                                put("is_completed", taskBody.getBoolean("is_completed"))
                                put("priority", taskBody.getInt("priority"))
                                put("project_id", taskBody.getInt("project_id"))
                                if (taskBody.has("due_date")) put("due_date", taskBody.getString("due_date"))
                                if (taskBody.has("reminder_at")) put("reminder_at", taskBody.getString("reminder_at"))
                            }
                            SharedData.tasks = SharedData.tasks.toMutableList().apply { add(taskMap) }
                            Log.d("OpenAIClient", "Task created: $taskMap")
                            success = true
                        } else {
                            Log.w("OpenAIClient", "Task creation failed: ${response.code}")
                        }
                    } catch (e: Exception) {
                        Log.e("OpenAIClient", "Error processing task creation: ${e.message}")
                    } finally {
                        response.close()
                    }
                },
                onFailure = { error ->
                    Log.e("OpenAIClient", "Task creation failed: $error")
                }
            )
            return success
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error creating task: ${e.message}")
            return false
        }
    }

    private fun updateTask(args: JSONObject): Boolean {
        try {
            val taskId = args.getString("id")
            val taskBody = JSONObject().apply {
                put("content", args.getString("content"))
                put("description", args.getString("description"))
                put("is_completed", args.getBoolean("is_completed"))
                put("priority", args.getInt("priority"))
                put("project_id", args.getInt("project_id"))
                if (args.has("due_date")) put("due_date", args.getString("due_date"))
                if (args.has("reminder_at")) put("reminder_at", args.getString("reminder_at"))
            }
            val body = taskBody.toString().toRequestBody("application/json".toMediaType())
            val request = Request.Builder()
                .url("https://ai-assistant-backend-nine.vercel.app/todo/tasks/$taskId")
                .put(body)
                .addHeader("Authorization", "Bearer $authToken")
                .addHeader("Content-Type", "application/json")
                .build()

            var success = false
            executeWithRetry(
                request = request,
                onSuccess = { response ->
                    try {
                        if (response.isSuccessful) {
                            val taskMap = mutableMapOf<String, Any>().apply {
                                put("id", taskId)
                                put("content", taskBody.getString("content"))
                                put("description", taskBody.getString("description"))
                                put("is_completed", taskBody.getBoolean("is_completed"))
                                put("priority", taskBody.getInt("priority"))
                                put("project_id", taskBody.getInt("project_id"))
                                if (taskBody.has("due_date")) put("due_date", taskBody.getString("due_date"))
                                if (taskBody.has("reminder_at")) put("reminder_at", taskBody.getString("reminder_at"))
                            }
                            SharedData.tasks = SharedData.tasks.toMutableList().apply {
                                val index = indexOfFirst { it["id"] == taskId }
                                if (index >= 0) set(index, taskMap) else add(taskMap)
                            }
                            Log.d("OpenAIClient", "Task updated: $taskMap")
                            success = true
                        } else {
                            Log.w("OpenAIClient", "Task update failed: ${response.code}")
                        }
                    } catch (e: Exception) {
                        Log.e("OpenAIClient", "Error processing task update: ${e.message}")
                    } finally {
                        response.close()
                    }
                },
                onFailure = { error ->
                    Log.e("OpenAIClient", "Task update failed: $error")
                }
            )
            return success
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error updating task: ${e.message}")
            return false
        }
    }

    private fun createProject(args: JSONObject): Boolean {
        try {
            val projectBody = JSONObject().apply {
                put("name", args.getString("name"))
                put("color", args.getString("color"))
                put("is_favorite", args.getBoolean("is_favorite"))
                put("view_style", args.getString("view_style"))
            }
            val body = projectBody.toString().toRequestBody("application/json".toMediaType())
            val request = Request.Builder()
                .url("https://ai-assistant-backend-nine.vercel.app/todo/projects/")
                .post(body)
                .addHeader("Authorization", "Bearer $authToken")
                .addHeader("Content-Type", "application/json")
                .build()

            var success = false
            executeWithRetry(
                request = request,
                onSuccess = { response ->
                    try {
                        if (response.isSuccessful) {
                            val projectName = projectBody.getString("name")
                            projects.add(projectName)
                            Log.d("OpenAIClient", "Project created: $projectName")
                            success = true
                        } else {
                            Log.w("OpenAIClient", "Project creation failed: ${response.code}")
                        }
                    } catch (e: Exception) {
                        Log.e("OpenAIClient", "Error processing project creation: ${e.message}")
                    } finally {
                        response.close()
                    }
                },
                onFailure = { error ->
                    Log.e("OpenAIClient", "Project creation failed: $error")
                }
            )
            return success
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error creating project: ${e.message}")
            return false
        }
    }

    private fun executeWithRetry(
        request: Request,
        onSuccess: (Response) -> Unit,
        onFailure: (String) -> Unit,
        maxRetries: Int = 3
    ) {
        var retryCount = 0
        while (retryCount < maxRetries) {
            try {
                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    onSuccess(response)
                    return
                } else {
                    val errorBody = response.body?.string() ?: "Unknown error"
                    Log.w("OpenAIClient", "Request failed: ${response.code}, $errorBody")
                    response.close()
                    if (retryCount < maxRetries - 1) {
                        retryCount++
                        Thread.sleep((2000 * retryCount).toLong())
                        continue
                    }
                    onFailure("HTTP error: ${response.code}, $errorBody")
                    return
                }
            } catch (e: IOException) {
                retryCount++
                Log.w("OpenAIClient", "Request attempt $retryCount failed: ${e.message}")
                if (retryCount < maxRetries) {
                    Thread.sleep((2000 * retryCount).toLong())
                    continue
                }
                onFailure("Request failed after retries: ${e.message}")
                return
            }
        }
    }
}