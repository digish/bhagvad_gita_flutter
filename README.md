# Shrimad Bhagavad Gita - A Flutter Application

A beautiful, modern, and open-source Flutter app for reading the Shrimad Bhagavad Gita on Android, iOS, and the Web.

*(Consider adding a GIF or screenshot of the app here)*

## ✨ Key Features

### 🔍 Unmatched Search Capabilities
*   **Deep Search:** Instantly find what you are looking for. Search within the **Shloka** itself, **Anvay**, **Tika**, or deep **Commentaries**.
*   **Multi-Script Support:** Search effortlessly using **English**, **Hindi**, or **Sanskrit** keywords.
*   **Contextual Understanding:** Find exactly where specific concepts (like *Karma*, *Yoga*, *Anger*) are discussed across the entire scripture.

### 📖 Immersive Reading Experience
*   **Versatile Reading Modes:** Choose how you want to read:
    *   **Chapter by Chapter:** Classic navigation.
    *   **Parayan Mode:** Distraction-free continuous recital mode.
    *   **Book-Like Mode:** Read commentaries and translations just like a physical book.
*   **Focus & Comfort:** Clutter-Free interface with adjustable font sizes and beautiful **Dark and Light themes**.
*   **Multi-Language Scripts:** View Shlokas in **Devanagari (Sanskrit/Hindi)**, **Gujarati**, and **English**.

### 🎧 Perfect Recitation & Audio
*   **Authentic Chanting:** Listen to pristine Sanskrit Shloka audio to perfect your pronunciation.
*   **Background Playback:** Continue listening while using other apps or with the screen off.
*   **Smart Playback:** Use **Single Repeat** for memorizing specific verses or **Back-to-Back** mode for continuous listening.

### 📜 Master Commentaries
*   Go beyond simple translations. Access in-depth commentaries from renowned sages:
    *   **Adi Shankaracharya**
    *   **Ramanujacharya**
    *   **Swami Sivananda**
    *   ...and many more.

### 🛠️ Powerful Study Tools
*   **Custom Lists & Bookmarks:** Create your own "Study Sets" or "Recitation Lists".
*   **Curated Wisdom:** Access predefined lists of Shlokas for specific life situations (e.g., *Anger*, *Peace*, *Motivation*).
*   **Daily Inspiration:** Start your day with a beautiful **Daily Shloka** card.
*   **Share the Wisdom:** Easily share Shloka text and Audio with friends and family.
*   **100% Free & Ad-Free:** Focus purely on your spiritual journey.

## 🚀 Getting Started

1.  **Clone the repo:**
    ```sh
    git clone https://github.com/digish/bhagvad_gita_flutter.git
    ```
2.  **Install dependencies:**
    ```sh
    cd bhagvad_gita_flutter
    flutter pub get
    ```
3.  **Run the app:**
    ```sh
    flutter run
    ```

## 🛠️ Tech Stack

-   **Framework:** Flutter
-   **Database:** sqflite (Mobile) & sqflite_common_ffi_web (Web)
-   **Audio:** just_audio & just_audio_background
-   **Asset Delivery:** asset_delivery for on-demand audio downloads.

## 📜 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Ads Configuration

This app uses Google AdMob for rewarded ads.

### Setup

1.  **AdMob Account**: Create apps for Android/iOS in AdMob.
2.  **Ad Units**: Create a "Rewarded Ad" unit for each platform.
3.  **App IDs**:
    -   Update `android/app/src/main/AndroidManifest.xml`
    -   Update `ios/Runner/Info.plist`
4.  **Ad Unit IDs**:
    -   Update `lib/services/ad_service.dart` with production IDs.

## Google Analytics (Firebase)

The app logs screen views, feature usage, settings/config changes, outbound links, search, Ask Gita, audio, shares, bookmarks, ads, and deep links via Firebase Analytics.

Firebase is configured for project **bhagvad-geeta-2a708**:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Dart: `lib/firebase_options.dart` (`isConfigured = true`)

Events appear in Firebase **Analytics → DebugView** (debug builds) and **Events** (after processing).

To refresh configs after changing apps in the Firebase console, replace those two native files and update `lib/firebase_options.dart` (or run `flutterfire configure`).
