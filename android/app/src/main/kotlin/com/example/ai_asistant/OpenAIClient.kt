package com.example.openai

import android.content.Context

import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale
import java.util.UUID
import java.util.concurrent.TimeUnit

class OpenAIClient(
    val context: Context,
    val apiKey: String,
    val authToken: String,
    val projects: MutableList<String>
) {
    val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(120, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()
    private val messages = mutableListOf<JSONObject>()
    private val maxMessages = 50
    private var lastMeetingTime = LocalDateTime.now()
    private val functionProvider = FunctionDefinitionProvider(this)
    private val systemInfoProvider = SystemInfoProvider(context)
    val dbHelper = DatabaseHelper(context)
    private val networkHelper = NetworkHelper(client, apiKey, authToken)

    private fun getFormattedDateTime(): String {
        val zdt = ZonedDateTime.now(ZoneOffset.UTC)
        val isoDateTime = zdt.format(DateTimeFormatter.ISO_INSTANT) // Always ends in 'Z'
        val dayOfWeek = zdt.dayOfWeek.getDisplayName(TextStyle.FULL, Locale.getDefault())
        return "$isoDateTime UTC and the day is $dayOfWeek"
    }


    private fun buildSystemPrompt(): String {
        val userData = dbHelper.fetchUserData()
        val batteryPercentage = systemInfoProvider.getBatteryPercentage()
        val deviceModel = systemInfoProvider.getDeviceModel()
        val availableStorage = systemInfoProvider.getAvailableStorage()
        val projects = SharedData.projects
        return """
        You are a helpful assistant for a task manager app that can also open Android apps, make phone calls, and fetch weather details. You answer general knowledge questions and hold friendly conversations. Your name is Jarvis.

        Your response **must always be a plain text string (suitable for text-to-speech that feels like a normal human is speaking so keep the puncutation in such a way that when spoken by tts engine, it feels like a human conversation.), and you must use function calls to handle specific actions. Do not include JSON or action details in the response text.
        
        When asked about system information, provide the following details when relevant:
        - Battery percentage: $batteryPercentage%
        - Current time and timezone: ${getFormattedDateTime()} (Strictly use these for every need.)
        - Device model: $deviceModel
        - Available storage: $availableStorage

        Actions to handle via function calls:
        - Creating a task: Use `create_task`.
        - Updating a task: Use `update_task`.
        - Creating a project: Use `create_project`.
        - Opening an Android app: Use `open_app`.
        - Entering standby mode: Use `standby`.
        - Summarizing conversation: Use `summarize_conversation`.
        - Collecting user data: Use `collect_user_data` when the prompt contains relevant personal information (e.g., name, preferences) that could improve future responses, but only if it’s useful and not repetitive. Limit to 24 data points.
        - Calling a contact: Use `call_contact`. If multiple contacts match the name, the function returns a list of contacts. Ask the user to choose one by name and call `call_contact` again with the contact_id.
        - Fetching weather: Use `get_weather` with the location name. Return the temperature in Celsius and the weather condition in the response text.
        - Answering any question from emails of the specific day: Use 'get_email_report_by_day' with the date in the format YYYY-MM-DD. Answer the question that use asked from the report.
        
        Rules:
        - Return short, friendly text responses for text-to-speech.
        - Use function calls for actions; do not embed details in text.
        - For apps, use exact package names (e.g., "com.google.android.youtube").
        - For phone calls, if multiple contacts are found, respond with a question listing their full names and wait for user clarification.
        - For weather, use the location name provided by the user and return a concise summary (e.g., temperature and condition).
        - Assign tasks the id of the project named "Inbox" if no other project matches.
        - Available projects: ${projects.joinToString()}
        - Current tasks: ${SharedData.tasks.joinToString()} (If asked about specific task or anything related to tasks, provide the info of that task if available.)
        - User data: ${userData.joinToString()}
        - No markdown or explanations in responses.

        Examples:
        - "What time is it?": "The current time is 08:48 PM."
        - "What's the battery level?": "The battery is at $batteryPercentage%."
        - "What's my device model?": "Your device is a $deviceModel."
        - "How much storage is available?": "You have $availableStorage of storage available."
        - "What is my emails report": call get_email_report_by_day
        - "Create a task to buy milk": "Task created to buy milk." + call `create_task`.
        - "Stop listening": "Entering standby mode." + call `standby`.
        - "My name is John": "Thanks for sharing, John!" + call `collect_user_data` with "Name is John".
        - "Call John": If multiple Johns, respond: "I found multiple contacts named John: John Smith, John Doe. Which one would you like to call?" + call `call_contact` with contact_id after user response. Try to partially match the name if it does not matches exactly.
        - "What's the weather in Oslo?": "The weather in Oslo is 15°C with partly cloudy skies." + call `get_weather` with location "Oslo".
        """.trimIndent()
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

        messages.add(JSONObject().apply {
            put("role", "user")
            put("content", userMessage)
        })
        if (messages.size > maxMessages) {
            messages.removeAt(0)
        }

        val requestMessages = JSONArray().apply {
            put(JSONObject().apply {
                put("role", "system")
                put("content", buildSystemPrompt())
            })
            messages.forEach { put(it) }
        }

        val body = JSONObject().apply {
            put("model", model)
            put("messages", requestMessages)
            put("tools", functionProvider.buildTools())
            put("tool_choice", "auto")
        }

        val request = Request.Builder()
            .url("https://api.openai.com/v1/chat/completions")
            .addHeader("Authorization", "Bearer $apiKey")
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()

        networkHelper.executeWithRetry(
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

                    messages.add(content)
                    if (messages.size > maxMessages) {
                        messages.removeAt(0)
                    }

                    if (chatres.isNotEmpty()) {
                        onResponse(chatres)
                    }

                    val toolResponses = mutableListOf<JSONObject>()
                    if (toolCalls.length() > 0) {
                        for (i in 0 until toolCalls.length()) {
                            val toolCall = toolCalls.getJSONObject(i)
                            val toolCallId = toolCall.getString("id")
                            val function = toolCall.getJSONObject("function")
                            val name = function.getString("name")
                            var toolResponseContent = JSONObject()

                            try {
                                val args = JSONObject(function.getString("arguments"))
                                val result = functionProvider.executeFunction(name, args)
                                toolResponseContent = result
                                if (name == "standby") {
                                    onStandBy()
                                } else if (name == "summarize_conversation") {
                                    onSummaryAsked()
                                }
                            } catch (e: Exception) {
                                Log.e("OpenAIClient", "Error processing tool call $name: ${e.message}")
                                toolResponseContent.put("error", "Error: ${e.message}")
                            }

                            toolResponses.add(JSONObject().apply {
                                put("role", "tool")
                                put("content", toolResponseContent.toString())
                                put("tool_call_id", toolCallId)
                                put("name", name)
                            })
                        }

                        toolResponses.forEach { messages.add(it) }
                        if (messages.size > maxMessages) {
                            messages.removeAt(0)
                        }

                        Log.d("OpenAIClient", "Messages before follow-up: ${messages.joinToString { it.toString() }}")

                        val followUpBody = JSONObject().apply {
                            put("model", model)
                            put("messages", JSONArray().apply {
                                put(JSONObject().apply {
                                    put("role", "system")
                                    put("content", buildSystemPrompt())
                                })
                                messages.forEach { put(it) }
                            })
                            put("tools", functionProvider.buildTools())
                            put("tool_choice", "auto")
                        }

                        val followUpRequest = Request.Builder()
                            .url("https://api.openai.com/v1/chat/completions")
                            .addHeader("Authorization", "Bearer $apiKey")
                            .addHeader("Content-Type", "application/json")
                            .post(followUpBody.toString().toRequestBody("application/json".toMediaType()))
                            .build()

                        networkHelper.executeWithRetry(
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
            dbHelper.insertOrUpdateSummary(
                id = UUID.randomUUID().toString(),
                title = "Not Summarized",
                startTime = LocalDateTime.now(),
                endTime = LocalDateTime.now(),
                actualTranscript = "",
                summary = "No transcript provided",
                keypoints = emptyList()
            )
            return
        }

        val job = CoroutineScope(Dispatchers.IO).launch {
            try {
                val startTime = LocalDateTime.now()
                val chunkSize = 3000
                val chunks = transcript.chunked(chunkSize)
                val basePrompt = """
                You are a smart assistant. Summarize the provided meeting transcript clearly and concisely, identify key points, and generate a relevant title.

                Respond in JSON format:
                {
                  "title": "Brief meeting title",
                  "summary": "Summary paragraph (max 6 lines)",
                  "keypoints": ["Key point 1", "Key point 2", ...]
                }
            """.trimIndent()

                // Process chunks in parallel
                val partialSummaries = chunks.mapIndexed { index, chunk ->
                    CoroutineScope(Dispatchers.IO).async {
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
                                        put("content", "Part ${index + 1} of the meeting transcript:\n$chunk")
                                    })
                                })
                            }.toString().toRequestBody("application/json".toMediaType()))
                            .build()

                        networkHelper.executeWithRetry(
                            request = request,
                            onSuccess = { response ->
                                try {
                                    val content = JSONObject(response.body?.string() ?: "{}")
                                        .getJSONArray("choices")
                                        .getJSONObject(0)
                                        .getJSONObject("message")
                                        .getString("content")
                                    JSONObject(content)
                                } finally {
                                    response.close()
                                }
                            },
                            onFailure = { error -> throw Exception("Error summarizing part ${index + 1}: $error") }
                        )
                    }
                }.awaitAll()
                // Merge partial summaries
                val mergePrompt = """
                Combine these partial summaries into one coherent meeting summary (max 16 lines), consolidate keypoints (max 16), and generate a suitable title.

                Respond in JSON format:
                {
                  "title": "Final title",
                  "summary": "Merged summary paragraph (max 16 lines)",
                  "keypoints": ["Consolidated key point 1", "Consolidated key point 2", ...]
                }

                Partial Summaries:
                ${partialSummaries.joinToString("\n") { summary -> summary.toString() }}
            """.trimIndent()

                val mergeRequest = Request.Builder()
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

                networkHelper.executeWithRetry(
                    request = mergeRequest,
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
                            val keypoints = (0 until keypointsArray.length()).map { idx -> keypointsArray.getString(idx) }

                            dbHelper.insertOrUpdateSummary(
                                id = UUID.randomUUID().toString(),
                                title = finalTitle,
                                startTime = startTime,
                                endTime = LocalDateTime.now(),
                                actualTranscript = transcript,
                                summary = finalSummary,
                                keypoints = keypoints
                            )
                            onDone(finalTitle, finalSummary, keypoints)
                        } finally {
                            response.close()
                        }
                    },
                    onFailure = { error -> throw Exception("Error generating final summary: $error") }
                )

            } catch (e: Exception) {
                Log.e("OpenAIClient", "Error: ${e.message}")
                onError("Error: ${e.message}")
                dbHelper.insertOrUpdateSummary(
                    id = UUID.randomUUID().toString(),
                    title = "Not Summarized",
                    startTime = LocalDateTime.now(),
                    endTime = LocalDateTime.now(),
                    actualTranscript = transcript,
                    summary = "Failed summarizing: ${e.message}",
                    keypoints = emptyList()
                )
            }
        }

        // Timeout mechanism
        CoroutineScope(Dispatchers.IO).launch {
            delay(60000)
            if (job.isActive) {
                job.cancel()
                onError("Summary generation timed out")
                dbHelper.insertOrUpdateSummary(
                    id = UUID.randomUUID().toString(),
                    title = "Not Summarized",
                    startTime = LocalDateTime.now(),
                    endTime = LocalDateTime.now(),
                    actualTranscript = transcript,
                    summary = "Summary generation timed out",
                    keypoints = emptyList()
                )
            }
        }
    }
}