package com.example.openai

import android.annotation.SuppressLint
import android.content.Intent
import android.location.Geocoder
import android.net.Uri
import android.provider.ContactsContract
import android.util.Log
import okhttp3.RequestBody.Companion.toRequestBody
import okio.IOException
import org.json.JSONArray
import org.json.JSONObject
import okhttp3.Request
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.Headers.Companion.toHeaders
import java.util.Locale

class FunctionDefinitionProvider(private val client: OpenAIClient) {

    interface FunctionDefinition {
        val name: String
        val description: String
        val parameters: JSONObject
        fun execute(args: JSONObject): JSONObject
    }

    private val functionDefinitions = listOf(



        object : FunctionDefinition {
            override val name = "get_weather"
            override val description = "Fetch current weather details for a specified location using the MET Norwegian Weather API."
            override val parameters = JSONObject().apply {
                put("type", "object")
                put("properties", JSONObject().apply {
                    put("location", JSONObject().apply {
                        put("type", "string")
                        put("description", "The name of the location (e.g., city, town) to fetch weather for")
                    })
                })
                put("required", JSONArray().apply { put("location") })
            }
            override fun execute(args: JSONObject): JSONObject {
                return getWeather(args)
            }
        },


        object : FunctionDefinition {
            override val name = "call_contact"
            override val description = "Initiate a phone call to a contact by name. If multiple contacts match, return their details for disambiguation."
            override val parameters = JSONObject().apply {
                put("type", "object")
                put("properties", JSONObject().apply {
                    put("contact_name", JSONObject().apply {
                        put("type", "string")
                        put("description", "The name of the contact to call")
                    })
                    put("contact_id", JSONObject().apply {
                        put("type", "string")
                        put("description", "The unique ID of the contact (used for disambiguation when provided)")
                    })
                })
                put("required", JSONArray().apply { put("contact_name") })
            }
            override fun execute(args: JSONObject): JSONObject {
                return callContact(args)
            }
        },


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
                        put("description", "Project ID (use id of the project named Inbox if no project is specified or the specified project is not available)")
                    })
                    put("due_date", JSONObject().apply { put("type", "string"); put("description", "Due date in ISO-8601 format (optional)") })
                    put("reminder_at", JSONObject().apply { put("type", "string"); put("description", "Reminder time in ISO-8601 format (optional)") })
                })
                put("required", JSONArray().apply { put("content"); put("description"); put("priority"); put("project_id") })
            }
            override fun execute(args: JSONObject): JSONObject {
                return createTask(args)
            }
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
            override fun execute(args: JSONObject): JSONObject {
                return updateTask(args)
            }
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
            override fun execute(args: JSONObject): JSONObject {
                return createProject(args)
            }
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
            override fun execute(args: JSONObject): JSONObject {
                return openApp(args)
            }
        },
        object : FunctionDefinition {
            override val name = "standby"
            override val description = "Enter standby mode."
            override val parameters = JSONObject().apply { put("type", "object"); put("properties", JSONObject()) }
            override fun execute(args: JSONObject): JSONObject {
                return JSONObject().apply { put("status", "standby") }
            }
        },
        object : FunctionDefinition {
            override val name = "summarize_conversation"
            override val description = "Summarize the conversation history."
            override val parameters = JSONObject().apply { put("type", "object"); put("properties", JSONObject()) }
            override fun execute(args: JSONObject): JSONObject {
                return JSONObject().apply { put("status", "summary_requested") }
            }
        },
        object : FunctionDefinition {
            override val name = "collect_user_data"
            override val description = "Collect and store user data from prompts for personalized responses, up to 24 points."
            override val parameters = JSONObject().apply {
                put("type", "object")
                put("properties", JSONObject().apply {
                    put("data_points", JSONObject().apply {
                        put("type", "array")
                        put("items", JSONObject().apply { put("type", "string"); put("description", "A concise data point (e.g., 'Name is John', 'Prefers dark mode')") })
                        put("description", "List of data points to store")
                    })
                })
                put("required", JSONArray().apply { put("data_points") })
            }
            override fun execute(args: JSONObject): JSONObject {
                return DatabaseHelper(client.context).collectUserData(args)
            }
        }
    )

    fun buildTools(): JSONArray {
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

    fun executeFunction(name: String, args: JSONObject): JSONObject {
        val functionDef = functionDefinitions.find { it.name == name }
        return functionDef?.execute(args) ?: JSONObject().apply {
            put("error", "Unknown function: $name")
        }
    }

    private fun getWeather(args: JSONObject): JSONObject {
        val result = JSONObject()
        try {
            val locationName = args.getString("location")
            val geocoder = Geocoder(client.context, Locale.getDefault())
            @Suppress("DEPRECATION")
            val addresses = geocoder.getFromLocationName(locationName, 1)
                ?: return JSONObject().apply { put("error", "Could not find coordinates for location: $locationName") }

            if (addresses.isEmpty()) {
                Log.w("OpenAIClient", "No coordinates found for location: $locationName")
                return JSONObject().apply { put("error", "No coordinates found for location: $locationName") }
            }

            val latitude = addresses[0].latitude
            val longitude = addresses[0].longitude

            val request = Request.Builder()
                .url("https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$latitude&lon=$longitude")
                .addHeader("User-Agent", "OpenAIClient/1.0 (contact: your-email@example.com)")
                .build()

            NetworkHelper(client.client, client.apiKey,client.authToken).executeWithRetry(
                request = request,
                onSuccess = { response ->
                    try {
                        if (response.isSuccessful) {
                            val responseBody = response.body?.string() ?: throw IOException("Empty response body")
                            val json = JSONObject(responseBody)
                            val timeseries = json.getJSONObject("properties").getJSONArray("timeseries")
                            val current = timeseries.getJSONObject(0).getJSONObject("data")
                            val instant = current.getJSONObject("instant").getJSONObject("details")
                            val temperature = instant.getDouble("air_temperature")
                            val condition = current.getJSONObject("next_1_hours")
                                .getJSONObject("summary")
                                .getString("symbol_code")

                            result.put("status", "success")
                            result.put("location", locationName)
                            result.put("temperature", temperature)
                            result.put("condition", condition)
                            Log.d("OpenAIClient", "Weather fetched for $locationName: $temperature°C, $condition")
                        } else {
                            val errorBody = response.body?.string() ?: "Unknown error"
                            Log.w("OpenAIClient", "Weather fetch failed: ${response.code}, $errorBody")
                            result.put("error", "Weather fetch failed: HTTP ${response.code}, $errorBody")
                        }
                    } catch (e: Exception) {
                        Log.e("OpenAIClient", "Error processing weather response: ${e.message}")
                        result.put("error", "Error processing weather response: ${e.message}")
                    } finally {
                        response.close()
                    }
                },
                onFailure = { error ->
                    Log.e("OpenAIClient", "Weather fetch failed: $error")
                    result.put("error", "Weather fetch failed: $error")
                }
            )
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error fetching weather: ${e.message}")
            result.put("error", "Error fetching weather: ${e.message}")
        }
        return result
    }
    private fun callContact(args: JSONObject): JSONObject {
        val result = JSONObject()
        try {
            val contactName = args.getString("contact_name")
            val contentResolver = client.context.contentResolver
            val cursor = contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                arrayOf(
                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                    ContactsContract.CommonDataKinds.Phone.NUMBER
                ),
                "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ?",
                arrayOf("%$contactName%"),
                null
            )

            val contacts = mutableListOf<JSONObject>()
            cursor?.use {
                while (it.moveToNext()) {
                    val contactId = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.CONTACT_ID))
                    val displayName = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME))
                    val phoneNumber = it.getString(it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER))
                    contacts.add(JSONObject().apply {
                        put("contact_id", contactId)
                        put("display_name", displayName)
                        put("phone_number", phoneNumber)
                    })
                }
            }

            when {
                contacts.isEmpty() -> {
                    Log.w("OpenAIClient", "No contacts found for name: $contactName")
                    result.put("error", "No contact found for name: $contactName")
                }
                contacts.size > 1 && !args.has("contact_id") -> {
                    Log.d("OpenAIClient", "Multiple contacts found for name: $contactName")
                    result.put("status", "multiple_contacts")
                    result.put("contacts", JSONArray(contacts))
                }
                else -> {
                    val contact = if (args.has("contact_id")) {
                        val contactId = args.getString("contact_id")
                        contacts.find { it.getString("contact_id") == contactId }
                            ?: throw IllegalArgumentException("Invalid contact ID: $contactId")
                    } else {
                        contacts[0]
                    }
                    val phoneNumber = contact.getString("phone_number")
                    val intent = Intent(Intent.ACTION_CALL).apply {
                        data = Uri.parse("tel:$phoneNumber")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    client.context.startActivity(intent)
                    Log.d("OpenAIClient", "Initiated call to: ${contact.getString("display_name")} ($phoneNumber)")
                    result.put("status", "success")
                    result.put("contact_name", contact.getString("display_name"))
                    result.put("phone_number", phoneNumber)
                }
            }
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error calling contact: ${e.message}")
            result.put("error", "Error calling contact: ${e.message}")
        }
        return result
    }

    private fun openApp(args: JSONObject): JSONObject {
        val result = JSONObject()
        try {
            val packageName = args.getString("package")
            val intent = client.context.packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                client.context.startActivity(intent)
                Log.d("OpenAIClient", "Opened app: $packageName")
                result.put("status", "success")
            } else {
                Log.w("OpenAIClient", "No launch intent for package: $packageName")
                result.put("error", "No launch intent for package: $packageName")
            }
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error opening app: ${e.message}")
            result.put("error", "Error opening app: ${e.message}")
        }
        return result
    }

    private fun createTask(args: JSONObject): JSONObject {
        val result = JSONObject()
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
                .url("${SharedData.baseUrl}todo/tasks/")
                .post(body)
                .addHeader("Authorization", "Bearer ${client.authToken}")
                .addHeader("Content-Type", "application/json")
                .build()

            NetworkHelper(client.client, client.apiKey, client.authToken).executeWithRetry(
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
                            result.put("status", "success")
                            result.put("task_id", taskId)
                        } else {
                            val errorBody = response.body?.string() ?: "Unknown error"
                            Log.w("OpenAIClient", "Task creation failed: ${response.code}, $errorBody")
                            result.put("error", "Task creation failed: HTTP ${response.code}, $errorBody")
                        }
                    } catch (e: Exception) {
                        Log.e("OpenAIClient", "Error processing task creation: ${e.message}")
                        result.put("error", "Error processing task creation: ${e.message}")
                    } finally {
                        response.close()
                    }
                },
                onFailure = { error ->
                    Log.e("OpenAIClient", "Task creation failed: $error")
                    result.put("error", "Task creation failed: $error")
                }
            )
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error creating task: ${e.message}")
            result.put("error", "Error creating task: ${e.message}")
        }
        return result
    }

    private fun updateTask(args: JSONObject): JSONObject {
        val result = JSONObject()
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
                .url("${SharedData.baseUrl}todo/tasks/$taskId")
                .put(body)
                .addHeader("Authorization", "Bearer ${client.authToken}")
                .addHeader("Content-Type", "application/json")
                .build()

            NetworkHelper(client.client, client.apiKey, client.authToken).executeWithRetry(
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
                            result.put("status", "success")
                        } else {
                            val errorBody = response.body?.string() ?: "Unknown error"
                            Log.w("OpenAIClient", "Task update failed: ${response.code}, $errorBody")
                            result.put("error", "Task update failed: HTTP ${response.code}, $errorBody")
                        }
                    } catch (e: Exception) {
                        Log.e("OpenAIClient", "Error processing task update: ${e.message}")
                        result.put("error", "Error processing task update: ${e.message}")
                    } finally {
                        response.close()
                    }
                },
                onFailure = { error ->
                    Log.e("OpenAIClient", "Task update failed: $error")
                    result.put("error", "Task update failed: $error")
                }
            )
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error updating task: ${e.message}")
            result.put("error", "Error updating task: ${e.message}")
        }
        return result
    }

    private fun createProject(args: JSONObject): JSONObject {
        val result = JSONObject()
        try {
            val projectBody = JSONObject().apply {
                put("name", args.getString("name"))
                put("color", args.getString("color"))
                put("is_favorite", args.getBoolean("is_favorite"))
                put("view_style", args.getString("view_style"))
            }
            val body = projectBody.toString().toRequestBody("application/json".toMediaType())
            val request = Request.Builder()
                .url("${SharedData.baseUrl}todo/projects/")
                .post(body)
                .addHeader("Authorization", "Bearer ${client.authToken}")
                .addHeader("Content-Type", "application/json")
                .build()

            NetworkHelper(client.client, client.apiKey, client.authToken).executeWithRetry(
                request = request,
                onSuccess = { response ->
                    try {
                        if (response.isSuccessful) {
                            val projectName = projectBody.getString("name")
                            client.projects.add(projectName)
                            Log.d("OpenAIClient", "Project created: $projectName")
                            result.put("status", "success")
                        } else {
                            val errorBody = response.body?.string() ?: "Unknown error"
                            Log.w("OpenAIClient", "Project creation failed: ${response.code}, $errorBody")
                            result.put("error", "Project creation failed: HTTP ${response.code}, $errorBody")
                        }
                    } catch (e: Exception) {
                        Log.e("OpenAIClient", "Error processing project creation: ${e.message}")
                        result.put("error", "Error processing project creation: ${e.message}")
                    } finally {
                        response.close()
                    }
                },
                onFailure = { error ->
                    Log.e("OpenAIClient", "Project creation failed: $error")
                    result.put("error", "Project creation failed: $error")
                }
            )
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error creating project: ${e.message}")
            result.put("error", "Error creating project: ${e.message}")
        }
        return result
    }
}