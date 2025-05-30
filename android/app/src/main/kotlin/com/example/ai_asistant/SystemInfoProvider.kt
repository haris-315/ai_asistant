package com.example.openai

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.StatFs
import android.util.Log
import java.time.LocalDateTime

class SystemInfoProvider(private val context: Context) {

    fun getDeviceModel(): String {
        return "${Build.MANUFACTURER} ${Build.MODEL}"
    }

    fun getAvailableStorage(): String {
        try {
            val stat = StatFs(context.getExternalFilesDir(null)?.path)
            val bytesAvailable = stat.blockSizeLong * stat.availableBlocksLong
            val gigabytesAvailable = bytesAvailable / (1024.0 * 1024.0 * 1024.0)
            return String.format("%.2f GB", gigabytesAvailable)
        } catch (e: Exception) {
            Log.e("OpenAIClient", "Error getting available storage: ${e.message}")
            return "Unknown"
        }
    }

    fun getBatteryPercentage(): Int {
        val batteryStatus: Intent? = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level: Int = batteryStatus?.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale: Int = batteryStatus?.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, -1) ?: -1
        return if (level != -1 && scale != -1) {
            (level * 100) / scale
        } else {
            -1
        }
    }

    fun getCurrentTime(): String {
        return LocalDateTime.now().toString()
    }
}