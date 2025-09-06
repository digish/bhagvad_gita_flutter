pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

include(":Chapter1_audio")
include(":Chapter2_audio")
include(":Chapter3_audio")
include(":Chapter4_audio")
include(":Chapter5_audio")
include(":Chapter6_audio")
include(":Chapter7_audio")
include(":Chapter8_audio")
include(":Chapter9_audio")
include(":Chapter10_audio")
include(":Chapter11_audio")
include(":Chapter12_audio")
include(":Chapter13_audio")
include(":Chapter14_audio")
include(":Chapter15_audio")
include(":Chapter16_audio")
include(":Chapter17_audio")
include(":Chapter18_audio")
