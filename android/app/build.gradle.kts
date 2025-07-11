plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.oneplayer"
    compileSdk = 35 // 明确指定SDK版本

    // 移除ndkVersion，让Gradle使用默认版本
    // ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.oneplayer"
        minSdk = 21 // 提高最低SDK版本
        targetSdk = 35 // 明确指定目标SDK版本
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // 启用MultiDex
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true // 重新启用代码混淆
            isShrinkResources = true // 启用资源压缩
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packagingOptions {
        // 解决原生库冲突
        resources.pickFirsts.add("lib/x86/libVLC.so")
        resources.pickFirsts.add("lib/x86_64/libVLC.so")
        resources.pickFirsts.add("lib/armeabi-v7a/libVLC.so")
        resources.pickFirsts.add("lib/arm64-v8a/libVLC.so")
        resources.pickFirsts.add("lib/**/libc++_shared.so")
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 根据需要添加依赖
}
