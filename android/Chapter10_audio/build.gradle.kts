// In android/Chapter10_audio/build.gradle.kts

plugins {
    id("com.android.asset-pack")
}

assetPack {
    packName.set("Chapter10_audio") // Make sure this matches the folder name
    dynamicDelivery {
        deliveryType.set("on-demand")
    }
}