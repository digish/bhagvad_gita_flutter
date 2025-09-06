// In android/Chapter12_audio/build.gradle.kts

plugins {
    id("com.android.asset-pack")
}

assetPack {
    packName.set("Chapter12_audio") // Make sure this matches the folder name
    dynamicDelivery {
        deliveryType.set("on-demand")
    }
}