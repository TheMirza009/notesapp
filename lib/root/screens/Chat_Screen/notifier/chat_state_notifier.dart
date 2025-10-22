import 'dart:async';
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
import 'package:notesapp/core/controllers/recording_handler.dart';
import 'package:notesapp/root/screens/Chat_Forward/chat_forward_screen.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/anchor_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/attachment/overlay_controller.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/overlays/overlay_handler.dart';
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
    });

    final selectedChat = ref.watch(chatListProvider.select((s) => s.selectedChat));
    if (selectedChat == null) return ChatState();

    _chat = selectedChat;
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _hydrateMessages();
  });
    return ChatState(); // empty initial
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

  Future<void> _hydrateMessages() async {
    if (_chat == null || isLoading) return;
    isLoading = true;

    final freshChat = await _isar.chats.get(_chat!.isarID);
    if (freshChat != null) {
      await freshChat.messages.load();
      await Future.wait(freshChat.messages.map((m) => m.media.load()));
      isLoading = false;
      allMessages = freshChat.messages.toList();
      state = state.copyWith(messages: allMessages);
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
    keyboardFocusNode.requestFocus();
    keyboardController.text = message.text;
    state = state.copyWith(highlightedMessage: message, isEditing: true);
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

    // We will collect media references to inspect after the txn.
    final List<Media> mediaToCheck = [];

    await _isar.writeTxn(() async {
      for (final m in selected) {
        final managedMsg = await _isar.messages.get(m.isarId);
        if (managedMsg != null) {
          await managedMsg.media.load();
          if (managedMsg.media.value != null) {
            mediaToCheck.add(managedMsg.media.value!);
          }
        }
        await _isar.messages.delete(m.isarId);

        if (_chat != null) {
          final managedChat = await _isar.chats.get(_chat!.isarID);
          if (managedChat != null) {
            await managedChat.messages.load();
            managedChat.messages.removeWhere((mm) => mm.isarId == m.isarId);
            await managedChat.messages.save();
            await _isar.chats.put(managedChat);
            _chat = managedChat;
          }
        }
      }
    });

    // Outside txn: for each media, check usage and delete files off main isolate
    for (final media in mediaToCheck) {
      if (media.type != Mediatype.text) {
        final usedByOthers = await _isMediaUsedByOthers(media.path);
        if (!usedByOthers) {
          try {
            await compute(_backgroundDeleteMedia, media.path ?? '');
          } catch (_) {
            await MediaHandler.deleteMedia(media);
          }
        }
      }
    }

    unSelectAllMessages();
    allMessages.removeWhere((m) => selected.contains(m));
    state = state.clearSelection().copyWith(messages: allMessages);
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
    state = state.clearSelection();
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
    state = state.copyWith(isSearching: false, anchorMessage: state.anchorMessage);
  }

  // =====================================================
  // Section: Recording Audio helpers (refactored)
  // =====================================================

  Future<void> startAudioRecording() async {
    await recorder.startRecording();
    state = state.copyWith(isRecording: true, anchorMessage: state.anchorMessage);
  }

  Future<void> cancelAudioRecording() async {
    ref.read(overlayHandlerProvider).hideRecordBar(instant: false);
    await recorder.cancelRecording();
    state = state.copyWith(isRecording: false, anchorMessage: state.anchorMessage);
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

  void scrollToBottom() {
    if (!itemScrollController.isAttached) return;

    itemScrollController.scrollTo(
      index: state.messages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
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

  /// Context menu actions
  void handleMessageMenuAction(String action, Message message, BuildContext? context) async {
    switch (action) {
      case 'deleteMessage':
        deleteMessage(message);
        break;
      case 'edit':
        startEditingTextMessage(message);
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
        Utils.copyToClipboard(message.text);
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
          CupertinoPageRoute(builder: (_) => ChatDetailScreen(chat: chat)),
        );
        break;
      case "chatMedia":
        Navigator.push(
          navigatorKey.currentContext!,
          CupertinoPageRoute(builder: (_) => ChatDetailScreen(chat: chat, scrollToMedia: true,)),
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

  @override
  void dispose() {
    searchController.dispose();
    keyboardController.dispose();
    searchFocusNode.dispose();
    keyboardFocusNode.dispose();
  }
}
