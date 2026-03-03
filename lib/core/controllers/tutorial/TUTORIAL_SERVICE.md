# TutorialService

A lightweight, scalable first-launch tutorial overlay system for Flutter.  
Tutorials are shown once per screen, persisted via `SharedPreferences`, and displayed as full-screen overlay hints using Flutter's native `Overlay` API — no widget tree modifications required.

---

## Quick Start

Add `shared_preferences` to your `pubspec.yaml` if not already present:

```yaml
dependencies:
  shared_preferences: ^2.3.0
```

---

## Usage

### Showing a tutorial from `initState`

Call the screen-specific method inside `initState` wrapped in `addPostFrameCallback` so the overlay inserts after the screen is fully laid out:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    TutorialService.showHomeScreenHelp();
  });
}
```

The tutorial will only appear if the user has not seen it before. On subsequent launches, the call is a silent no-op.

---

### Force showing a tutorial (e.g. from a "Show Tips" button in Settings)

```dart
await TutorialService.forceShow(TutorialKey.homeScreen);
```

Ignores the seen flag entirely — always shows.

---

### Resetting a single tutorial

```dart
await TutorialService.reset(TutorialKey.chatScreen);
```

Clears the seen flag for one screen. Next time the screen is visited, the tutorial will show again.

---

### Resetting all tutorials

```dart
await TutorialService.resetAll();
```

Useful for a "Replay all tips" option in Settings or during development.

---

### Checking if a tutorial has been seen

```dart
final seen = await TutorialService.hasSeen(TutorialKey.homeScreen);
if (!seen) {
  // do something else first
}
```

---

### Dismissing the active tutorial imperatively

```dart
TutorialService.dismiss();
```

Call this in `dispose()` if you want to guarantee cleanup when a screen is removed:

```dart
@override
void dispose() {
  TutorialService.dismiss();
  super.dispose();
}
```

---

### Adding a new tutorial

Three steps:

**1. Add a key to `TutorialKey`:**
```dart
enum TutorialKey {
  homeScreen,
  chatScreen,
  folderScreen, // ← new
}
```

**2. Add a config to `_tutorials`:**
```dart
TutorialKey.folderScreen: TutorialConfig(
  message: 'Long press a note\nto add it to a folder',
  anchor: TutorialAnchor.bottomLeft,
  dismissHint: 'Tap anywhere to dismiss',
),
```

**3. Add a public method to `TutorialService`:**
```dart
static Future<void> showFolderScreenHelp() =>
    _showIfUnseen(TutorialKey.folderScreen);
```

Then call it from the screen's `initState`:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  TutorialService.showFolderScreenHelp();
});
```

---

## Overall Flow

```
Screen initState
       │
       ▼
TutorialService.showXxxHelp()
       │
       ▼
_showIfUnseen(TutorialKey)
       │
       ├─── SharedPreferences.getBool('tutorial_seen_xxx')
       │              │
       │         ┌────┴────┐
       │       true       false
       │         │           │
       │       return      _show(key)
       │       (no-op)       │
       │                     ▼
       │           lookup _tutorials[key]
       │                     │
       │                     ▼
       │         navigatorKey.currentState?.overlay
       │                     │
       │                     ▼
       │           OverlayEntry(_TutorialOverlay)
       │                     │
       │          addPostFrameCallback → insert
       │                     │
       │                     ▼
       │            Overlay renders on screen
       │            (fade in 350ms, full screen,
       │             12% black, hint bubble + arrow)
       │                     │
       │              user taps anywhere
       │                     │
       │                     ▼
       │            _handleDismiss()
       │                     │
       │            fade out → onDismiss()
       │                     │
       │         ┌───────────┴────────────┐
       │         ▼                        ▼
       │   _activeEntry.remove()   SharedPreferences
       │   _activeEntry = null     .setBool('tutorial_seen_xxx', true)
       │
       └─── tutorial will never show again for this key
```

---

## `TutorialKey` — Enum Registry

| Value | Screen | SharedPreferences Key |
|---|---|---|
| `homeScreen` | `Homescreen` | `tutorial_seen_homeScreen` |
| `chatScreen` | `ChatScreen` | `tutorial_seen_chatScreen` |
| `searchScreen` | `SearchScreen` | `tutorial_seen_searchScreen` |
| `settingsScreen` | `SettingsScreen` | `tutorial_seen_settingsScreen` |
| `profileScreen` | `ProfileScreen` | `tutorial_seen_profileScreen` |

---

## `TutorialAnchor` — Enum Values

Controls where the hint bubble and arrow appear on screen.

| Value | Position | Arrow Direction | Typical Use |
|---|---|---|---|
| `bottomRight` | Bottom-right, 90px from bottom | Points down | FAB button |
| `bottomLeft` | Bottom-left, 90px from bottom | Points down | Bottom-left actions |
| `bottomCenter` | Bottom-center, 90px from bottom | Points down | Bottom nav items |
| `topRight` | Top-right, 80px from top | Points up | Top-right actions |
| `topLeft` | Top-left, 80px from top | Points up | Back/leading buttons |
| `topCenter` | Top-center, 80px from top | Points up | Search bars, app bars |
| `center` | Centered on screen | Points up | General info, modals |

---

## `TutorialConfig` — Properties

| Property | Type | Required | Default | Description |
|---|---|---|---|---|
| `message` | `String` | ✅ | — | Main instruction text shown in the hint bubble |
| `anchor` | `TutorialAnchor` | ✅ | — | Controls bubble position and arrow direction |
| `dismissHint` | `String?` | ❌ | `'Tap anywhere to dismiss'` | Secondary hint shown at top center. Pass `null` to hide |

---

## `TutorialService` — Public Methods

| Method | Returns | Description |
|---|---|---|
| `showHomeScreenHelp()` | `Future<void>` | Shows homescreen tutorial if unseen |
| `showChatScreenHelp()` | `Future<void>` | Shows chat screen tutorial if unseen |
| `showSearchScreenHelp()` | `Future<void>` | Shows search screen tutorial if unseen |
| `showSettingsScreenHelp()` | `Future<void>` | Shows settings screen tutorial if unseen |
| `showProfileScreenHelp()` | `Future<void>` | Shows profile screen tutorial if unseen |
| `forceShow(TutorialKey)` | `Future<void>` | Shows tutorial regardless of seen flag |
| `hasSeen(TutorialKey)` | `Future<bool>` | Returns whether the tutorial has been seen |
| `reset(TutorialKey)` | `Future<void>` | Clears seen flag for a single tutorial |
| `resetAll()` | `Future<void>` | Clears seen flags for all tutorials |
| `dismiss()` | `void` | Removes the active overlay immediately |

---

## `TutorialService` — Internal Members

| Member | Type | Description |
|---|---|---|
| `_prefix` | `String` const | SharedPreferences key prefix — `'tutorial_seen_'` |
| `_activeEntry` | `OverlayEntry?` | Reference to the currently visible overlay entry |
| `_showIfUnseen(key)` | `Future<void>` | Checks seen flag then calls `_show` |
| `_show(key)` | `Future<void>` | Builds and inserts the `OverlayEntry` |
| `_markSeen(key)` | `Future<void>` | Writes `true` to SharedPreferences for the given key |
| `_prefKey(key)` | `String` | Generates the full SharedPreferences key string |

---

## `_tutorials` Map — Definition Location

The `_tutorials` constant at the top of `tutorial_service.dart` is the single source of truth for all tutorial content. It maps every `TutorialKey` to a `TutorialConfig`:

```dart
const Map<TutorialKey, TutorialConfig> _tutorials = {
  TutorialKey.homeScreen: TutorialConfig(
    message: 'Tap here to create\na new note',
    anchor: TutorialAnchor.bottomRight,
  ),
  // ... one entry per TutorialKey
};
```

An `assert` at runtime will warn immediately if a `TutorialKey` exists without a corresponding entry in this map.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `shared_preferences` | `^2.3.0` | Persisting seen flags across app launches |
| `flutter/material.dart` | SDK | `OverlayEntry`, animations, widgets |
| `global_keys.dart` | internal | `navigatorKey` for overlay access without `BuildContext` |

---

## Notes

- `TutorialService` is a **static-only utility class** — it cannot be instantiated.
- Only **one tutorial can be active at a time**. Calling any show method while another is visible will dismiss the current one first.
- The overlay is inserted via `navigatorKey.currentState?.overlay` so it floats above all screens without modifying any widget tree.
- The fade-in duration is `350ms` with `Curves.easeOut`. Fade-out triggers on tap, then `onDismiss` fires after the animation completes.
- `HitTestBehavior.opaque` on the `GestureDetector` ensures taps register across the entire screen, including transparent areas.
