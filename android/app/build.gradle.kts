plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ai_asistant"
    compileSdk = flutter.compileSdkVersion
//    aaptOptions {
//        // Remove Vosk-specific noCompress, as models are no longer needed
//        noCompress += listOf("pv") // For Porcupine model, if needed
//    }
    packaging {
        resources {
            pickFirsts.add("META-INF/INDEX.LIST")
            pickFirsts.add("META-INF/io.netty.versions.properties")
            pickFirsts.add("META-INF/DEPENDENCIES")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.ai_asistant"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Update to release signing later
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
//    implementation("com.google.cloud:google-cloud-speech:2.2.0")

    // gRPC and Protobuf (for manually managing stubs and streams)
//    implementation("io.grpc:grpc-okhttp:1.51.0")
//    implementation("io.grpc:grpc-protobuf:1.51.0")
//    implementation("io.grpc:grpc-stub:1.51.0")
//
//    // Protobuf Java
//    implementation("com.google.protobuf:protobuf-java:3.21.12")
//
//    // Authentication
//    implementation("com.google.auth:google-auth-library-oauth2-http:1.17.0")

    // Logging & JSON
//    implementation("com.assemblyai:assembly-ai-java:1.0.0")

    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("org.json:json:20231013")

    // Kotlin coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.1")

    // Porcupine for wake word detection
    implementation("ai.picovoice:porcupine-android:3.0.1")

    // Porcupine for hot word detection
}

flutter {
    source = "../.."
}