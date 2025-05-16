# Preserve Porcupine classes
-keep class ai.picovoice.** { *; }
-keep class com.picovoice.** { *; }
-dontwarn ai.picovoice.**
-keepclasseswithmembers class ai.picovoice.** {
    native <methods>;
}

# Preserve your client classes
-keep class com.example.sp_client.** { *; }