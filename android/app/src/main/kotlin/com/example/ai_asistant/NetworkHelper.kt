package com.example.openai

import android.util.Log
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import java.io.IOException

class NetworkHelper(
    private val client: OkHttpClient,
    private val apiKey: String,
    private val authToken: String
) {

    fun executeWithRetry(
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