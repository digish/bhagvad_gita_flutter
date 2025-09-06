// In android/Chapter5_audio/build.gradle.kts

plugins {
    id("com.android.asset-pack")
}

assetPack {
    packName.set("Chapter5_audio") // Make sure this matches the folder name
    dynamicDelivery {
        deliveryType.set("on-demand")
    }
}