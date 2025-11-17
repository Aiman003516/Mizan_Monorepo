// In: mizan_monorepo/app_main/apps/android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-plugin-loader")
    // DO NOT APPLY google-services here. Move it to the end.
    // id("com.google.gms.google-services") 
}

fun localProperties(): java.util.Properties {
    val properties = java.util.Properties()
    val localPropertiesFile = project.rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        properties.load(java.io.FileInputStream(localPropertiesFile))
    }
    return properties
}

val flutterRoot: String by project
val flutterVersionCode: String? by project
val flutterVersionName: String? by project

// === FIX STEP 1: Add this line ===
// Load .env file for build-time variables
project.ext.set("flutter.dotenv", ".env")

// === FIX STEP 2: Apply flutter.gradle AFTER .env line ===
apply(from = "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle")

android {
    namespace = "com.example.mizan.mizan"
    compileSdk = 34 // flutter.compileSdkVersion
    ndkVersion = "26.1.10909125" // flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin", "src/main/java")
        }
    }

    defaultConfig {
        applicationId = "com.example.mizan.mizan"
        minSdk = 21 // flutter.minSdkVersion
        targetSdk = 34 // flutter.targetSdkVersion
        versionCode = (flutterVersionCode ?: "1").toInt()
        versionName = flutterVersionName ?: "1.0"
    }

    buildTypes {
        release {
            isSigningReady = true
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {}

// === FIX STEP 3: Apply google-services at the VERY END ===
apply(plugin = "com.google.gms.google-services")