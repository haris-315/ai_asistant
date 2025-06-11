package com.example.openai

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
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

    fun saveEmailReport(summary: String, hash: String) {
        var retryCount = 0
        val maxRetries = 3
        while (retryCount < maxRetries) {
            try {
                val dbPath = context.getDatabasePath("reports.db").path
                val db = SQLiteDatabase.openOrCreateDatabase(dbPath, null)

                db.execSQL("""
                CREATE TABLE IF NOT EXISTS reports (
                    day TEXT,
                    hash TEXT,
                    summary TEXT,
                    PRIMARY KEY (hash)
                )
            """.trimIndent())

                // Check total number of records
                val cursor = db.rawQuery("SELECT COUNT(*) FROM reports", null)
                var totalCount = 0
                if (cursor.moveToFirst()) {
                    totalCount = cursor.getInt(0)
                }
                cursor.close()

                // If total count >= 15, delete the oldest record
                if (totalCount >= 15) {
                    db.execSQL("""
                    DELETE FROM reports
                    WHERE day = (SELECT MIN(day) FROM reports)
                    LIMIT 1
                """.trimIndent())
                }

                // Insert or update the report
                val stmt = db.compileStatement("""
                INSERT OR REPLACE INTO reports (day, hash, summary)
                VALUES (?, ?, ?)
            """.trimIndent())
                stmt.bindString(1, LocalDate.now().toString())
                stmt.bindString(2, hash)
                stmt.bindString(3, summary)
                stmt.executeInsert()

                db.close()
                Log.d("OpenAIClient", "Report inserted/updated: $summary")
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
    fun getEmailReportByDay(day: String): String? {
        var retryCount = 0
        val maxRetries = 3
        while (retryCount < maxRetries) {
            try {
                val dbPath = context.getDatabasePath("reports.db").path
                val db = SQLiteDatabase.openOrCreateDatabase(dbPath, null)

                db.execSQL("""
                CREATE TABLE IF NOT EXISTS reports (
                    day TEXT,
                    hash TEXT,
                    summary TEXT,
                    PRIMARY KEY (hash)
                )
            """.trimIndent())

                val cursor = db.rawQuery("""
                SELECT summary FROM reports WHERE day = ?
            """.trimIndent(), arrayOf(day))

                var summary: String? = null
                if (cursor.moveToFirst()) {
                    summary = cursor.getString(0)
                }

                cursor.close()
                db.close()
                Log.d("OpenAIClient", "Report retrieved for day $day: $summary")
                return summary
            } catch (e: Exception) {
                retryCount++
                Log.e("OpenAIClient", "Error retrieving summary for day $day (attempt $retryCount): ${e.message}")
                if (retryCount == maxRetries) {
                    Log.e("OpenAIClient", "Max retries reached for summary retrieval")
                }
                Thread.sleep(500)
            }
        }
        return null
    }
}