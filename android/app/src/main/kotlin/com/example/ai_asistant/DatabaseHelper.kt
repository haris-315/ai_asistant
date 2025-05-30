package com.example.openai

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDateTime
import java.util.UUID

class DatabaseHelper(private val context: Context) {

    fun fetchUserData(): List<String> {
        val userData = mutableListOf<String>()
        var retryCount = 0
        val maxRetries = 3
        while (retryCount < maxRetries) {
            try {
                val dbPath = context.getDatabasePath("user_data.db").path
                val db = SQLiteDatabase.openOrCreateDatabase(dbPath, null)
                db.execSQL("""
                    CREATE TABLE IF NOT EXISTS user_data (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        data_point TEXT UNIQUE,
                        created_at TEXT
                    )
                """.trimIndent())
                val cursor = db.rawQuery("SELECT data_point FROM user_data ORDER BY created_at DESC LIMIT 24", null)
                while (cursor.moveToNext()) {
                    userData.add(cursor.getString(0))
                }
                cursor.close()
                db.close()
                return userData
            } catch (e: Exception) {
                retryCount++
                Log.e("OpenAIClient", "Error fetching user data (attempt $retryCount): ${e.message}")
                if (retryCount == maxRetries) {
                    Log.e("OpenAIClient", "Max retries reached for fetching user data")
                    return emptyList()
                }
                Thread.sleep(500)
            }
        }
        return emptyList()
    }

    fun collectUserData(args: JSONObject): JSONObject {
        val result = JSONObject()
        try {
            val dataPoints = args.getJSONArray("data_points")
            val dbPath = context.getDatabasePath("user_data.db").path
            val db = SQLiteDatabase.openOrCreateDatabase(dbPath, null)
            db.execSQL("""
                CREATE TABLE IF NOT EXISTS user_data (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    data_point TEXT UNIQUE,
                    created_at TEXT
                )
            """.trimIndent())

            val cursor = db.rawQuery("SELECT COUNT(*) FROM user_data", null)
            var currentCount = 0
            if (cursor.moveToFirst()) {
                currentCount = cursor.getInt(0)
            }
            cursor.close()

            val newPoints = mutableListOf<String>()
            for (i in 0 until dataPoints.length()) {
                if (currentCount >= 24) {
                    db.execSQL("DELETE FROM user_data WHERE id = (SELECT MIN(id) FROM user_data)")
                    currentCount--
                }
                val dataPoint = dataPoints.getString(i)
                val stmt = db.compileStatement("INSERT OR IGNORE INTO user_data (data_point, created_at) VALUES (?, ?)")
                stmt.bindString(1, dataPoint)
                stmt.bindString(2, LocalDateTime.now().toString())
                stmt.executeInsert()
                newPoints.add(dataPoint)
                currentCount++
            }
            db.close()
            Log.d("OpenAIClient", "Stored user data points: $newPoints")
            result.put("status", "success")
            result.put("data_points", JSONArray(newPoints))
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error storing user data: ${e.message}")
            result.put("error", "Error storing user data: ${e.message}")
        }
        return result
    }

    fun insertOrUpdateSummary(
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
}