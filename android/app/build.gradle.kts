plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

    android {
        namespace = "org.komal.bhagvadgeeta"
        compileSdk = flutter.compileSdkVersion
        ndkVersion = flutter.ndkVersion


        aaptOptions {
            noCompress.add("opus")
        }
        
            kotlin {
                jvmToolchain(17)
            }

        defaultConfig {
            // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
            applicationId = "org.komal.bhagvadgeeta"
            // You can update the following values to match your application needs.
            // For more information, see: https://flutter.dev/to/review-gradle-config.
            minSdk = flutter.minSdkVersion
            targetSdk = flutter.targetSdkVersion
            versionCode = flutter.versionCode
            versionName = flutter.versionName
        }

        bundle {
            // CHANGE THIS LINE
            assetPacks.addAll(mutableSetOf(
                ":Chapter1_audio", ":Chapter2_audio", ":Chapter3_audio",
                ":Chapter4_audio", ":Chapter5_audio", ":Chapter6_audio",
                ":Chapter7_audio", ":Chapter8_audio", ":Chapter9_audio",
                ":Chapter10_audio", ":Chapter11_audio", ":Chapter12_audio",
                ":Chapter13_audio", ":Chapter14_audio", ":Chapter15_audio",
                ":Chapter16_audio", ":Chapter17_audio", ":Chapter18_audio"
            ))
        }
    

        // The following code reads the properties from key.properties using Kotlin syntax

        signingConfigs {
            create("release") { // <-- This creates the 'release' config
                val keystorePropertiesFile = rootProject.file("key.properties")
                if (keystorePropertiesFile.exists()) {
                    val keystoreProperties = Properties()
                    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                    storeFile = file(keystoreProperties.getProperty("storeFile"))
                    storePassword = keystoreProperties.getProperty("storePassword")
                    keyPassword = keystoreProperties.getProperty("keyPassword")
                    keyAlias = keystoreProperties.getProperty("keyAlias")
                }
            }
        }

        buildTypes {
            release {
                // TODO: Add your own signing config for the release build.
                // Signing with the debug keys for now, so `flutter run --release` works.
                // This will now only succeed if the signingConfigs.release block was populated.
                // If key.properties is missing, the build will fail with a clear message
                // that the signing configuration is incomplete.
                signingConfig = signingConfigs.getByName("release")
                

                // BEGIN FIX FOR R8 ERROR
                // Enables code shrinking, obfuscation, and optimization for this build type.
                isMinifyEnabled = true
                // Enables the removal of unused resources. This works only when isMinifyEnabled is true.
                isShrinkResources = true
                // Specifies the ProGuard rules file.
                proguardFiles(
                    getDefaultProguardFile("proguard-android.txt"),
                    "proguard-rules.pro"
                )
                // END FIX FOR R8 ERROR
            }
        }
    }

    flutter {
        source = "../.."
    }

    dependencies {
        constraints {
            add("implementation", "org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.24")
            add("implementation", "org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.24")
            add("implementation", "org.jetbrains.kotlin:kotlin-stdlib:1.9.24")
        }
    }