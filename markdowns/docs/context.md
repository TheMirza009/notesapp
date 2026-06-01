# NotesApp — Technical Context (Source of Truth)

> **Version:** 2.1.1+6 · **Last Updated:** 2026-04-27
> **Audience:** AI agents performing bug fixes, feature development, and refactoring.
> **Rule:** Read this file in full before modifying any source code.

---

## 1. Project Identity

| Key | Value |
|---|---|
| **Name** | NotesApp |
| **Package** | `com.azdhaar.notesapp` |
| **Purpose** | Offline, privacy-first note-taking app styled as a self-chat messenger |
| **Platforms** | Android (stable), Windows (alpha via `bitsdojo_window`) |
| **Architecture** | MVVM-inspired with Riverpod `StateNotifier` / `Notifier` |
| **Persistence** | Isar NoSQL (community fork `isar_community`) |
| **State Mgmt** | `flutter_riverpod` |
| **Min SDK** | Flutter 3.x, Dart 3.x |

### Core Philosophy
- **100% offline** — no cloud, no analytics, no network calls (link preview feature must be opt-in if added).
- **Privacy-first** — all data stays on-device.
- **Self-chat paradigm** — every note is a "message" inside a "chat thread". No multi-user concepts.
- **Clean Monolith** — widgets stay inline unless used ≥3 times across ≥3 files (see `markdowns/clean_monolith.md`).
- **Simplicity-first** — no over-engineering, no premature abstractions (see `markdowns/claude.md`).

---

## 2. Directory Structure

```
notesapp/
├── android/                          # Android platform files
├── windows/                          # Windows platform files (alpha)
├── markdowns/
│   ├── claude.md                     # AI agent behavioral rules
│   ├── clean_monolith.md             # Widget extraction rules
│   ├── NotesApp_Feature_Requests.docx # Backlog (bugs + features)
│   └── context.md                    # ← THIS FILE
├── lib/
│   ├── main.dart                     # App entry point
│   ├── core/                         # Feature-agnostic services
│   │   ├── Theme/
│   │   │   ├── theme_constants.dart  # Color palette (light + dark)
│   │   │   └── gradients.dart        # Background gradients
│   │   ├── controllers/
│   │   │   ├── isar_database.dart    # Singleton DB controller
│   │   │   ├── media_handler.dart    # Image/doc/audio pick+save
│   │   │   ├── media_handler_video_extensions.dart  # Video pick+save
│   │   │   ├── video_handler.dart    # Video metadata + thumbnails
│   │   │   ├── blurhash_service.dart # BlurHash encode/decode cache
│   │   │   ├── recording_handler.dart # Audio recording
│   │   │   ├── share_intent_handler.dart # Android share-to-app
│   │   │   ├── theme_provider.dart   # ThemeNotifier (light/dark)
│   │   │   └── backup/
│   │   │       └── backup_service.dart # Export/import .notesbackup
│   │   ├── extensions/
│   │   │   ├── chat_extensions.dart    # Chat → last message helpers
│   │   │   ├── media_extensions.dart   # Media type checks, list helpers
│   │   │   ├── message_extensions.dart # Message type checks, display text
│   │   │   ├── context_extensions.dart # BuildContext → theme/size shortcuts
│   │   │   ├── string_extensions.dart  # Thread JSON codec, URL wrapping
│   │   │   └── widget_extensions.dart  # Keyboard shortcut builder
│   │   └── utils/
│   │       ├── utils.dart            # Snackbar, clipboard, share, navigation
│   │       ├── global_keys.dart      # ScaffoldMessenger, Navigator, titlebar keys
│   │       ├── constants.dart        # Version, email, Play Store URL
│   │       ├── time_format.dart      # Date/time formatting helpers
│   │       └── transitions.dart      # Slide-from-left/right page routes
│   └── root/                         # Feature-specific domain + UI
│       ├── data/
│       │   ├── models/
│       │   │   ├── chat_model.dart        # Chat entity
│       │   │   ├── message_model.dart     # Message entity
│       │   │   ├── media_model.dart       # Media entity + VideoMetadata
│       │   │   ├── settings_model.dart    # Global settings entity
│       │   │   ├── user_model.dart        # User profile entity
│       │   │   └── folder_model.dart      # Folder grouping entity
│       │   ├── enums/
│       │   │   ├── media_type.dart        # Mediatype enum
│       │   │   ├── bubble_style.dart      # BubbleStyle enum
│       │   │   └── bubble_color.dart      # BubbleColor enum
│       │   └── chat_list_provider/
│       │       ├── chat_list_notifier.dart # Master chat list state
│       │       ├── chat_list_state.dart    # ChatListState model
│       │       └── extensions/
│       │           └── chatlist_folder_extension.dart
│       └── presentation/
│           ├── screens/
│           │   ├── Homescreen/           # Chat list / home
│           │   │   ├── homescreen.dart
│           │   │   ├── components/
│           │   │   │   ├── chat_list/    # Chat tile widgets
│           │   │   │   └── main/         # AppBar, FAB, etc.
│           │   │   └── platform/
│           │   │       └── desktop/      # Windows-specific layout
│           │   ├── Chat_screen/          # Message view
│           │   │   ├── chat_screen.dart
│           │   │   ├── notifier/
│           │   │   │   ├── chat_state.dart          # Immutable ChatState
│           │   │   │   └── chat_state_notifier.dart  # ChatStateNotifier (1778 LOC)
│           │   │   ├── bodies/
│           │   │   │   └── chat_screen_glass_body.dart
│           │   │   └── widgets/
│           │   │       ├── components/
│           │   │       │   ├── message_bubble/       # Bubble rendering
│           │   │       │   │   ├── message_bubble.dart
│           │   │       │   │   ├── message_content_builder.dart
│           │   │       │   │   ├── content/          # Media-specific content
│           │   │       │   │   └── helpers/           # Swipeable, colors, shapes
│           │   │       │   ├── bottom_message_bar.dart
│           │   │       │   ├── chat_appbar.dart
│           │   │       │   ├── attachment_board.dart
│           │   │       │   ├── reply_anchor.dart
│           │   │       │   ├── reply_wrapper.dart
│           │   │       │   ├── date_chip.dart
│           │   │       │   ├── emoji_board.dart
│           │   │       │   ├── auto_hide_scroll_to_bottom.dart
│           │   │       │   └── recording/            # Voice recording UI
│           │   │       └── wrappers/
│           │   │           ├── message_list_wrapper.dart
│           │   │           ├── bottom_message_bar_wrapper.dart
│           │   │           ├── chat_appbar_wrapper.dart
│           │   │           ├── chat_searchbar.dart
│           │   │           ├── anchor_wrapper.dart
│           │   │           ├── emoji_board_wrapper.dart
│           │   │           ├── emerging_overlay.dart
│           │   │           ├── attachment/
│           │   │           │   └── overlay_controller.dart
│           │   │           └── overlays/
│           │   │               └── overlay_handler.dart
│           │   ├── Chat_Detail/          # Chat info / media gallery
│           │   │   ├── chat_detail_screen.dart
│           │   │   ├── screens/
│           │   │   │   ├── chat_detail_screen_divided.dart
│           │   │   │   └── chat_media_screen.dart
│           │   │   └── widgets/
│           │   │       └── info_bottom_sheet.dart
│           │   ├── Chat_Forward/         # Forward message to another chat
│           │   │   └── chat_forward_screen.dart
│           │   ├── Settings/
│           │   │   ├── settings_screen.dart
│           │   │   └── notifier/
│           │   │       └── settings_notifier.dart
│           │   ├── Backup/
│           │   │   ├── backup_screen.dart
│           │   │   └── backup_notifier.dart
│           │   ├── Camera/
│           │   │   └── camera_screen.dart
│           │   └── Profile/
│           │       └── profile_screen.dart
│           └── widgets/                  # Shared reusable widgets
│               ├── photo_view/
│               │   ├── gallery_view_wrapper.dart
│               │   ├── media_preview_modal.dart
│               │   ├── media_preview_screen.dart
│               │   ├── photo_view_wrapper.dart
│               │   ├── croppy_custom_cropper.dart
│               │   ├── croppy_example.dart
│               │   └── croppy_settings_modal.dart
│               ├── voice_message/
│               │   └── components/       # Audio waveform + player
│               └── custom_icon_dialogue.dart
```

---

## 3. Data Models (Isar Entities)

All models live in `lib/root/data/models/`. Generated `.g.dart` files are gitignored and regenerated via:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3.1 Chat (`chat_model.dart`)

| Field | Type | Notes |
|---|---|---|
| `isarID` | `Id` (auto) | Isar primary key |
| `id` | `String` | UUID v7 identifier |
| `name` | `String` | Chat title |
| `emoji` | `String?` | Optional emoji avatar |
| `isPinned` | `bool` | Pin to top of list |
| `createdAt` | `DateTime` | Creation timestamp |
| `messages` | `IsarLinks<Message>` | One-to-many link |
| `folder` | `IsarLink<Folder>` | Optional folder grouping |

**Key relationships:**
- `Chat` → `Message`: One-to-many via `IsarLinks`.
- `Chat` → `Folder`: Many-to-one via `IsarLink`.

### 3.2 Message (`message_model.dart`)

| Field | Type | Notes |
|---|---|---|
| `isarId` | `Id` (auto) | Isar primary key |
| `id` | `String` | UUID v7 identifier |
| `text` | `String` | Message content (may contain `§url§` wrapped links or JSON thread array) |
| `time` | `DateTime` | Timestamp |
| `isSender` | `bool` | `true` = right-aligned bubble, `false` = left-aligned |
| `media` | `IsarLink<Media>` | Optional attached media |
| `replyingTo` | `IsarLink<Message>` | Optional reply reference |
| `chat` | Backlink | Reverse link to parent Chat |

**Critical:** `Message.copyWith()` exists for immutable state updates. The `text` field stores raw markdown (rendered by `typeset` package) and URL sentinels (`§url§`).

**Init message:** New chats contain one message with `id = "0000"` and text `"This is a new chat. Start typing to create your first note."` — this is auto-deleted on first real message send.

### 3.3 Media (`media_model.dart`)

| Field | Type | Notes |
|---|---|---|
| `isarId` | `Id` (auto) | Isar primary key |
| `name` | `String?` | Display name / thread JSON |
| `path` | `String?` | Absolute file path on device |
| `extension` | `String?` | File extension |
| `type` | `Mediatype` | Enum: image, video, audio, document, thread, text |
| `aspectRatio` | `double?` | For images/videos |
| `blurHash` | `String?` | BlurHash placeholder string |
| `duration` | `String?` | For audio/video |
| `thumbnailPath` | `String?` | Video thumbnail path |
| `messagesBacklink` | Backlink | Reverse link to Messages |

**Named constructors:** `Media.thread(json)`, `Media.fromVideoPath(path, metadata)`.
**`VideoMetadata`** (plain class, not Isar): holds `videoPath`, `thumbnailPath`, `blurHash`, `aspectRatio`, `duration`, `fileSize`, `fileName`, `fileExtension`.

### 3.4 Settings (`settings_model.dart`)

| Field | Type | Notes |
|---|---|---|
| `id` | `Id` | Always `0` (singleton) |
| `isLightMode` | `bool` | Theme preference |
| `chatDisplayAscending` | `bool` | Message sort order |
| `selectedBubbleStyle` | `BubbleStyle` | Enum stored as index |

**Methods:** `copyWith()`, `setBubbleStyle()`, `setChatOrder()`, `toggleChatDisplayOrder()`, `toggleTheme()`.
**Singleton pattern:** Only one Settings object exists at `id = 0`.

### 3.5 User (`user_model.dart`)
Stores user profile (name, avatar path). Not heavily used in current version.

### 3.6 Folder (`folder_model.dart`)
Groups chats into folders. `IsarLinks<Chat>` back-reference.

---

## 4. Enums

### `Mediatype` (`media_type.dart`)
```dart
enum Mediatype { image, video, audio, document, thread, text }
```

### `BubbleStyle` (`bubble_style.dart`)
```dart
enum BubbleStyle { normal, glass, opaque }
```

### `BubbleColor` (`bubble_color.dart`)
```dart
enum BubbleColor { seed, blue, green, purple, orange, red, pink }
```

---

## 5. Core Services (`lib/core/controllers/`)

### 5.1 IsarDatabase (`isar_database.dart`)

**Singleton** — initialized once in `main.dart` via `IsarDatabase.initialize()`.

| Method | Purpose |
|---|---|
| `initialize()` | Opens Isar with all schemas, sets static `isar` reference |
| `getChats()` | Returns all chats sorted by creation date |
| `getChatMessages(chatId)` | Loads messages for a chat with media preloaded |
| `deleteMessage(msg)` | Deletes message + media link cleanup |
| `deleteChat(chat)` | Deletes chat + all linked messages + media files |
| `deleteAllChats()` | Nuclear delete — all chats, messages, media |
| `createChat(name, emoji)` | Creates chat with init message |
| `updateChat(chat)` | Persists chat field changes |

**Schemas registered:** `ChatSchema`, `MessageSchema`, `MediaSchema`, `SettingsSchema`, `UserSchema`, `FolderSchema`.

### 5.2 MediaHandler (`media_handler.dart`)

**Static utility class** — no state. Handles pick → process → save → return `Media` object.

| Method | Purpose |
|---|---|
| `pickImage(source)` | Pick from gallery/camera → crop → generate blurhash → save to app dir → return `Media` |
| `fromImageBytes(bytes)` | Convert raw bytes to saved image `Media` |
| `pickDocument(fileType)` | Pick file via `FilePicker` → copy to app dir → return `Media` |
| `saveAudio(path)` | Copy recording to app dir → return `Media` |
| `deleteMedia(media)` | Delete file + thumbnail from disk |

**Storage paths:** `{appDocDir}/Media/Images/`, `Media/Videos/`, `Media/Documents/`, `Media/Audio/`, `Media/Thumbnails/`.

### 5.3 MediaHandlerVideoExtensions (`media_handler_video_extensions.dart`)

Extends `MediaHandler` with video-specific workflows:

| Method | Purpose |
|---|---|
| `pickVideo()` | Full pipeline: pick → save → generate metadata → return `Media` |
| `previewVideo()` | Pick only (no save/metadata) for preview modal |
| `saveVideo(path)` | Save + generate metadata from a known path |
| `pickVideoFast(onMetadataReady)` | Save immediately, metadata in background callback |
| `pickVideoHybrid(onFullMetadataReady)` | Minimal metadata sync, full metadata async |

### 5.4 BlurHashService (`blurhash_service.dart`)

**Caching decode service.** Uses `compute()` isolates for 60fps performance.

| Method | Purpose |
|---|---|
| `batchDecode(entries)` | Pre-decode list of `(hash, aspectRatio)` pairs into cache |
| `getCachedImage(hash)` | Return cached decoded `ui.Image` or `null` |

### 5.5 ThemeProvider (`theme_provider.dart`)

`ThemeNotifier extends StateNotifier<ThemeMode>`. Manages light/dark toggle. 
**Known bug:** Does not persist `isLightMode` back to Isar Settings — see Feature Requests bug #16.

### 5.6 BackupService (`backup/backup_service.dart`)

**Static class.** Exports/imports `.notesbackup` ZIP files containing:
- `chats.json`, `messages.json`, `media.json`, `settings.json`
- All media files in `Media/` subfolder
- Progress callback: `onProgress(double, String)`
- Custom exceptions: `BackupException`, `BackupCancelledException`, `InvalidBackupException`

### 5.7 ShareIntentHandler (`share_intent_handler.dart`)

Handles Android share-to-app via platform channels. Delegates to `MediaHandler` for processing, navigates to `ChatForwardScreen` for target selection.

### 5.8 RecordingHandler (`recording_handler.dart`)

`Recorder` class wrapping the `record` package. Methods: `startRecording()`, `stopRecording()`, `cancelRecording()`.

---

## 6. Extensions (`lib/core/extensions/`)

### `ChatX` on `Chat` (`chat_extensions.dart`)
- `loadLastMessageTextFormatted()` → formatted subtitle for chat tile
- `loadLastMessage()` / `loadLastMessageFull()` / `loadLastMessageTime()` → direct Isar queries

### `MessageX` on `Message` (`message_extensions.dart`)
- `isImage`, `isAudio`, `isVideo`, `isDocument`, `isThread` → type checks via media link
- `getMessageDisplayText` → returns emoji-prefixed label (`📷 Photo`, `📽️ Video`, etc.)

### `MediaX` on `Media` (`media_extensions.dart`)
- `messageTime`, `timeString` → timestamp from backlink
- `isImage`, `isVideo`, `isDocument`, `isAudio` → type checks

### `MediaHelpers` on `List<Media>` (`media_extensions.dart`)
- `validImages` → filtered list of image-type media with valid paths
- `indexOfMediaIsarID(message)` → find media index by message link

### `StringCaseX` on `String` (`string_extensions.dart`)
- `toSentenceCase()` → capitalize first letter
- `safeDecode()` → JSON decode to `List<String>` for thread messages (with fallback)
- `formatThread()` → human-readable thread rendering
- `getThreadLength()` → thread count

### `LinkWrapper` on `String` (`string_extensions.dart`)
- `withWrappedLinks` → wraps URLs in `§url§` delimiters for clickable rendering
- `unwrappedLink` → replaces `§url§` with `🔗 url` for display
- **Critical:** The `§` character is an internal sentinel. Must be stripped before clipboard/share operations.

### `ThemeX` on `BuildContext` (`context_extensions.dart`)
- `isLight`, `isDark`, `screenSize`, `screenWidth`, `screenHeight`

### `KeyboardShortcutsX` on `Widget` (`widget_extensions.dart`)
- `.withKeys(onEscape, onEnter, onSave, ...)` → declarative keyboard shortcut binding (Windows support)

---

## 7. Utils (`lib/core/utils/`)

### `Utils` (`utils.dart`)
| Method | Purpose |
|---|---|
| `showGlobalSnackBar(text, color)` | App-wide snackbar via `scaffoldMessengerKey` |
| `copyTextToClipboard(text)` | Copy + snackbar feedback |
| `copyImageFromPath(path)` | Copy image bytes to clipboard via `pasteboard` |
| `shareToApps(XFile)` / `shareText(text)` | System share sheet |
| `smoothNavigate(context, child)` | Fade+scale page transition |
| `formatDuration(duration)` | `HH:MM:SS` or `MM:SS` |
| `getObjectSize/Position(key)` | RenderBox measurement helpers |
| `getBubbleColorScheme(context, style, color)` | Resolve bubble colors by style |

### `TimeFormat` (`time_format.dart`)
| Method | Purpose |
|---|---|
| `formatChatTime(time)` | Smart: "3:45 PM" / "12 Sep" / "Sep 2024" |
| `formatChatDateChip(date)` | "Today" / "Yesterday" / weekday / full date |
| `formatChatSubtitle(lastEdited)` | "today at 3:45 PM" / "yesterday" / date |
| `imageTime(dateTime)` | "Today, 02:45 PM" / "13 September, 02:45 PM" |

### `Transitions` (`transitions.dart`)
- `slideFromLeftRoute<T>(page)` → left-slide (profile drawer)
- `slideFromRightRoute<T>(page)` → right-slide (Cupertino-style)
- Uses parallax depth effect on secondary animation.

### Global Keys (`global_keys.dart`)
```dart
final scaffoldMessengerkey = GlobalKey<ScaffoldMessengerState>();
final navigatorKey = GlobalKey<NavigatorState>();
final windowsTitleBarColor = ValueNotifier<Color?>(null);
```

### Constants (`constants.dart`)
```dart
static const String version = "2.1.1+6";
static const String supportEmail = "azdhaarsoftware@gmail.com";
static const String playStoreURL = "https://play.google.com/store/apps/details?id=com.azdhaar.notesapp";
```

---

## 8. State Management — Riverpod Providers

All state is managed through Riverpod. **Never create a new state management mechanism** — extend existing notifiers.

### 8.1 Provider Registry

| Provider | Type | Class | File |
|---|---|---|---|
| `chatListProvider` | `NotifierProvider` | `ChatListNotifier` | `chat_list_notifier.dart` |
| `chatStateController` | `NotifierProvider` | `ChatStateNotifier` | `chat_state_notifier.dart` |
| `settingsController` | `StateNotifierProvider` | `SettingsNotifier` | `settings_notifier.dart` |
| `backupProvider` | `StateNotifierProvider` | `BackupNotifier` | `backup_notifier.dart` |
| `overlayHandlerProvider` | (varies) | `OverlayHandler` | `overlay_handler.dart` |
| `overlayControllerProvider` | (varies) | `OverlayController` | `overlay_controller.dart` |

### 8.2 ChatListNotifier (`chat_list_notifier.dart` — 602 LOC)

**Purpose:** Master controller for the homescreen chat list.

**State:** `ChatListState` containing:
```dart
class ChatListState {
  final List<Chat> chats;           // All chats
  final List<Chat> filteredChats;   // Search-filtered subset
  final Chat? selectedChat;         // Currently open chat
  final Message? messageToHighlight;// Cross-screen highlight target
  final List<Message> searchResults;// Global search results
  final bool isSearching;
  final String searchQuery;
}
```

**Key methods:**

| Method | Purpose |
|---|---|
| `loadChats()` | Hydrate from Isar, sorted by last message time |
| `selectChat(chat)` | Set `selectedChat`, triggers `ChatStateNotifier.build()` |
| `createChat(name, emoji)` | Create via `IsarDatabase.createChat()`, add to state |
| `removeChat(chat)` | Immediate removal from state + Isar |
| `deleteChatWithUndo(chat, context)` | Soft-delete → SnackBar with Undo → hard-delete after timeout |
| `deleteAllChats()` | Nuclear delete with confirmation |
| `searchChats(query)` | Filter `chats` by name/last-message text |
| `togglePin(chat)` | Toggle `isPinned`, re-sort |
| `renameChat(chat, name)` | Update name in Isar + state |
| `globalSearch(query)` | Search across all messages in all chats |
| `clearHighlight()` | Reset `messageToHighlight` |

**Pending Delete Pattern:**
```
deleteChatWithUndo(chat) →
  1. Remove from UI state immediately
  2. Store in _PendingDelete map (chatId → timer)
  3. Show SnackBar with "Undo" action
  4. On Undo: cancel timer, restore to UI state
  5. On timeout (5s): commit hard-delete via IsarDatabase.deleteChat()
```

### 8.3 ChatStateNotifier (`chat_state_notifier.dart` — 1778 LOC)

**Purpose:** Controller for the active chat screen — messages, selection, editing, recording, threading.

**State:** `ChatState` (immutable, `copyWith`-based):
```dart
class ChatState {
  final List<Message> messages;
  final bool isSearching, showEmojis, isLoading, isRecording, isEditing, isThreading;
  final Message? anchorMessage;         // Reply target
  final Message? highlightedMessage;    // Temporarily highlighted
  final Message? cancelledThread;       // Thread being cancelled (animation)
  final Message? activeEditingThread;   // Thread being edited
  final BubbleColor? bubbleColor;
  final List<Message> selectedMessages; // Multi-select
  final List<String> activeThreadStrings; // Thread entries being composed
  bool get isSelecting => selectedMessages.isNotEmpty;
}
```

**Controllers (non-state, stored as fields):**
```dart
TextEditingController searchController;
TypeSetEditingController keyboardController;  // Markdown-aware input
FocusNode searchFocusNode, keyboardFocusNode;
ItemScrollController itemScrollController;    // scrollable_positioned_list
ItemPositionsListener itemPositionsListener;
Recorder recorder;
Chat? _chat;  // Current chat reference
List<Message> allMessages;  // Authoritative in-memory list
```

**`build()` lifecycle:**
1. Watches `chatListProvider.select((s) => s.selectedChat)`.
2. If `selectedChat` changes → sets `_chat`, calls `hydrateMessages()`.
3. Watches `messageToHighlight` for cross-screen scroll targets.
4. Sets up keyboard auto-scroll via `_setupKeyboardAutoScroll()`.

**Message CRUD — centralized DB helpers:**

| Helper | Purpose |
|---|---|
| `_persistMedia(media)` | `writeTxn` → `medias.put` → return managed instance |
| `_createAndAttachMessage(message, media?, replyTo?)` | Single txn: save message, link media, link to chat, link reply |
| `_deleteMessageManaged(message)` | Single txn: delete message, unlink from chat, return media ref |
| `_isMediaUsedByOthers(path, excludingId?)` | Check if other messages share the same media file |

**Message operations using helpers:**

| Method | Flow |
|---|---|
| `sendMessage(text)` | Delete init msg → create Message → `_createAndAttachMessage` → update state → scroll |
| `pickImage(bytes?, isCamera?, media?)` | Pick/process → `showPreview()` modal → `_persistMedia` → `_createAndAttachMessage` |
| `pickVideo(isCamera?, media?)` | Preview → save → metadata → `_persistMedia` → `_createAndAttachMessage` |
| `pickVideoFast()` | Save immediately → metadata in background callback |
| `pickDocument()` | `MediaHandler.pickDocument()` → `_persistMedia` → `_createAndAttachMessage` |
| `pickAudio()` | Same pattern as pickDocument with `FileType.audio` |
| `stopAudioRecording()` | `recorder.stopRecording()` → `MediaHandler.saveAudio()` → persist → attach |
| `deleteMessage(msg)` | Remove from UI immediately → background: `_deleteMessageManaged` → file cleanup |
| `deleteSelected()` | Batch delete in single txn → media cleanup in background |
| `editTextMessage(msg, newText)` | Update in Isar → reload managed instance → update `allMessages` |
| `forwardMessage(original, targetChat)` | Clone message + media → persist in targetChat → update UI if same chat |
| `updateMessage(msg)` | Simple put in Isar + update state |

**Message hydration (progressive loading):**
```
hydrateMessages() →
  1. Query all message IDs for current chat, sorted by time
  2. If descending mode: load ALL at once
  3. If ascending mode: load first 20 visible, then background-load rest in batches of 50
  4. Pre-decode all blurhashes via BlurHashService.batchDecode()
  5. Background batches use _loadRemainingMessagesInBatches() with scroll-position preservation
```

**Selection & highlight:**

| Method | Purpose |
|---|---|
| `selectMessage(msg)` | Add to `selectedMessages` |
| `unselectMessage(msg)` | Remove from `selectedMessages` |
| `unSelectAllMessages()` | Clear selection (skipped if `isEditing`) |
| `selectAllMessages()` | Select all messages |
| `highlightMessageTemporarily(msg)` | Set highlight → auto-clear after 700ms |

**Chat bar / emoji / anchor:**

| Method | Purpose |
|---|---|
| `setAnchorMessage(msg, ctx)` | Set reply target, show reply overlay |
| `clearAnchorMessage()` | Clear reply, unfocus keyboard |
| `toggleEmojiPicker()` | Show/hide emoji board (mutually exclusive with keyboard) |
| `toggleSearch()` / `searchChats(query)` / `clearSearch()` | In-chat message search |

**Recording:**

| Method | Purpose |
|---|---|
| `startAudioRecording()` | `recorder.startRecording()`, set `isRecording` |
| `cancelAudioRecording()` | Hide overlay, cancel recording |
| `stopAudioRecording()` | Stop → save → persist → create message |

**Threading (multi-note threads stored as JSON array in `message.text`):**

| Method | Purpose |
|---|---|
| `createThread()` | Create new message with `Media.thread(json)`, set `isThreading` |
| `onTyping(text)` | Live-update last thread entry in JSON + persist to Isar |
| `addThread(text)` | Append new entry to thread JSON array |
| `removeLastThread()` | Pop last entry; cancel thread if only placeholder remains |
| `saveThread()` | Persist final JSON, clear threading state, highlight |
| `cancelThread()` | Delete thread message, clear state |
| `editThread(msg)` | Load existing thread JSON, enter threading mode |

**Context menu handling:**

| Action | Handler |
|---|---|
| `deleteMessage` | `deleteMessage(msg)` |
| `edit` | Thread → `editThread()`, Text → `startEditingTextMessage()` |
| `reply` | Show anchor overlay → `setAnchorMessage()` |
| `forward` | Navigate to `ChatForwardScreen` |
| `copy` | Image → `copyImageFromPath`, Thread → formatted text, Text → raw text |
| `toggleSender` | Flip `isSender` boolean |
| `share` | Thread → `shareText(formatted)`, Media → `shareToApps(XFile)` |

**Chat screen options:** `chatInfo`, `chatMedia`, `search`, `clearChat` (with dialog).

### 8.4 SettingsNotifier (`settings_notifier.dart`)

**Purpose:** Manages singleton Settings object.

| Method | Purpose |
|---|---|
| `_loadSettings()` | Load from Isar id=0, create default if missing |
| `update(settings)` | Persist to Isar, update state |
| `setBubbleStyle(style)` | Update bubble style |
| `setChatOrder(ascending)` | Set chat display order |
| `toggleChatOrder()` | Toggle ascending/descending |

**Note:** No `toggleTheme()` method exists — this is a known gap (bug #16).

### 8.5 BackupNotifier (`backup_notifier.dart`)

**State:** `BackupState` with `BackupStatus` enum (`idle`, `inProgress`, `completed`, `error`, `cancelled`).

| Method | Purpose |
|---|---|
| `startExport()` | `BackupService.exportBackup()` with progress callbacks |
| `startImport(ref)` | `BackupService.importBackup()` with progress callbacks |
| `reset()` | Return to idle (blocked during operations) |

---

## 9. UI Architecture

### 9.1 Screen → Notifier Mapping

| Screen | Notifier | Provider |
|---|---|---|
| `homescreen.dart` | `ChatListNotifier` | `chatListProvider` |
| `chat_screen.dart` | `ChatStateNotifier` | `chatStateController` |
| `settings_screen.dart` | `SettingsNotifier` | `settingsController` |
| `backup_screen.dart` | `BackupNotifier` | `backupProvider` |
| `profile_screen.dart` | (direct Isar) | N/A |

### 9.2 Chat Screen Widget Hierarchy

```
ChatScreen (ConsumerStatefulWidget)
├── ChatAppbarWrapper → ChatAppbar
│   ├── Normal mode: title + options menu
│   └── Selection mode: count + delete/forward/copy actions
├── ChatSearchbar (conditional)
├── MessageListWrapper → ScrollablePositionedList
│   ├── DateChip (group separator)
│   └── MessageBubble
│       ├── ReplyWrapper (if replying to another message)
│       ├── MessageContentBuilder
│       │   ├── Text content (TypeSet rendered)
│       │   ├── Image content (with BlurHash placeholder)
│       │   ├── Video content (thumbnail + play icon)
│       │   ├── Audio content (waveform + player)
│       │   ├── Document content (file icon + name)
│       │   └── Thread content (multi-entry card)
│       └── Swipeable (gesture for reply)
├── AnchorWrapper → ReplyAnchor (conditional, when replying)
├── BottomMessageBarWrapper → BottomMessageBar
│   ├── TypeSetEditingController (markdown input)
│   ├── Emoji toggle
│   ├── Attachment button → AttachmentBoard overlay
│   ├── Send button / Record button
│   └── Thread controls (add/save/cancel when threading)
├── EmojiBoard (conditional)
└── AutoHideScrollToBottom (FAB)
```

### 9.3 Component vs Wrapper Pattern

- **Components** (`widgets/components/`): Pure UI widgets. Receive data via constructor. Minimal logic.
- **Wrappers** (`widgets/wrappers/`): `ConsumerWidget`s that read from providers and pass data to components. Handle overlay/animation orchestration.

### 9.4 Overlay System

The chat screen uses a centralized overlay system:
- `OverlayHandler` (`overlay_handler.dart`): manages attachment board, reply anchor, recording bar overlays.
- `OverlayController` (`overlay_controller.dart`): controls attachment board show/hide.
- All overlays are dismissed via `overlayHandler.closeAllOverlays()` before state transitions.

### 9.5 Message Bubble Rendering

`MessageBubble` → `MessageContentBuilder` dispatches by media type:
- **No media / text:** TypeSet-rendered markdown
- **Image:** BlurhHash placeholder → `Image.file` with aspect ratio
- **Video:** Thumbnail image + play icon overlay + duration badge
- **Audio:** Waveform visualization via `siri_wave` + `just_audio` player
- **Document:** File icon + name + size
- **Thread:** Multi-entry card with index badges

Bubble alignment: `isSender = true` → right, `false` → left.
Bubble styles: `normal` (default), `glass` (frosted), `opaque` (solid color from `BubbleColor`).

---

## 10. Theme System

### Color Palette (`theme_constants.dart`)

**Light mode key colors:**
| Token | Hex | Usage |
|---|---|---|
| `sacredSeed` | `#6ca4be` | Primary brand color |
| `senderBlue` | `#AACBDE` | Sender bubble background |
| `textLight` | `#131B24` | Primary text |
| `subtitleLight` | `#6D7D87` | Secondary text |

**Dark mode key colors:**
| Token | Hex | Usage |
|---|---|---|
| `sinisterSeed` | `#0c96a4` | Primary brand color (dark) |
| `senderBlueDark` | `#003755` | Sender bubble background (dark) |
| `textDark` | `#c4cacd` | Primary text |
| `darkAppbar` | `#1d2b36` | App bar background |

### Gradients (`gradients.dart`)

| Name | Colors | Usage |
|---|---|---|
| `lightBackground` | silverSunlight2 → silverGrey | Home/chat background (light) |
| `darkBackground` | shadowBlue → marianaBlue | Home/chat background (dark) |
| `darkChatBackground` | shadowBlue → marianaBlue (top→bottom) | Chat screen (dark) |
| `darkAlertBackground` | 3-stop dark blues | Alert dialogs (dark) |

---

## 11. Dependencies

### Core Dependencies (`pubspec.yaml`)

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `isar_community` / `isar_community_generator` | NoSQL local database |
| `build_runner` | Code generation for Isar schemas |

### Media & Audio

| Package | Purpose |
|---|---|
| `image_picker` | Camera/gallery image/video picking |
| `croppy` | Image cropping UI |
| `blurhash_dart` | BlurHash encoding/decoding |
| `video_player` | Video playback |
| `just_audio` | Audio playback |
| `record` | Audio recording |
| `siri_wave` | Audio waveform visualization |
| `file_picker` | Document/audio file picking |

### UI & UX

| Package | Purpose |
|---|---|
| `typeset` | Markdown rendering in message bubbles |
| `scrollable_positioned_list` | Scroll-to-index message list |
| `emoji_picker_flutter` | Emoji keyboard |
| `iconify_flutter` | Extended icon sets |
| `pasteboard` | Clipboard image support |
| `share_plus` | System share sheet |
| `intl` | Date/time formatting |

### Platform

| Package | Purpose |
|---|---|
| `bitsdojo_window` | Windows custom title bar & window controls |
| `path_provider` | App document directory paths |
| `uuid` | UUID v7 generation for entity IDs |

### Build-time Only

| Package | Purpose |
|---|---|
| `isar_community_generator` | Isar schema codegen (dev) |
| `build_runner` | Code generation runner (dev) |
| `flutter_lints` | Lint rules |

**Critical:** After modifying any Isar model, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 12. Platform-Specific Notes

### Android (Stable)
- Full feature support: camera, recording, video, share intents.
- Gesture navigation detection via `Utils.isAndroidGestureNavigationEnabled()`.
- Share intent handling via `ShareIntentHandler` + platform channels.

### Windows (Alpha)
- Custom window frame via `bitsdojo_window` in `main.dart`.
- `windowsTitleBarColor` `ValueNotifier` drives title bar theming.
- Keyboard shortcuts via `widget_extensions.dart` `.withKeys()` extension.
- Video picking disabled: `pickVideo()` shows snackbar "Video picking not supported on Windows".
- No share intent support.
- Desktop layout variant in `Homescreen/platform/desktop/`.

---

## 13. Feature Request Backlog

> Source: `markdowns/NotesApp_Feature_Requests.docx`

### Sprint 1: P0 Bugs (Fix First)

| # | Bug | Status | Key File(s) |
|---|---|---|---|
| #15 | `§` symbol leaks into clipboard when copying URL messages | Open | `context_menu_options.dart` — add `.replaceAll("§", "")` before `Clipboard.setData` |
| #16 | Theme toggle not persisted to Isar Settings | Open | `theme_provider.dart` — read `isLightMode` from Settings on init; write back on toggle |
| #18 | Back key exits chat screen instead of cancelling selection | Open | `chat_screen.dart` — check `selectedMessages.isNotEmpty` in `PopScope`, call `clearSelection()` |

### Sprint 2: P1 Features (Independent)

| # | Feature | Key File(s) | Notes |
|---|---|---|---|
| #19 | Share individual message via system share sheet | `context_menu_options.dart` | Strip `§` before sharing. `share_plus` already in pubspec. |
| #4 | Draft auto-save | `settings_model.dart`, `bottom_message_bar.dart`, `settings_notifier.dart` | Add `draftText` to Settings. Debounce 500ms. Clear on send. Consider per-chat draft (Chat model) instead. |
| #1 | WhatsApp chat import | New: `whatsapp_import_service.dart` | Parse `.txt` export. Regex: `^\[(\d{1,2}/\d{1,2}/\d{2,4}),\s([^\]]+)\]\s([^:]+):\s(.*)$`. All messages `isSender = true`. Handle locale date format variations. |

### Sprint 3: P2 Features (Lower Urgency)

| # | Feature | Key File(s) | Notes |
|---|---|---|---|
| #21 | Active bubble style indicator | `context_menu_options.dart` | Add `isSelected` to `ContextMenuOption` model |
| #24 | Move "Delete All" to Settings with confirmation | `context_menu_options.dart`, `settings_screen.dart` | Remove from overflow menu, add to Settings with `showDialog` |
| #20 | Left-side bubble default | `settings_model.dart`, `message_bubble.dart` | Add `defaultLeftBubble` bool to Settings |
| #3 | Swipe direction for quote-reply | `settings_model.dart`, `swipable.dart` | Add `swipeRightToReply` bool to Settings |
| #25 | Include Settings in backup | `backup_service.dart` | Add `_upsertSettings()` step in import |
| #26 | Chat lock (prevent deletion) | `chat_model.dart`, chat tile | Add `isLocked` bool to Chat. Check before `onDismissed`. |
| #2 | URL link preview | `bottom_message_bar.dart`, `chat_state_notifier.dart` | **Caution:** Requires network call — conflicts with "100% offline" principle. Must be opt-in with Settings toggle defaulting to OFF. |
| Camera | Zoom+fade transition for camera preview | `transitions.dart`, `camera_screen.dart` | Add `zoomFadeRoute<T>()` to transitions.dart. Replace `MaterialPageRoute` in camera_screen.dart ~line 271. |

---

## 14. Known Issues & Developer Suggestions

### Code Quality Issues

| Issue | Location | Fix |
|---|---|---|
| Duplicate imports | `share_intent_handler.dart` | Same 10 import lines appear twice. Remove duplicate block. |
| Stale old notifiers | `Chat_screen/notifier/old_notifiers/` | 5 unused files. Delete or archive. |
| `GlobalKey` as file-level constants | `settings_screen.dart` (`tile1`, `tile2`, `tile3`) | Will crash on re-mount. Move to widget State or local to `build()`. |
| Missing `toggleTheme()` persistence | `settings_notifier.dart` | `Settings.toggleTheme()` model method exists but notifier doesn't call it. Root cause of bug #16. |
| Undo snackbar sticking | `ChatListNotifier.deleteChatWithUndo()` | Review `SnackBar` duration. Dismiss programmatically on "Undo" tap or navigation. Use `ScaffoldMessenger.hideCurrentSnackBar()`. |

### Architecture Notes

- **Draft text scope:** Feature #4 requests per-chat drafts (like WhatsApp). Current plan adds to Settings (global). Consider adding `String? draftText` to `Chat` model instead for correctness. Discuss with Mirza before implementing.
- **Link preview privacy:** Feature #2 (link preview) requires `http` fetching. Must be opt-in via Settings toggle defaulting OFF, with cached previews in Isar. Document network behavior in UI.
- **WhatsApp import date formats:** Device locale varies format. Build parser with ordered list of known patterns; fall back to raw text on no match. Log skipped lines.

---

## 15. Critical Invariants (DO NOT VIOLATE)

### Database Rules
1. **Always use `writeTxn`** for Isar mutations — never write outside a transaction.
2. **Always `load()` links** before reading `IsarLink` / `IsarLinks` values.
3. **Settings is singleton** at `id = 0`. Never create a second instance.
4. **Init message** (`id = "0000"`) must be auto-deleted on first real message send via `deleteInitMessage()`.
5. **Media cleanup:** Before deleting a media file, check `_isMediaUsedByOthers()` — forwarded messages may share the same file.

### State Rules
6. **`allMessages`** is the authoritative in-memory list. State's `messages` is always derived from it via `List.unmodifiable(allMessages)`.
7. **Never create new providers** — extend existing `ChatStateNotifier`, `ChatListNotifier`, or `SettingsNotifier`.
8. **`copyWith` for immutability** — never mutate `ChatState` fields directly. Always use `state = state.copyWith(...)`.
9. **UI updates after Isar writes** — always update `allMessages` + emit new state after any DB write.

### URL/String Rules
10. **`§` is an internal sentinel** for URL wrapping. Strip with `.replaceAll("§", "")` before any clipboard/share operation. Never modify `withWrappedLinks` or `unwrappedLink`.
11. **Threads are JSON arrays** stored in `message.text`. Always use `safeDecode()` to parse, `jsonEncode()` to serialize.

### UI Rules
12. **Clean Monolith:** Do not extract widgets unless used ≥3 times across ≥3 files. Keep widget trees inline.
13. **Component/Wrapper split:** Components are pure UI; Wrappers read providers. Never put `ref.watch()` in a component.
14. **Overlays must close** before state transitions — always call `overlayHandler.closeAllOverlays()`.

### Platform Rules
15. **Windows guards:** Wrap Android-only features (video pick, share intent, camera) with `Platform.isWindows` checks.
16. **`navigatorKey.currentContext!`** is the fallback for context-free navigation. Use sparingly.

---

## 16. Build & Run Commands

```bash
# Get dependencies
flutter pub get

# Generate Isar schemas (required after model changes)
dart run build_runner build --delete-conflicting-outputs

# Run on Android
flutter run

# Run on Windows (alpha)
flutter run -d windows

# Analyze
flutter analyze
```

---

## 17. File Quick-Reference for Common Tasks

| Task | Primary File(s) |
|---|---|
| Add a new Isar field | `lib/root/data/models/<model>.dart` → run `build_runner` |
| Add a Settings toggle | `settings_model.dart` → `settings_notifier.dart` → `settings_screen.dart` |
| Add a message context menu action | `context_menu_options.dart` → `chat_state_notifier.dart` `handleMessageMenuAction()` |
| Add a homescreen menu action | `context_menu_options.dart` → `chat_list_notifier.dart` |
| Add a new media type | `media_type.dart` enum → `media_model.dart` constructor → `media_handler.dart` → `message_content_builder.dart` |
| Fix a bubble rendering issue | `message_bubble.dart` → `helpers/` → `content/` |
| Add a keyboard shortcut | `widget_extensions.dart` `.withKeys()` |
| Add a page transition | `transitions.dart` |
| Modify backup format | `backup/backup_service.dart` |

---

*End of document. This file is the single source of truth for AI agents working on NotesApp.*
