// Location: mizan_monorepo/app_main/apps/android/build.gradle.kts

buildscript {
    // 1. Define Kotlin version
    val kotlin_version = "1.9.0" 

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // 2. Android Build Tools
        classpath("com.android.tools.build:gradle:8.1.0") // Updated to match recent Flutter versions
        
        // 3. Kotlin Gradle Plugin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")

        // 4. Google Services Plugin (CRITICAL FIX)
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}