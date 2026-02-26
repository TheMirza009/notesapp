<div align="center">

<img src="assets/launcher/app_logo_transparent.png" alt="NotesApp Logo" width="120"/>

# NotesApp
### Chat-style notes. Offline. Private. Powerful.

[![Flutter](https://img.shields.io/badge/Flutter-3.41.2-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-brightgreen?style=for-the-badge)](/)
[![Play Store](https://img.shields.io/badge/Google_Play-4.9★_100+_Downloads-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.azdhaar.notesapp)
[![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-red?style=for-the-badge)](/)

> *"Tired of cluttering your WhatsApp self-chat? So was I. So I built this."*
> — Mirza AbdulMoeed

</div>

---

## 🧠 What is NotesApp?

**NotesApp** reimagines note-taking through the most intuitive interface humans already know — **a messaging app.**

Instead of a blank page staring back at you, every note lives inside a **chat thread** — visual, scrollable, timestamped, and instantly familiar. It's the self-chat experience you've been hacking together on WhatsApp, but built properly from the ground up.

No accounts. No cloud. No subscriptions. **Your data stays on your device. Period.**

---

## ✨ Features

### 📝 Core Experience
- **Chat-style note interface** — every note is a thread, every entry is a message
- **Custom note avatars** — personalize each notebook with a photo
- **Pin important notebooks** — keep what matters at the top
- **Full-text search** — search across all notes and message content instantly
- **Smart filters** — sort and filter your notebook list your way
- **Markdown-style text formatting** — bold, italic, and more via `typeset`

### 📎 Rich Media Support
| Type | Details |
|------|---------|
| 📷 **Photos** | Pick from gallery, capture with camera, paste from clipboard |
| 🎥 **Videos** | Attach and preview video clips inline |
| 🎙️ **Voice Notes** | Record audio with live waveform visualization |
| 📄 **Documents** | PDFs, Word files, spreadsheets, and more |
| 🧵 **Threads** | Twitter/X-style threaded notes within a note |
| 🖼️ **GIFs** | Animated image support |

### 🎨 Personalization
- **Per-note wallpapers** — set a custom background per notebook
- **Bubble style customization** — choose your message bubble aesthetic
- **Full dark & light theme** — system-aware with manual override
- **Custom profile avatar** with crop support

### 🔍 Search & Organization
- **Global message search** — find any note entry across all notebooks
- **In-chat search** — search within a specific notebook
- **Filter & sort** — by date, pinned, media type, and more

### 🖥️ Multi-Platform
- **Android** — full feature set, stable release
- **Windows** — alpha, custom native titlebar with `bitsdojo_window`

### 🔒 Privacy First
- **100% offline** — zero network calls, zero telemetry
- **No account required** — open the app and start noting
- **Local Isar database** — typed, fast, and entirely on-device

---

## 📸 Screenshots

<div align="center">

| Home | Chat View | Media Picker |
|------|-----------|--------------|
| ![Home Screen](screenshots/home.png) | ![Chat View](screenshots/chat.png) | ![Media Picker](screenshots/picker.png) |

| Rich Media | Media Gallery |
|------------|---------------|
| ![Rich Media](screenshots/rich_media.png) | ![Media Gallery](screenshots/gallery.png) |

</div>

> 🎬 *Video demo coming soon*

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter | `3.41.2+` |
| Dart | `3.7+` |
| Android SDK | `21+` |

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/TheMirza009/notesapp.git
cd notesapp

# 2. Install dependencies
flutter pub get

# 3. Generate Isar schema files
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

### Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# Windows
flutter build windows --release
```

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **UI Framework** | ![Flutter](https://img.shields.io/badge/-Flutter-02569B?logo=flutter&logoColor=white) | Cross-platform UI |
| **Language** | ![Dart](https://img.shields.io/badge/-Dart-0175C2?logo=dart&logoColor=white) | Application logic |
| **State Management** | [Riverpod 3.x](https://riverpod.dev) | Reactive state, per-feature notifiers |
| **Local Database** | [Isar Community](https://isar.dev) | Typed, high-performance local persistence |
| **Media** | `image_picker`, `file_picker`, `camera` | Media capture and selection |
| **Audio** | `just_audio`, `record`, `siri_wave` | Playback, recording, waveform |
| **Video** | `video_player`, `video_thumbnail` | Inline video support |
| **Windows** | `bitsdojo_window` | Native Windows titlebar |
| **Sharing** | `receive_sharing_intent`, `share_plus` | Inter-app share integration |
| **Image Processing** | `croppy`, `extended_image`, `blurhash_dart` | Crop, cache, blur placeholders |

---

## 🏗️ Architecture

NotesApp follows an **MVVM-inspired architecture** using Riverpod as the ViewModel layer.

```
lib/
├── main.dart                     # App entry point
├── core/
│   ├── controllers/              # App-wide services (Isar, Theme, Media)
│   ├── extensions/               # Dart extensions
│   ├── Theme/                    # Design tokens, gradients, constants
│   └── utils/                    # Helpers, global keys, constants
│
└── root/
    ├── data/
    │   ├── models/               # Isar models + generated .g.dart files
    │   └── enums/                # App-wide enums
    │
    └── screens/                  # Feature screens
        ├── Homescreen/           # Notebook list + search
        ├── Chat_screen/          # Chat view + notifier + state
        ├── Chat_Detail/          # Media detail viewer
        ├── Chat_Forward/         # Forward messages between notebooks
        ├── Profile/              # User settings & avatar
        ├── Settings/             # App preferences
        └── Camera/               # In-app camera
```

**Key architectural decisions:**
- Each screen owns its **Riverpod notifier**, **state class**, and **widget subtree**
- `IsarDatabase` acts as a centralized data service accessed by notifiers
- `core/` is entirely feature-agnostic — no screen imports
- Platform-specific logic (`WindowsUtils`, titlebar theming) isolated in utilities

---

## 📦 Download

<div align="center">

[![Get it on Google Play](https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png)](https://play.google.com/store/apps/details?id=com.azdhaar.notesapp)

**4.9 ★ Rating &nbsp;·&nbsp; 100+ Downloads &nbsp;·&nbsp; Android 5.0+**

</div>

---

## 🗺️ Roadmap

### 🔜 In Progress
- [ ] Video message support
- [ ] Undoable chat deletes
- [ ] Pinnable chat tiles
- [ ] Reply Anchor system UI compliance

### 📋 Planned
- [ ] Cloud sync (optional, opt-in)
- [ ] Message delivery indicators
- [ ] Multi-select bulk actions
- [ ] Audio record overlay with waveform UI
- [ ] Windows — full feature parity

### 💭 Exploring
- [ ] End-to-end encrypted cloud backup
- [ ] Widget support (Android home screen)
- [ ] iPad / tablet layout

---

## 👤 Author

**Mirza AbdulMoeed**

[![GitHub](https://img.shields.io/badge/GitHub-TheMirza009-181717?style=for-the-badge&logo=github)](https://github.com/TheMirza009)
[![Play Store](https://img.shields.io/badge/Play_Store-NotesApp-414141?style=for-the-badge&logo=google-play)](https://play.google.com/store/apps/details?id=com.azdhaar.notesapp)

---

## ⚖️ License

```
Copyright © 2025 Mirza AbdulMoeed. All rights reserved.

This source code is made available for viewing and portfolio purposes only.
Unauthorized copying, forking, redistribution, or commercial use of this
codebase, in whole or in part, is strictly prohibited without explicit
written permission from the author.
```

---

<div align="center">

**Built with 💙 in Flutter &nbsp;·&nbsp; Designed for the notes you actually use**

*If you find this project interesting, consider leaving a ⭐ on GitHub*

</div>