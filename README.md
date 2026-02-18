# StreakUp

A cross-platform habit tracking app built with Flutter. Track daily habits, maintain streaks, view statistics, and stay motivated with reminders and celebrations.

## Features

- **Habit Management** — Create, edit, and organize habits with custom categories, icons, colors, tags, and difficulty levels
- **Streak Tracking** — Current and best streak counters with streak freeze support (skip a day without breaking your streak)
- **Smart Reminders** — Per-habit reminders with pre-notifications and follow-up alerts, scheduled 3 weeks ahead for reliability
- **Calendar View** — Interactive monthly calendar showing daily completion status
- **Statistics & Insights** — Weekly breakdown, monthly completion percentage, and a 16-week heatmap
- **Cloud Sync** — Firebase Firestore sync for authenticated users with offline local storage fallback
- **Authentication** — Email/password and Google Sign-In
- **Dark/Light Mode** — Persistent theme toggle
- **Confetti Celebrations** — Animated confetti and sound effects on 100% daily completion
- **Habit Timer** — Built-in countdown timer with pause/resume per habit
- **Multi-Platform** — Android, iOS, Web, macOS, Windows, and Linux

## Screenshots

_Coming soon_

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | ChangeNotifier + ListenableBuilder |
| Auth | Firebase Auth, Google Sign-In |
| Database | Cloud Firestore (cloud), SharedPreferences (local) |
| Notifications | `alarm`, `flutter_local_notifications` |
| Audio | `audioplayers` with procedurally generated WAV effects |
| Styling | Material Design 3, Google Fonts (Poppins) |

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   └── habit.dart              # Core data model with streak calculation
├── services/
│   ├── auth_service.dart       # Firebase Auth & Google Sign-In
│   ├── firestore_service.dart  # Cloud Firestore sync
│   ├── habit_service.dart      # Business logic (ChangeNotifier)
│   ├── storage_service.dart    # SharedPreferences wrapper
│   ├── notification_service.dart # Alarms & reminders
│   ├── timer_service.dart      # Per-habit countdown timer
│   └── celebration_sound.dart  # Generated audio effects
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── dashboard_screen.dart   # Main shell with tab navigation
│   ├── add_habit_screen.dart   # Create/edit habits
│   ├── habit_detail_screen.dart
│   ├── alarm_screen.dart
│   ├── edit_profile_screen.dart
│   ├── notification_settings_screen.dart
│   ├── privacy_policy_screen.dart
│   └── tabs/
│       ├── home_tab.dart       # Habit list with search/filter
│       ├── calendar_tab.dart   # Monthly calendar
│       ├── statistics_tab.dart # Analytics & heatmap
│       └── profile_tab.dart    # Settings & profile
├── widgets/
│   ├── app_logo.dart
│   └── login_character.dart
└── theme/
    └── app_theme.dart          # Dark/Light theme definitions
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- Dart SDK (included with Flutter)
- Android Studio / Xcode (for mobile builds)
- A Firebase project (for auth and cloud sync)

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/streakup.git
cd streakup
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase configuration

The app uses Firebase for authentication and cloud sync. To connect your own Firebase project:

1. Create a project in the [Firebase Console](https://console.firebase.google.com/)
2. Enable **Authentication** (Email/Password and Google providers)
3. Create a **Cloud Firestore** database
4. Install the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) and run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` and platform-specific config files (`google-services.json`, `GoogleService-Info.plist`).

> **Desktop note:** Firebase is not fully supported on Linux and Windows. The app gracefully falls back to local-only storage on those platforms — no Firebase setup required.

### 4. Run the app

```bash
# Debug
flutter run

# Specify a device
flutter run -d chrome      # Web
flutter run -d linux        # Linux desktop
flutter run -d windows      # Windows desktop
flutter run -d macos        # macOS desktop
```

### 5. Build for release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Platform Support

| Platform | Firebase | Alarms & Notifications | Status |
|----------|----------|----------------------|--------|
| Android | Yes | Yes | Full support |
| iOS | Yes | Yes | Full support |
| Web | Yes | Limited | Functional |
| macOS | Fallback | No | Local storage only |
| Windows | Fallback | No | Local storage only |
| Linux | Fallback | No | Local storage only |

## App Icon

To regenerate app icons after modifying `assets/logo.png`:

```bash
dart run flutter_launcher_icons
```

## License

This project is proprietary. All rights reserved.
