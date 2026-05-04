# Deen Azkar — Flutter

A complete Flutter rewrite of the **Deen Azkar (Daily Duas & Adhkar)** Android app, preserving all original functionality with improved animations, cleaner architecture, and Material 3 design.

---

## Features

| Feature | Details |
|---|---|
| 📖 Duas List | All 135+ duas from the original SQLite database |
| 🗂️ Categories Grid | 10 category tiles with background images (Illness, Prayer, Travel, etc.) |
| 🔍 Search | Real-time search of dua titles |
| ⭐ Bookmarks | Favorite individual duas, browse by bookmarked group |
| 🔊 Audio | Per-dua audio playback with seekbar (just_audio) |
| 🌙 Dark Mode | System / Light / Dark theme switching |
| 📏 Font Settings | Adjustable Arabic and translation font sizes |
| 💰 Zakat Calculator | Full calculator with currency selection |
| 🤝 Share | Share any dua via the system share sheet |
| 🎬 Animations | Button press scale animations throughout |
| 🚀 Splash / Onboarding | Animated splash + 3-page onboarding |

---

## Project Structure

```
lib/
├── main.dart                         # App entry point
├── core/
│   ├── database/
│   │   └── database_helper.dart      # SQLite (copies from assets on first run)
│   ├── models/
│   │   └── dua.dart                  # Dua data model
│   └── services/
│       ├── settings_service.dart     # SharedPreferences + ChangeNotifier
│       └── audio_service.dart        # just_audio wrapper (optional singleton)
├── features/
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   ├── home/
│   │   └── home_screen.dart          # AppDrawer + navigator shell
│   ├── dua_group/
│   │   ├── dua_group_screen.dart     # Grid/List toggle + search
│   │   └── filtered_dua_list_screen.dart
│   ├── categories/
│   │   └── category_grid_screen.dart # 2-column grid with category images
│   ├── dua_detail/
│   │   └── dua_detail_screen.dart    # Arabic + transliteration + audio + fav + share
│   ├── bookmarks/
│   │   └── bookmarks_group_screen.dart
│   ├── zakat/
│   │   └── zakat_calculator_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   └── about/
│       └── about_screen.dart
└── shared/
    └── theme/
        └── app_theme.dart            # Colors, typography, ThemeData
```

---

## Setup

### 1. Prerequisites
- Flutter SDK ≥ 3.0
- Dart SDK ≥ 3.0

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Copy original assets from the Java project

Copy these from the original Java project into the Flutter `assets/` folder:

| From Java project | To Flutter |
|---|---|
| `app/src/main/assets/hisnul.sqlite3` | `assets/db/hisnul.sqlite3` |
| `app/src/main/assets/img/*.png` | `assets/img/` |
| `app/src/main/assets/fonts_2/DroidNaskh.ttf` | `assets/fonts/DroidNaskh.ttf` |
| `app/src/main/assets/audio/a*.mp3` | `assets/audio/` |

> **Note:** The audio files (a1.mp3 – a135.mp3) are required for audio playback. The app will show a snackbar if an audio file is missing for a dua — it won't crash.

### 4. Android permissions (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### 5. Run
```bash
flutter run
```

---

## Key Architecture Decisions

- **State management:** `provider` + `ChangeNotifier` (matches the original's Observer pattern)
- **Database:** `sqflite` — database is bundled in assets and copied to the app's documents directory on first launch (same approach as the Java `ExternalDbOpenHelper`)
- **Audio:** `just_audio` — one `AudioPlayer` per dua card, stopped when another starts
- **Animations:** `AnimationController` with `ScaleTransition` on all interactive buttons — tap-down shrinks, tap-up bounces back
- **No ads:** Ad code removed; easy to re-add with `google_mobile_ads` if needed

---

## Mapping: Java → Flutter

| Java Class | Flutter File |
|---|---|
| `Splash.java` | `splash/splash_screen.dart` |
| `OnboardingActivity.java` | `onboarding/onboarding_screen.dart` |
| `DuaGroupActivity.java` | `dua_group/dua_group_screen.dart` |
| `FilteredDuaListActivity.java` | `dua_group/filtered_dua_list_screen.dart` |
| `DuaDetailActivity.java` | `dua_detail/dua_detail_screen.dart` |
| `BookmarksGroupActivity.java` | `bookmarks/bookmarks_group_screen.dart` |
| `BookmarksDetailActivity.java` | Merged into `dua_detail_screen.dart` (favoritesOnly flag) |
| `ZakatCalculatorActivity.java` | `zakat/zakat_calculator_screen.dart` |
| `PreferencesActivity.java` | `settings/settings_screen.dart` |
| `AboutActivity.java` | `about/about_screen.dart` |
| `CategoryGridAdapter.java` | `categories/category_grid_screen.dart` |
| `DuaGroupAdapter.java` | Widget in `dua_group_screen.dart` |
| `DuaDetailAdapter.java` | `_DuaDetailCard` widget in `dua_detail_screen.dart` |
| `ExternalDbOpenHelper.java` | `core/database/database_helper.dart` |
| `DuaGroupLoader.java` | `DatabaseHelper.getDuaGroups()` |
| `DuaDetailsLoader.java` | `DatabaseHelper.getDuaDetails()` |
| `Dua.java` | `core/models/dua.dart` |
