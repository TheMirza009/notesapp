import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isar_community/isar.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/blurhash_service.dart';
import 'package:notesapp/core/controllers/recording_handler.dart';
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/core/extensions/string_extensions.dart';
import 'package:notesapp/root/data/enums/bubble_color.dart';
import 'package:notesapp/root/screens/Chat_Detail/screens/chat_detail_screen_divided.dart';
import 'package:notesapp/root/screens/Chat_Detail/screens/chat_media_screen.dart';
import 'package:notesapp/root/screens/Chat_Forward/chat_forward_screen.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/anchor_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/attachment/overlay_controller.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/overlays/overlay_handler.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:riverpod/riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/message_list_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/widgets/custom_icon_dialogue.dart';
import 'package:typeset/typeset.dart';
import 'package:uuid/uuid.dart';
import 'chat_state.dart';

/// Provider for ChatStateNotifier
final chatStateController = NotifierProvider<ChatStateNotifier, ChatState>(() => ChatStateNotifier());

class ChatStateNotifier extends Notifier<ChatState> {
  final _isar = IsarDatabase.isar; // Master references & controllers (not part of state)
  List<Message> allMessages = [];
  final TextEditingController searchController = TextEditingController();
  final TypeSetEditingController keyboardController = TypeSetEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final FocusNode keyboardFocusNode = FocusNode();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final Recorder recorder = Recorder();
  Chat? _chat;
  bool isLoading = false;
  bool get isReplying => state.anchorMessage != null;

  @override
  ChatState build() {
    ref.keepAlive();
    keyboardFocusNode.addListener(() {
      if (keyboardFocusNode.hasFocus) hideEmojiPicker();
      // scrollToBottomIfLastMessageVisible();
    });

    final selectedChat = ref.watch(
      chatListProvider.select((s) => s.selectedChat),
    );
    if (selectedChat == null) return ChatState();

    _chat = selectedChat;
  
  // Listen for message to highlight
  final messageToHighlight = ref.watch(
    chatListProvider.select((s) => s.messageToHighlight),
  );
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isLoading) {
      hydrateMessages().then((_) {
        // After hydration, check if we need to scroll to a message
        if (messageToHighlight != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            scrollToMessage(messageToHighlight.isarId);
            ref.read(chatListProvider.notifier).clearHighlight();
          });
        }
      });
    }
    _setupKeyboardAutoScroll();
  });
  
  return ChatState();
  }

  // =====================================================
  // Helper: Centralized DB helpers to reduce redundancy
  // =====================================================

  /// Persist a Media object and return the managed (persisted) instance.
  Future<Media?> _persistMedia(Media media) async {
    await _isar.writeTxn(() async {
      await _isar.medias.put(media);
    });
    return await _isar.medias.get(media.isarId);
  }

  /// Core helper to create a Message, optionally attach persisted media & reply link, attach it to the active chat.
  /// This runs a single writeTxn combining all DB writes for a message-send flow.
  Future<Message?> _createAndAttachMessage({
    required Message message,
    Media? persistedMedia, // managed media (must already be in DB or null)
    Message? replyingTo, // link to another managed message
  }) async {
    if (_chat == null) return null;

    await _isar.writeTxn(() async {
      // If replying, link first
      if (replyingTo != null) {
        message.replyingTo.value = replyingTo;
      }

      // Ensure message is stored to obtain isarId
      await _isar.messages.put(message);

      // Attach media if provided
      if (persistedMedia != null) {
        message.media.value = persistedMedia;
        await message.media.save();
      }

      // Ensure chat exists in DB
      Chat? managedChat = await _isar.chats.get(_chat!.isarID);
      if (managedChat == null) {
        // chat might be new; put _chat to create managed chat
        await _isar.chats.put(_chat!);
        managedChat = await _isar.chats.get(_chat!.isarID);
      }

      // Attach message to chat and save
      if (managedChat != null) {
        await managedChat.messages.load();
        managedChat.messages.add(message);
        await managedChat.messages.save();
        await _isar.chats.put(managedChat);
        _chat = managedChat;
      }

      // If replying link exists, save it as well
      if (replyingTo != null) {
        await message.replyingTo.save();
      }
    });

    return message;
  }

  /// Delete a message within a single DB transaction (removes message record and removes links from chat)
  /// Returns a reference to the media (if any) so caller can check and perform file cleanup outside the txn.
  Future<Media?> _deleteMessageManaged(Message message) async {
    Media? mediaRef;
    await _isar.writeTxn(() async {
      final managedMsg = await _isar.messages.get(message.isarId);
      if (managedMsg != null) {
        // Grab media reference before deletion
        await managedMsg.media.load();
        mediaRef = managedMsg.media.value;

        // Delete the message record
        await _isar.messages.delete(managedMsg.isarId);
      }

      // Remove from chat links if chat exists
      if (_chat != null) {
        final managedChat = await _isar.chats.get(_chat!.isarID);
        if (managedChat != null) {
          await managedChat.messages.load();
          // Remove any linked references with same isarId
          final toRemove = managedChat.messages.where((m) => m.isarId == message.isarId).toList();
          if (toRemove.isNotEmpty) {
            for (final r in toRemove) {
              managedChat.messages.remove(r);
            }
            await managedChat.messages.save();
            await _isar.chats.put(managedChat);
            _chat = managedChat;
          }
        }
      }
    });

    return mediaRef;
  }

  /// Helper: determine whether a given media (by path) is used by any message other than an optional excluded message.
  Future<bool> _isMediaUsedByOthers(String? mediaPath, {int? excludingMessageIsarId}) async {
    if (mediaPath == null) return false;
    // Fetch all messages and preload media to inspect paths.
    final msgs = await _isar.messages.where().findAll();
    for (final m in msgs) {
      await m.media.load();
    }
    // Use your existing extension function if available
    final dup = msgs.hasDuplicateMediaPathByPath(mediaPath, excludingIsarId: excludingMessageIsarId);
    return dup;
  }

  // =====================================================
  // Section: Messages CRUD (refactored to reuse helpers)
  // =====================================================

  Future<void> hydrateMessages({
    bool ascending = true, // true → load oldest first, false → newest first
    int visibleCount = 15, // how many messages to load instantly
    int batchSize = 20, // how many to load per background batch
    int concurrency = 4, // how many parallel media loads at a time
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    // Prevent overlapping loads
    if (_chat == null || isLoading) return;
    isLoading = true;
    state = state.copyWith(isLoading: true);

    try {
      // === STEP 1: Fetch only message IDs for efficiency
      final messageIds =
          await _isar.messages
              .filter()
              .chat((q) => q.isarIDEqualTo(_chat!.isarID))
              .sortByTime() // oldest first
              .isarIdProperty()
              .findAll();

      if (messageIds.isEmpty) {
        allMessages = [];
        state = state.copyWith(messages: allMessages, isLoading: false);
        isLoading = false;
        return;
      }

      // === STEP 2: Select which IDs to load first based on order
      List<int> visibleIds;
      if (ascending) {
        // Load oldest messages first (start of chat)
        visibleIds = messageIds.take(visibleCount).toList();
      } else {
        // Load newest messages first (end of chat)
        visibleIds = messageIds.skip(messageIds.length - visibleCount).toList();
      }

      // === STEP 3: Load visible batch
      final visibleMessages = await _loadMessageBatch(
        visibleIds,
        concurrency: concurrency,
      );

      allMessages = visibleMessages;
      state = state.copyWith(
        messages: List.unmodifiable(allMessages),
        isLoading: false,
      );
      isLoading = false;

      // === STEP 4: Progressive background loading
      if (messageIds.length > visibleCount) {
        List<int> remainingIds =
            ascending
                ? messageIds.skip(visibleCount).toList()
                : messageIds.take(messageIds.length - visibleCount).toList();

        _loadRemainingMessagesInBatches(
          remainingIds,
          ascending: ascending,
          batchSize: batchSize,
          concurrency: concurrency,
          delay: delay,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Error hydrating messages: $e');
      debugPrint(stack.toString());
      isLoading = false;
      state = state.copyWith(isLoading: false);
    }
  }

  /// ✅ Load messages AND pre-decode all blurhashes
Future<List<Message>> _loadMessageBatch(
  List<int> ids, {
  int concurrency = 4,
}) async {
  final messages = await _isar.messages.getAll(ids);
  final validMessages = messages.whereType<Message>().toList();

  // ✅ Collect all blurhashes to decode
  final hashesToDecode = <MapEntry<String, double>>[];

  // Load media
  await Future.wait(
    validMessages.map((message) async {
      try {
        await message.media.load();

        final media = message.media.value;
        if (media == null) return;

        // Collect blurhash for batch decode
        if (media.blurHash != null && media.aspectRatio != null) {
          hashesToDecode.add(MapEntry(media.blurHash!, media.aspectRatio!));
        }
      } catch (e) {
        debugPrint('⚠️ Failed to load media: $e');
      }
    }),
  );

  // ✅ CRITICAL: Pre-decode all blurhashes BEFORE returning
  if (hashesToDecode.isNotEmpty) {
    debugPrint('🎨 Pre-decoding ${hashesToDecode.length} blurhashes...');
    await BlurHashService.batchDecode(hashesToDecode);
    debugPrint('✅ Blurhashes decoded!');
  }

  return validMessages;
}

  /// Progressive background loading with append/prepend logic
  Future<void> _loadRemainingMessagesInBatches(
    List<int> remainingIds, {
    bool ascending = true,
    int batchSize = 20,
    int concurrency = 4,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    for (int i = 0; i < remainingIds.length; i += batchSize) {
      if (_chat == null) return; // Cancel if chat changed

      await Future.delayed(delay);

      final batchIds = remainingIds.skip(i).take(batchSize).toList();
      final batchMessages = await _loadMessageBatch(
        batchIds,
        concurrency: concurrency,
      );

      if (ascending) {
        // Appending (older → newer)
        allMessages = [...allMessages, ...batchMessages];
      } else {
        // Prepending (newer → older)
        allMessages = [...batchMessages, ...allMessages];
      }

      state = state.copyWith(messages: List.unmodifiable(allMessages));
    }
  }


  Future<void> updateMessage(Message message) async {
    // Single txn to update message
    await _isar.writeTxn(() async {
      final existing = await _isar.messages.get(message.isarId);
      if (existing != null) {
        existing.text = message.text;
        existing.isSender = message.isSender;
        await _isar.messages.put(existing);
      } else {
        await _isar.messages.put(message);
      }
    });

    final messages = [...state.messages];
    final index = messages.indexWhere((m) => m.isarId == message.isarId);
    if (index != -1) {
      messages[index] = message;
    } else {
      messages.add(message);
    }

    state = state.copyWith(messages: messages);
  }

  Future<void> sendMessage(String text) async {
    if (_chat == null) return;
    await deleteInitMessage();

    final newMessage = Message()
      ..text = text
      ..time = DateTime.now()
      ..isSender = true;

    // Reuse centralized helper for full DB persistence & linking
    await _createAndAttachMessage(
      message: newMessage,
      persistedMedia: null,
      replyingTo: state.anchorMessage,
    );

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages], anchorMessage: null);
    scrollToBottom();
  }

  Future<void> forwardMessage({
    required Message original,
    required Chat targetChat,
  }) async {
    // Preload before transaction
    try {
      await original.media.load();
    } catch (_) {}
    try {
      await original.replyingTo.load();
    } catch (_) {}

    final newMessage = Message()
      ..id = const Uuid().v7()
      ..text = original.text
      ..time = DateTime.now()
      ..isSender = true;

    // Clone media if present (no DB assignment yet)
    final originalMedia = original.media.value;
    Media? clonedMedia;
    if (originalMedia != null) {
      clonedMedia = Media()
        ..name = originalMedia.name
        ..path = originalMedia.path
        ..extension = originalMedia.extension
        ..type = originalMedia.type
        ..aspectRatio = originalMedia.aspectRatio;
    }

    // Persist media + message + attach to targetChat in a single txn (reuse helper semantics)
    await _isar.writeTxn(() async {
      if (clonedMedia != null) {
        await _isar.medias.put(clonedMedia);
      }
      await _isar.messages.put(newMessage);

      if (clonedMedia != null) {
        newMessage.media.value = clonedMedia;
        await newMessage.media.save();
      }

      if (original.replyingTo.value != null) {
        newMessage.replyingTo.value = original.replyingTo.value;
        await newMessage.replyingTo.save();
      }

      // Attach to targetChat
      await targetChat.messages.load();
      targetChat.messages.add(newMessage);
      await targetChat.messages.save();
      await _isar.chats.put(targetChat);
    });

    // Update UI if forwarding to current chat
    final currentChat = _chat;
    if (currentChat != null && currentChat.isarID == targetChat.isarID) {
      allMessages.add(newMessage);
      state = state.copyWith(messages: [...allMessages]);
    }
  }

  void startEditingTextMessage(Message message) {
    cancelAudioRecording();
    ref.read(overlayHandlerProvider).closeAllOverlays();
    keyboardFocusNode.requestFocus();
    keyboardController.text = message.text;
    state = state.copyWith(highlightedMessage: message, isEditing: true);
  }

  void cancelEditing() {
    keyboardFocusNode.requestFocus();
    keyboardController.clear();
    state = state.copyWith(
      isEditing: false,
      highlightedMessage: null,
      selectedMessages: [],
    );
  }

  Future<void> editTextMessage(Message message, String newText) async {
    if (message.isarId == 0) {
      debugPrint("⚠️ Cannot edit unsaved message: ${message.id}");
      return;
    }

    // 1) Persist change on the managed Isar instance
    await _isar.writeTxn(() async {
      final managed = await _isar.messages.get(message.isarId);
      if (managed != null) {
        managed.text = newText;
        await _isar.messages.put(managed);
      } else {
        // Defensive: fallback to putting the detached instance with updated text
        final fallback = message.copyWith(text: newText);
        await _isar.messages.put(fallback);
      }
    });

    // 2) Update in-memory authoritative list (allMessages) if present
    final idx = allMessages.indexWhere((m) => m.isarId == message.isarId);
    if (idx != -1) {
      // Reload the managed message so it has any lazy-loaded links (media, replyingTo, etc.)
      final managedReload = await _isar.messages.get(message.isarId);
      if (managedReload != null) {
        // Ensure related backlinks / media are loaded if needed:
        try {
          await managedReload.media.load();
          await managedReload.replyingTo.load();
        } catch (_) {}

        allMessages[idx] = managedReload;
      } else {
        // Fallback: update the detached object in place
        allMessages[idx] = message.copyWith(text: newText);
      }
    } else {
      // If the message isn't in allMessages, don't append — just log
      debugPrint(
        "⚠️ editTextMessage: message not found in allMessages (${message.isarId})",
      );
    }

    // 3) Push updated list into state (immutable)
    state = state.copyWith(
      messages: List.unmodifiable([...allMessages]),
      isEditing: false,
      highlightedMessage: null,
      selectedMessages: [],
    );
  }

  Future<void> pickImage({Uint8List? imageBytes, bool? isCamera = false, Media? media}) async {
    final Media? pickedMedia = imageBytes != null
        ? await MediaHandler.fromImageBytes(imageBytes)
        : (media ?? await MediaHandler.pickImage(source: (isCamera ?? false) ? ImageSource.camera : ImageSource.gallery));

    if (pickedMedia == null || _chat == null) return;
    await deleteInitMessage();

    // Persist media in a centralized helper
    final persisted = await _persistMedia(pickedMedia);
    if (persisted == null) return;

    final newMessage = Message()
      ..text = "📷 Photo"
      ..isSender = true
      ..time = DateTime.now();

    await _createAndAttachMessage(
      message: newMessage,
      persistedMedia: persisted,
      replyingTo: state.anchorMessage,
    );

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages]);
  }

  Future<void> deleteInitMessage() async {
    if (_chat == null || state.messages.isEmpty) return;

    const initID = "0000";
    const initText = "This is a new chat. Start typing to create your first note.";

    final firstMessage = state.messages.first;
    if (firstMessage.id == initID && firstMessage.text == initText && firstMessage.isSender == false && state.messages.length == 1) {
      deleteMessage(firstMessage);
    }
  }

  Future<void> deleteMessage(Message message) async {
    // Delete message within DB and get media reference back
    final mediaRef = await _deleteMessageManaged(message);

    // If message had media, check if that media is used by any other message; if not, delete file
    if (mediaRef != null && mediaRef.type != Mediatype.text) {
      // See if used by others excluding current message
      final usedByOthers = await _isMediaUsedByOthers(mediaRef.path, excludingMessageIsarId: message.isarId);

      if (!usedByOthers) {
        // Offload file deletion to background isolate to avoid blocking UI
        try {
          await compute(_backgroundDeleteMedia, mediaRef.path ?? '');
        } catch (_) {
          // fallback to direct call if compute fails
          await MediaHandler.deleteMedia(mediaRef);
        }
      }
    }

    // Update in-memory collections & state
    allMessages.removeWhere((m) => m.isarId == message.isarId);
    unSelectAllMessages();
    state = state.copyWith(messages: List.unmodifiable(allMessages));
  }

  /// Background isolate function to delete a media file path. Runs via compute().
  /// Note: compute only accepts/top-level functions.
  static Future<bool> _backgroundDeleteMedia(String path) async {
    try {
      if (path.isEmpty) return false;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Function to delete selected messages from chat
  Future<void> deleteSelected() async {
  final selected = state.selectedMessages;
  if (selected.isEmpty) return;

  try {
    final mediaToCheck = <Media>[];
    
    // ✅ Single transaction for all deletions
    await _isar.writeTxn(() async {
      // Collect media first
      final managedMessages = await _isar.messages.getAll(
        selected.map((m) => m.isarId).toList(),
      );
      
      for (final msg in managedMessages.whereType<Message>()) {
        await msg.media.load().catchError((_) {});
        if (msg.media.value != null) {
          mediaToCheck.add(msg.media.value!);
        }
      }

      // Batch delete messages
      await _isar.messages.deleteAll(
        selected.map((m) => m.isarId).toList(),
      );

      // Update chat links in single operation
      if (_chat != null) {
        final managedChat = await _isar.chats.get(_chat!.isarID);
        if (managedChat != null) {
          await managedChat.messages.load();
          
          final toRemoveIds = selected.map((m) => m.isarId).toSet();
          managedChat.messages.removeWhere((m) => toRemoveIds.contains(m.isarId));
          
          await managedChat.messages.save();
          await _isar.chats.put(managedChat);
          _chat = managedChat;
        }
      }
    });

    // Clean up media in parallel (outside transaction)
    await Future.wait(
      mediaToCheck.map((media) async {
        if (media.type != Mediatype.text) {
          final usedByOthers = await _isMediaUsedByOthers(media.path);
          if (!usedByOthers) {
            compute(_backgroundDeleteMedia, media.path ?? '')
                .catchError((_) => MediaHandler.deleteMedia(media));
          }
        }
      }),
      eagerError: false,
    );

    allMessages.removeWhere((m) => selected.contains(m));
    state = state.copyWith(messages: [...allMessages], selectedMessages: []);
  } catch (e) {
    debugPrint('❌ Error deleting selected: $e');
    Utils.showGlobalSnackBar('Failed to delete messages', Colors.red);
  }
}
  /// Function to change the message sender position
  void toggleSender(Message message) async {
    message.isSender = !message.isSender;

    await _isar.writeTxn(() async {
      await _isar.messages.put(message); // update
    });

    final index = allMessages.indexWhere((m) => m.isarId == message.isarId);
    if (index != -1) allMessages[index] = message;

    state = allMessages.length == 1
        ? state.copyWith(messages: [message.copyWith()]) // new instance for first-message animation (BUG FIX)
        : state.copyWith(messages: [...allMessages]);
  }

  // =====================================================
  // Section: Message selection & highlight
  // =====================================================

  /// Long press to hold message
  void selectMessage(Message message) {
    state = state.selectMessage(message);
    debugPrint("Selected: ${state.selectedMessages.length}");
  }

  /// Unselect while selection mode
  void unselectMessage(Message message) {
    state = state.unselectMessage(message);
  }

  /// Unselects all messages and exits selection mode
  void unSelectAllMessages() {
    if (state.isEditing == false) {
      state = state.clearSelection();
    }
  }

  /// Selects all messages while in selection mode
  void selectAllMessages() {
    state = state.copyWith(
      selectedMessages: [...state.messages],
    );
  }

  /// Exposes number of selected messages
  int selectCount() => state.selectedMessages.length;

  /// Highlights a message temporarily when reply wrapper clicked
  void highlightMessageTemporarily(Message message) {
    state = state.highlightMessage(message);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (state.highlightedMessage?.isarId == message.isarId) {
        state = state.clearHighlight();
      }
    });
  }

  // =====================================================
  // Section: Chat bar / emoji / anchor
  // =====================================================

  /// Reply anchor set
  Future<void> setAnchorMessage(Message message, BuildContext context) async {
    final overlayHandler = ref.read(overlayHandlerProvider);
    state = state.copyWith(anchorMessage: message);
    if (!keyboardFocusNode.hasFocus) {
      keyboardFocusNode.requestFocus();
    }

    // Ensure the attachment board is closed via the centralized handler
    await overlayHandler.closeAttachmentBoard();
    overlayHandler.showReplyAnchor(context);
  }

  /// Clears reply anchor message
  void clearAnchorMessage() {
    final newState = state.copyWith(anchorMessage: null);
    state = newState;
    keyboardFocusNode.unfocus();
  }

  /// Toggles emoji board
  void toggleEmojiPicker() {
    if (state.showEmojis) {
      state = state.copyWith(showEmojis: false);
      keyboardFocusNode.requestFocus();
    } else {
      if (keyboardFocusNode.hasFocus) keyboardFocusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        state = state.copyWith(showEmojis: true);
      });
    }
  }

  /// hides emoji board
  void hideEmojiPicker() {
    if (state.showEmojis) state = state.copyWith(showEmojis: false);
  }

  /// Toggles search
  void toggleSearch() async {
    final newSearching = !state.isSearching;
    if (!newSearching) {
      clearSearch();
    } else {
      searchController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (searchFocusNode.canRequestFocus) searchFocusNode.requestFocus();
      });
    }
    state = state.copyWith(isSearching: newSearching);
  }

  /// Clears search and resets results
  void clearSearch() {
    searchController.clear();
    state = state.copyWith(messages: [...allMessages], anchorMessage: state.anchorMessage);
  }

  /// Filters chat by query
  void searchChats(String query) {
    if (query.isEmpty) {
      state = state.copyWith(messages: [...allMessages]);
      return;
    }
    final filtered = allMessages.where((m) => (m.text ?? "").toLowerCase().contains(query.toLowerCase())).toList();
    state = state.copyWith(messages: filtered);
  }

  /// Closes search and resets chat
  void closeSearchAndKeyboard() {
    if (state.isSearching) toggleSearch();
    clearSearch();
    keyboardFocusNode.unfocus();
    hideEmojiPicker();
  }

  void closeKeyboard() {
    keyboardFocusNode.unfocus();
    hideEmojiPicker();
  }

  void stopSearching() {
    state = state.copyWith(isSearching: false, anchorMessage: state.anchorMessage, highlightedMessage: state.highlightedMessage);
  }

  // =====================================================
  // Section: Recording Audio helpers (refactored)
  // =====================================================

  Future<void> startAudioRecording() async {
    await recorder.startRecording();
    state = state.copyWith(isRecording: true, anchorMessage: state.anchorMessage, selectedMessages: []);
  }

  Future<void> cancelAudioRecording() async {
    ref.read(overlayHandlerProvider).hideRecordBar(instant: false);
    await recorder.cancelRecording();
    state = state.copyWith(isRecording: false, anchorMessage: state.anchorMessage, highlightedMessage: state.highlightedMessage);
  }

  void stopAudioRecording() async {
    final String? recordingPath = await recorder.stopRecording();
    if (recordingPath == null) return;

    final savedAudio = await MediaHandler.saveAudio(recordingPath);
    if (savedAudio == null) return;

    await deleteInitMessage();

    // Persist media then create message via centralized helper
    final persisted = await _persistMedia(savedAudio);
    if (persisted == null) return;

    final newMessage = Message()
      ..text = "🎙️ Recording"
      ..isSender = true
      ..time = DateTime.now();

    await _createAndAttachMessage(
      message: newMessage,
      persistedMedia: persisted,
      replyingTo: state.anchorMessage,
    );

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages], isRecording: false);
  }

  Future<void> pickDocument() async {
    final Media? pickedMedia = await MediaHandler.pickDocument();

    if (pickedMedia == null || _chat == null) return;
    await deleteInitMessage();

    final persisted = await _persistMedia(pickedMedia);
    if (persisted == null) return;

    final newMessage = Message()
      ..text = "📃 Document"
      ..isSender = true
      ..time = DateTime.now();

    await _createAndAttachMessage(
      message: newMessage,
      persistedMedia: persisted,
      replyingTo: state.anchorMessage,
    );

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages]);
  }

  Future<void> pickAudio() async {
    final Media? pickedMedia = await MediaHandler.pickDocument(fileType: FileType.audio);

    if (pickedMedia == null || _chat == null) return;
    await deleteInitMessage();

    final persisted = await _persistMedia(pickedMedia);
    if (persisted == null) return;

    final newMessage = Message()
      ..text = "🎧 Audio"
      ..isSender = true
      ..time = DateTime.now();

    await _createAndAttachMessage(
      message: newMessage,
      persistedMedia: persisted,
      replyingTo: state.anchorMessage,
    );

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages]);
  }

  // =====================================================
  // Section: Scroll helpers
  // =====================================================

  void scrollToBottom({Curve? curve, Duration? duration}) {
    if (!itemScrollController.isAttached) return;

    itemScrollController.scrollTo(
      index: state.messages.length - 1,
      duration: duration ?? const Duration(milliseconds: 300),
      curve: curve ?? Curves.easeOut,
      alignment: 0.0,
    );
  }

  void scrollToMessage(int isarID, {bool animated = true}) {
    final index = state.messages.indexWhere((m) => m.isarId == isarID);
    if (index == -1 || !itemScrollController.isAttached) return;

    itemScrollController.scrollTo(
      index: index,
      duration: animated ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeIn,
      alignment: 0.1,
    );

    final msg = state.messages.firstWhere((m) => m.isarId == isarID);
    highlightMessageTemporarily(msg);
  }

  // =====================================================
  // Section: Chat cleanup / clear
  // =====================================================

  void clearChat() async {
    if (_chat == null) return;
    await _isar.writeTxn(() async {
      await _chat!.messages.filter().deleteAll();
      await _chat!.messages.save();
      await _isar.chats.put(_chat!);
    });
    allMessages = [];
    state = ChatState();
  }

  void removeChatIfEmpty() async {
    if (_chat == null) return;
    final managedChat = await _isar.chats.get(_chat!.isarID);
    if (managedChat == null) return;
    await managedChat.messages.load();

    if (managedChat.messages.isEmpty) {
      ref.read(chatListProvider.notifier).removeChat(managedChat);
      return;
    }

    const initText = "This is a new chat. Start typing to create your first note.";
    const initID = "0000";

    final isInit = managedChat.messages.length == 1 &&
        managedChat.messages.first.text == initText &&
        managedChat.messages.first.id == initID;

    if (isInit) ref.read(chatListProvider.notifier).removeChat(managedChat);
  }

  // ===============================================
  // KEYBOARD METHODS
  // ===============================================

  /// Method to push chat up (or scroll to bottom) if last child is visible
  void _setupKeyboardAutoScroll() {
    // Listen to keyboard focus changes
    debugPrint("⌨️ Keybaord setup");
    keyboardFocusNode.addListener(() {
      if (keyboardFocusNode.hasFocus) {
        // When keyboard gains focus, check if we should scroll to bottom
        scrollToBottomIfLastMessageVisible();
      }
    });
  }

  bool _isLastMessageVisible() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || state.messages.isEmpty) return false;

    final lastIndex = state.messages.length - 1;
    final maxVisibleIndex = positions
        .map((pos) => pos.index)
        .reduce((a, b) => a > b ? a : b);

    // Consider last message visible if it's within the last few messages
    debugPrint("⌨️ LAST MESSAGE ${maxVisibleIndex >= lastIndex - 2}");
    return maxVisibleIndex >= lastIndex - 2;
  }

  void scrollToBottomIfLastMessageVisible() {
    if (state.messages.isEmpty) return;

    // Double-check after a full layout cycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check positions again after layout
      final positions = itemPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;

      final lastIndex = state.messages.length - 1;
      final maxVisibleIndex = positions
          .map((pos) => pos.index)
          .reduce((a, b) => a > b ? a : b);

      final threshold = (state.messages.length * 0.1).ceil();
      final shouldScroll = maxVisibleIndex >= lastIndex - threshold;

      if (shouldScroll) {
        // One more frame to ensure keyboard layout is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom(
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
          );
        });
      }
    });
  }

  // ===============================================
  // THREAD METHODS
  // ===============================================

  /// Start thread creating
  /// Start thread creation — always creates a new message.
Future<void> createThread() async {
  debugPrint('=== CREATE THREAD CALLED ===');
  await deleteInitMessage();

  // 🧹 Step 1: Clear any existing thread state (we always start fresh)
  if (state.activeEditingThread != null) {
    debugPrint('♻️ Disposing previous activeEditingThread: ${state.activeEditingThread!.isarId}');
  }

  state = state.copyWith(
    activeEditingThread: null,
    activeThreadStrings: const [],
    cancelledThread: null,
    isThreading: false,
  );

  // 🧩 Step 2: Prepare initial placeholder thread
  const placeholder = "_Start typing your first thread_";
  final initialThreads = [placeholder];
  final threadsJson = jsonEncode(initialThreads);

  // 🧩 Step 3: Create media + persist it
  final threadMedia = Media.thread(threadsJson);
  final persistedMedia = await _persistMedia(threadMedia);

  // 🧩 Step 4: Create the new message object
  final newMessage = Message()
    ..text = threadsJson
    ..time = DateTime.now()
    ..isSender = true;

  // 🧩 Step 5: Persist it and attach to chat
  final savedMessage = await _createAndAttachMessage(
    message: newMessage,
    persistedMedia: persistedMedia,
    replyingTo: state.anchorMessage,
  );

  if (savedMessage == null) {
    debugPrint('❌ Failed to create new thread message.');
    return;
  }

  // 🧩 Step 6: Update in-memory list and set it as the only active thread
  final updatedMessages = List<Message>.from(allMessages)..add(savedMessage);
  allMessages = updatedMessages;

  state = state.copyWith(
    isThreading: true,
    activeEditingThread: savedMessage,
    activeThreadStrings: initialThreads,
    messages: List.unmodifiable(updatedMessages),
  );

  // 🧩 Step 7: Focus + scroll
  keyboardFocusNode.requestFocus();
  scrollToBottom();

  debugPrint('✅ New activeEditingThread created: ${savedMessage.isarId}');
  debugPrint('=== CREATE THREAD COMPLETED ===');
}


void onTyping(String text) async {
  if (!state.isThreading || state.activeEditingThread == null) {
    return;
  }

  final currentThreads = List<String>.from(state.activeThreadStrings);
  final effective = text.trim().isEmpty && currentThreads.isEmpty
      ? "_Start typing your first thread_"
      : text;

  // Replace the last string in the thread list
  if (currentThreads.isEmpty) {
    currentThreads.add(effective);
  } else {
    currentThreads[currentThreads.length - 1] = effective;
  }

  final threadsJson = jsonEncode(currentThreads);
  final lastThread = state.activeEditingThread!;

  // ✅ Step 1: Load the *managed instance* from Isar
  final managedThread = await _isar.messages.get(lastThread.isarId);
  if (managedThread == null) {
    debugPrint('⚠️ Managed thread not found in DB for id ${lastThread.isarId}');
    return;
  }

  // ✅ Step 2: Update text on the managed instance
  managedThread.text = threadsJson;

  // ✅ Step 3: Update linked media (if exists)
  await managedThread.media.load();
  final media = managedThread.media.value;
  if (media != null && media.type == Mediatype.thread) {
    media.name = threadsJson;
    await _isar.writeTxn(() async {
      await _isar.medias.put(media);
      await _isar.messages.put(managedThread);
    });
  } else {
    await _isar.writeTxn(() async {
      await _isar.messages.put(managedThread);
    });
  }

  // ✅ Step 4: Update in-memory state
  final index = allMessages.indexWhere((m) => m.isarId == managedThread.isarId);
  if (index != -1) {
    allMessages[index] = managedThread;
  }

  state = state.copyWith(
    activeThreadStrings: List.unmodifiable(currentThreads),
    activeEditingThread: managedThread,
    messages: List.unmodifiable(allMessages),
  );

  debugPrint('⌨️ Typing updated thread: ${managedThread.isarId} → $threadsJson');
}

  void ensureThreadTitlePlaceholder() {
    // If there are no threads, or the first thread string is empty,
    // make sure we have a placeholder title.
    final threads = List<String>.from(state.activeThreadStrings);

    if (threads.isEmpty || threads.first.trim().isEmpty) {
      threads
        ..clear()
        ..add("_Start typing your first thread_");

      state = state.copyWith(activeThreadStrings: List.unmodifiable(threads));
    }
  }
void addThread(String text) {
  // Clone current thread strings
  keyboardController.clear();
  final currentThreads = List<String>.from(state.activeThreadStrings);

  // ✅ Only add placeholder if this is the very first thread
  final newEntry = text.trim().isEmpty && currentThreads.isEmpty
      ? "_Start typing your first thread_"
      : text;

  currentThreads.add(newEntry);

  // Encode updated threads as JSON
  final threadsJson = jsonEncode(currentThreads);

  // Update the active message if we're threading
  if (state.isThreading && state.messages.isNotEmpty) {
    final activeThread = state.activeEditingThread;
    if (activeThread == null) return;

    // Update message and its linked media WITH JSON
    final updatedMessage = activeThread.copyWith(text: threadsJson);

    if (updatedMessage.media.value?.type == Mediatype.thread) {
      updatedMessage.media.value = updatedMessage.media.value?.copyWith(
        name: threadsJson, // ✅ Media name should be JSON too
      );
    }

    // Replace last message immutably
    final updatedMessages = state.messages.map((message) {
      return message.isarId == activeThread.isarId ? updatedMessage : message;
    }).toList();

    // Commit changes
    state = state.copyWith(
      activeThreadStrings: List.unmodifiable(currentThreads),
      messages: List.unmodifiable(updatedMessages),
    );
  } else {
    // Edge case: no thread message yet
    state = state.copyWith(
      activeThreadStrings: List.unmodifiable(currentThreads),
    );
  }
}
Future<void> removeLastThread() async {
  final currentThreads = List<String>.from(state.activeThreadStrings);

  // 🧩 Handle placeholder-only state
  if (currentThreads.length == 1 &&
      currentThreads.first == "_Start typing your first thread_") {
    await cancelThread();
    return;
  }

  // 🧩 Remove last entry or reset to placeholder
  if (currentThreads.isNotEmpty) currentThreads.removeLast();
  if (currentThreads.isEmpty) currentThreads.add("_Start typing your first thread_");

  final threadsJson = jsonEncode(currentThreads);

  // 🧩 Only proceed if editing a thread
  if (state.isThreading && state.activeEditingThread != null) {
    final activeThread = state.activeEditingThread!;

    // ✅ Fetch the managed version from Isar
    final managed = await _isar.messages.get(activeThread.isarId);
    if (managed == null) {
      debugPrint('⚠️ Active editing thread not found in Isar.');
      return;
    }

    // ✅ Update text directly on the managed object
    managed.text = threadsJson;

    // ✅ Update linked media safely
    await managed.media.load();
    final media = managed.media.value;
    if (media != null && media.type == Mediatype.thread) {
      media.name = threadsJson;
      await _persistMedia(media); // handles own transaction
    }

    // ✅ Save updated message back to Isar
    await _isar.writeTxn(() async {
      await _isar.messages.put(managed);
    });

    // ✅ Reload the updated message
    final refreshed = await _isar.messages.get(managed.isarId);
    await refreshed?.media.load();

    // ✅ Update in-memory state
    final updatedMessages = List<Message>.from(allMessages);
    final idx = updatedMessages.indexWhere((m) => m.isarId == managed.isarId);
    if (idx != -1 && refreshed != null) {
      updatedMessages[idx] = refreshed;
    }

    allMessages = updatedMessages;

    // ✅ Update state
    state = state.copyWith(
      activeThreadStrings: List.unmodifiable(currentThreads),
      messages: List.unmodifiable(updatedMessages),
      activeEditingThread: refreshed,
    );

    debugPrint('✅ Thread updated after removal: $currentThreads');
  } else {
    // 🧩 Not in thread mode — just update the state
    state = state.copyWith(
      activeThreadStrings: List.unmodifiable(currentThreads),
    );
  }
}


  Future<void> cancelThread() async {
  final lastThread = state.activeEditingThread;
  if (lastThread == null) return;

  final threadIsarId = lastThread.isarId;

  state = state.copyWith(cancelledThread: lastThread);
  keyboardController.clear();

  await Future.delayed(const Duration(milliseconds: 300));

  if (threadIsarId != 0) {
    // ✅ Use your existing deleteMessage method which properly handles chat links
    await deleteMessage(lastThread);
  }

  allMessages.removeWhere((m) => m.isarId == threadIsarId);

  state = state.copyWith(
    messages: List.unmodifiable(allMessages),
    activeThreadStrings: [],
    activeEditingThread: null,
    isThreading: false,
    cancelledThread: null,
  );
}

  bool _isPlaceholderThread(Message? thread) {
    if (thread == null) return false;
    final decodedText = thread.text.safeDecode();
    return thread.text == "_Start typing your first thread_" ||
        (decodedText.isNotEmpty && decodedText.first == "_Start typing your first thread_");
  }

  Future<void> saveThread() async {
  final lastThread = state.activeEditingThread;
  if (lastThread == null) return;

  if (state.activeThreadStrings.length == 1 &&
      state.activeThreadStrings.first == "_Start typing your first thread_") {
    debugPrint('📝 Empty thread not being saved.');
    return;
  }

  // ✅ DEBUG: Check what's being saved
  debugPrint('💾 Saving thread with content: ${state.activeThreadStrings}');
  debugPrint('📝 Last thread text before update: ${lastThread.text}');

  // ✅ Create updated thread with current content
  final updatedThread = lastThread.copyWith(
    text: jsonEncode(state.activeThreadStrings),
  );

  // ✅ Update media name as well to keep in sync
  final updatedMedia = lastThread.media.value?.copyWith(
    name: jsonEncode(state.activeThreadStrings),
  );

  Media? persistedMedia;
  if (updatedMedia != null) {
    persistedMedia = await _persistMedia(updatedMedia);
    // Reattach persisted media
    updatedThread.media.value = persistedMedia;
  }

  // 🧩 Instead of creating a new message, update the existing one
  await _isar.writeTxn(() async {
    await _isar.messages.put(updatedThread);
  });

  // ✅ Replace the old thread with the updated one in allMessages
  final threadIndex = allMessages.indexWhere((m) => m.isarId == lastThread.isarId);
  if (threadIndex != -1) {
    allMessages[threadIndex] = updatedThread;
  }

  keyboardController.clear();
  state = state.copyWith(
    messages: List.unmodifiable(allMessages),
    activeThreadStrings: [],
    activeEditingThread: null,
    cancelledThread: null,
    isThreading: false,
  );

  // ✅ Highlight after rebuild
  WidgetsBinding.instance.addPostFrameCallback((_) {
    highlightMessageTemporarily(updatedThread);
  });

  debugPrint('✅ Thread updated successfully (no duplication): ${updatedThread.text}');
}



void editThread(Message thread) {
  unSelectAllMessages();
  keyboardController.text = thread.text.safeDecode().last;
    state = state.copyWith(
      activeEditingThread: thread,
      activeThreadStrings: thread.text.safeDecode(),
      isThreading: true,
    );

}
  // ===============================================
  // CONTEXT MENUS
  // ===============================================

  /// Context menu actions
  void handleMessageMenuAction(String action, Message message, BuildContext? context) async {
    switch (action) {
      case 'deleteMessage':
        deleteMessage(message);
        break;
      case 'edit':
        message.isThread ? editThread(message) : startEditingTextMessage(message);
      case 'reply':
        unSelectAllMessages();
        ref.read(overlayHandlerProvider).showReplyAnchor(context ?? navigatorKey.currentContext!); // show hidden
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setAnchorMessage(message, context!); // trigger slide
        });
        break;
      case 'forward':
        unSelectAllMessages();
        Navigator.push(navigatorKey.currentContext!, CupertinoPageRoute(builder: (_) => ChatForwardScreen(message: message)));
        break;
      case 'copy':
        if (message.isImage) {
          Utils.copyImageFromPath(message.media.value!.path);
        } else if (message.isThread) {
          Utils.copyTextToClipboard(message.text.formatThread());
        } else {
          Utils.copyTextToClipboard(message.text);
        }
        unSelectAllMessages();
        break;
      case 'toggleSender':
        message.isSender = !message.isSender;
        updateMessage(message);
        unSelectAllMessages();
        break;
      case "share":
        await Utils.shareToApps(XFile(message.media.value!.path!));
        unSelectAllMessages();
        break;
    }
  }

  void handleChatScreenOptions(String action, Chat chat) {
    switch (action) {
      case "chatInfo":
        Navigator.push(
          navigatorKey.currentContext!,
          CupertinoPageRoute(builder: (_) => ChatDetailScreenDivided(chat: chat)),
        );
        break;
      case "chatMedia":
        Navigator.push(
          navigatorKey.currentContext!,
          CupertinoPageRoute(builder: (_) => ChatMediaScreen(chat: chat)),
        );
        break;
      case "search":
        toggleSearch();
      case "clearChat":
        showCupertinoDialog(
          context: navigatorKey.currentContext!,
          builder:
              (_) => CustomAlertDialog(
                title: "Delete all notes",
                content: "Are you sure you want to delete all notes?",
                iconColor: Colors.redAccent,
                iconData:
                    (Mdi.delete_empty_outline),
                iconSize: 25,
                option: TextButton(
                  onPressed: () {
                    Navigator.pop(navigatorKey.currentContext!);
                    clearChat();
                  },
                  child: Text(
                    "Delete",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
        );
    }
  }

  void setBubbleColor({required BubbleColor scheme}) {
    state = state.copyWith(bubbleColor: scheme);
  }

  @override
  void dispose() {
    searchController.dispose();
    keyboardController.dispose();
    searchFocusNode.dispose();
    keyboardFocusNode.dispose();
  }
}
