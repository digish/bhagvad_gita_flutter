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

### Firebase Exploration recipes

In **Analytics → Explore**, create free-form explorations (register custom dimensions for event parameters when prompted):

| Question | Event / dimension | Notes |
|----------|-------------------|--------|
| Which screens are used most? | `screen_view` → screen name | e.g. `search`, `chapters`, `parayan`, `bookmarks`, `ask_gita`, `credits` |
| Theme preference | User property `theme_mode` | `system`, `light`, `dark` |
| Home layout preference | User property `home_ui_mode` | `full`, `simple`, `minimal` |
| Ask Gita usage | `ask_gita` (count / users); funnel with `feature_used` `ask_gita_screen` | Question text is not logged |
| Search volume & terms | `search` → `search_term`, `result_count` | One event per debounced query |
| Popular chapters | `chapter_open` → `chapter_number`, `read_mode` | Numeric chapter routes only |
| Book mode in chapter | `config_change` where `setting_name` = `book_reading_mode` | Toggle inside chapter list |
| Audio by surface | `audio_play` → `playback_context` | `parayan`, `chapter_list`, `chapter_book`, `bookmark_list`, `shloka_card` |
| Shares | `share` → `content_type` | `shloka_text`, `shloka_audio`, `image`, `list`, `app`, `ask_gita_answer` |
| Credits & GitHub | `screen_view` `credits`; `link_open` with `link_source` = `credits` and host `github.com` | |
| Bookmark funnel | `screen_view` `bookmarks`; `feature_used` `bookmark_add_sheet`, `bookmark_list_detail`; `bookmark_action` → `action` | |
| User consistency (not on-device streak) | **Retention** (Day 1 / 7 / 28), engaged sessions, sessions per user | Streak counts stay on-device per privacy policy |
