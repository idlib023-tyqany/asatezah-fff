plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // يجب تطبيق Flutter Plugin بعد Android و Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.asatezah.asatezah"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.asatezah.asatezah"
        minSdk = 21 // حدم أدنى لضمان توافق المكتبات
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}