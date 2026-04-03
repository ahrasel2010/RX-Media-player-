plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mx_media_player"
    compileSdk = 36  // ← এটি 36 রাখুন

    defaultConfig {
    applicationId = "com.your_company.media_player"  // পরিবর্তন করো
    minSdk = flutter.minSdkVersion
    targetSdk = 36
    versionCode = 1
    versionName = "1.0"
}


    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }

        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/proguard/androidx-*.pro",
                "META-INF/DEPENDENCIES"
            )
        }
    }

    lint {
        disable += setOf("MissingDimensionRegistration")
    }
}

flutter {
    source = "../.."
}
