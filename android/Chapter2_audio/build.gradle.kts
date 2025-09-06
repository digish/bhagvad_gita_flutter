// In android/Chapter2_audio/build.gradle.kts

plugins {
    id("com.android.asset-pack")
}

assetPack {
    packName.set("Chapter2_audio") // Make sure this matches the folder name
    dynamicDelivery {
        deliveryType.set("on-demand")
    }
}