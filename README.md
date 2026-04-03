# MX Media Player — Flutter

A full-featured media player app inspired by MX Player, built with Flutter/Dart.

---

## Features

- **Video Player** — Play MP4, MKV, AVI, MOV, WebM, and more
- **Audio Player** — Play MP3, AAC, FLAC, WAV, OGG, M4A with rotating vinyl UI
- **File Browser** — Auto-scan device storage for media files
- **File Picker** — Manually add files from anywhere on device
- **Playback Controls** — Play/Pause, Seek, Skip ±10s, Speed control (0.25x–2x)
- **Playlist** — Auto-advance through video/audio playlist
- **Repeat & Shuffle** — None / Repeat One / Repeat All + Shuffle
- **Volume Control** — In-player volume slider
- **Lock Screen** — Lock touch controls during playback
- **Search** — Search through all media files
- **Settings** — Auto-play, remember position, subtitle toggle, default speed
- **Dark Theme** — MX Player-style dark UI with orange accents

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── theme/
│   └── app_theme.dart               # Dark theme with orange accent
├── models/
│   └── media_file.dart              # Media file model
├── services/
│   └── media_scanner_service.dart   # Device storage scanner
└── screens/
    ├── home_screen.dart             # Main screen with tabs + search
    ├── video_list_screen.dart       # Video library list
    ├── video_player_screen.dart     # Full video player with controls
    ├── audio_list_screen.dart       # Audio library list
    ├── audio_player_screen.dart     # Audio player with vinyl UI
    └── settings_screen.dart        # App settings
```

---

## Setup

### 1. Install Flutter
https://docs.flutter.dev/get-started/install

### 2. Create a new Flutter project
```bash
flutter create mx_media_player
cd mx_media_player
```

### 3. Replace files
Copy all files from this project into your Flutter project:
- Replace `pubspec.yaml`
- Replace `lib/` directory entirely
- Replace `android/app/src/main/AndroidManifest.xml`

### 4. Install dependencies
```bash
flutter pub get
```

### 5. Run on Android device/emulator
```bash
flutter run
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `video_player` | Core video playback |
| `chewie` | Video player UI controls |
| `just_audio` | Audio playback with background support |
| `file_picker` | Pick files from device storage |
| `permission_handler` | Request storage permissions |
| `path` / `path_provider` | File path utilities |
| `shared_preferences` | Persist settings |

---

## Permissions (Android)

Required permissions are already set in `AndroidManifest.xml`:
- `READ_EXTERNAL_STORAGE` (Android ≤ 12)
- `READ_MEDIA_VIDEO` (Android 13+)
- `READ_MEDIA_AUDIO` (Android 13+)
- `FOREGROUND_SERVICE` (background audio)
- `WAKE_LOCK` (keep screen on during video)

---

## Known Limitations & Next Steps

- Subtitle (SRT/ASS) support can be added via `flutter_subtitle_wrapper`
- Hardware decoder selection (like real MX Player) needs platform channels
- Gesture-based brightness control needs `screen_brightness` package
- Background video pip requires `floating_window_android` plugin
- Cast/streaming support can be added with `flutter_cast_framework`

---

## Screenshots (UI Overview)

- **Home**: Orange-accented tab bar with Videos / Audio tabs
- **Video player**: Immersive landscape mode with gradient overlay controls
- **Audio player**: Dark screen with rotating vinyl disc, full playback controls

---

Built with ❤️ using Flutter
