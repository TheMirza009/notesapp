import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/recording_handler.dart';
import 'package:notesapp/root/screens/Chat_Forward/chat_forward_screen.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/anchor_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/attachment/overlay_controller.dart';
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
final chatStateController =  NotifierProvider<ChatStateNotifier, ChatState>(() => ChatStateNotifier());

class ChatStateNotifier extends Notifier<ChatState> {
  /// Master references & controllers (not part of state)
  final _isar = IsarDatabase.isar;
  List<Message> allMessages = [];
  final TextEditingController searchController = TextEditingController();
  final TypeSetEditingController keyboardController = TypeSetEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final FocusNode keyboardFocusNode = FocusNode();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =  ItemPositionsListener.create();
  final Recorder recorder = Recorder();
  Chat? _chat;
  bool isLoading = false;
  bool get isReplying => state.anchorMessage != null;

  @override
  ChatState build() {
    keyboardFocusNode.addListener(() {
      if (keyboardFocusNode.hasFocus) hideEmojiPicker();
    });

    final selectedChat = ref.watch(chatListProvider.select((s) => s.selectedChat));
    if (selectedChat == null) return ChatState();

    _chat = selectedChat;
    _hydrateMessages(); // Load messages into state
    return ChatState(); // empty initial
  }

  // =====================================================
  // Section: Messages CRUD
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

    await _isar.writeTxn(() async {
      if (state.anchorMessage != null) newMessage.replyingTo.value = state.anchorMessage;
      await _isar.messages.put(newMessage);

      if (_chat != null) {
        _chat!.messages.add(newMessage);
        await _chat!.messages.save();
        await _isar.chats.put(_chat!);
      }

      if (state.anchorMessage != null) await newMessage.replyingTo.save();
    });

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages], anchorMessage: null);
    scrollToBottom();
  }

  Future<void> forwardMessage({
  required Message original,
  required Chat targetChat,
}) async {
  // ✅ Step 1: preload before transaction
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

  // ✅ Prepare cloned media data if any
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

  final replyingTo = original.replyingTo.value;

  await _isar.writeTxn(() async {
    // ✅ Step 2: put media first if exists
    if (clonedMedia != null) {
      await _isar.medias.put(clonedMedia);
    }

    // ✅ Step 3: put message first (makes it managed)
    await _isar.messages.put(newMessage);

    // ✅ Step 4: now safely attach links
    if (clonedMedia != null) {
      newMessage.media.value = clonedMedia;
      await newMessage.media.save();
    }

    if (replyingTo != null) {
      newMessage.replyingTo.value = replyingTo;
      await newMessage.replyingTo.save();
    }

    // ✅ Step 5: attach to chat
    await targetChat.messages.load();
    targetChat.messages.add(newMessage);
    await targetChat.messages.save();

    await _isar.chats.put(targetChat);
  });

  // ✅ Step 6: refresh UI if forwarding to current chat
  final currentChat = _chat;
  if (currentChat != null && currentChat.isarID == targetChat.isarID) {
    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages]);
  }
}


  Future<void> pickImage({Uint8List? imageBytes, bool? isCamera = false, Media? media}) async {
    final Media? pickedMedia =  imageBytes != null 
      ? await MediaHandler.fromImageBytes(imageBytes) 
      : ( media ?? await MediaHandler.pickImage(source: (isCamera ?? false) ? ImageSource.camera : ImageSource.gallery));

    if (pickedMedia == null || _chat == null) return;

    await deleteInitMessage();

    await _isar.writeTxn(() async {
      await _isar.medias.put(pickedMedia);
    });

    final persistedMedia = await _isar.medias.get(pickedMedia.isarId);
    if (persistedMedia == null) return;

    final newMessage = Message()
      ..text = "📷 Photo"
      ..isSender = true
      ..time = DateTime.now()
      ..media.value = persistedMedia;

    await _isar.writeTxn(() async {
      await _isar.messages.put(newMessage);
      await newMessage.media.save();

      final managedChat = await _isar.chats.get(_chat!.isarID);
      if (managedChat != null) {
        await managedChat.messages.load();
        managedChat.messages.add(newMessage);
        await managedChat.messages.save();
        await _isar.chats.put(managedChat);
        _chat = managedChat;
      }
    });

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages]);
    // state = state.copyWith(messages: [...state.messages, newMessage]);
  }

  Future<void> deleteInitMessage() async {
    if (_chat == null || state.messages.isEmpty) return;

    const initID = "0000";
    const initText = "This is a new chat. Start typing to create your first note.";

    final firstMessage = state.messages.first;
    if (firstMessage.id == initID && firstMessage.text == initText) {
      deleteMessage(firstMessage);
    }
  }

  Future<void> deleteMessage(Message message) async {
    await _isar.writeTxn(() async {
      await _isar.messages.delete(message.isarId);
      if (_chat != null) {
        _chat!.messages.remove(message);
        await _chat!.messages.save();
        await _isar.chats.put(_chat!);
      }
    });

    // Handle media deletion if necessary
    final isMedia = message.media.value != null && message.media.value!.type != Mediatype.text;
    if (isMedia) {
      final allMessages = await _isar.messages.where().findAll();
      for (final msg in allMessages) {
        await msg.media.load();
      }
      final isUsedByMultiple = allMessages.hasDuplicateMediaPath(message);
      if (!isUsedByMultiple) await MediaHandler.deleteMedia(message.media.value!);
    }

    final updatedMessages = state.messages.where((m) => m.isarId != message.isarId).toList();
    unSelectAllMessages();
    allMessages.remove(message);
    state = state.copyWith(messages: [...allMessages]);
  }

  Future<void> deleteSelected() async {
    final selected = state.selectedMessages;
    if (selected.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final m in selected) {
        await _isar.messages.delete(m.isarId);
        _chat?.messages.remove(m);

        if (m.media.value != null && m.media.value!.type != Mediatype.text) {
          final allMessages = await _isar.messages.where().findAll();
          for (final msg in allMessages) {
            await msg.media.load();
          }
          final isUsedByMultiple = allMessages.hasDuplicateMediaPath(m);
          if (!isUsedByMultiple) await MediaHandler.deleteMedia(m.media.value!);
        }
      }

      if (_chat != null) {
        await _chat!.messages.save();
        await _isar.chats.put(_chat!);
      }
    });

    unSelectAllMessages();
    allMessages.removeWhere((m) => selected.contains(m));
    state.clearSelection();
    state = state.copyWith(messages: allMessages);
    // state = state.clearSelection().copyWith(
    //   messages: state.messages.where((m) => !selected.contains(m)).toList(),
    // );
  }

  void toggleSender(Message message) async {
    message.isSender = !message.isSender;

    await _isar.writeTxn(() async {
      await _isar.messages.put(message); // save the same instance
    });

    // Update the list
    final index = allMessages.indexWhere((m) => m.isarId == message.isarId);
    if (index != -1) allMessages[index] = message;

    // Trigger state update
    state =  allMessages.length == 1
            ? state.copyWith( messages: [message.copyWith()]) // new instance for first-message animation (BUG FIX)
            : state.copyWith(messages: [...allMessages]);
  }


  // =====================================================
  // Section: Message selection & highlight
  // =====================================================

  void selectMessage(Message message) {
    state = state.selectMessage(message);
    print("Selected: ${state.selectedMessages.length}");
  }

  void unselectMessage(Message message) {
    state = state.unselectMessage(message);
  }

  void unSelectAllMessages() {
    state = state.clearSelection();
  }

  void selectAllMessages() {
    state = state.copyWith(
      selectedMessages: [...state.messages],
    );
  }

  int selectCount() => state.selectedMessages.length;

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

  void setAnchorMessage(Message message) {
    final attachmentOverlay = ref.read(overlayControllerProvider.notifier);
    state = state.copyWith(anchorMessage: message);
    if (!keyboardFocusNode.hasFocus) keyboardFocusNode.requestFocus();
    if (attachmentOverlay.state == true) {
      attachmentOverlay.close();
    }
  }

  void clearAnchorMessage() {
    final newState = state.copyWith(anchorMessage: null);
    state = newState;
    hideReplyAnchor();
    keyboardFocusNode.unfocus();
  }

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

  void hideEmojiPicker() {
    if (state.showEmojis) state = state.copyWith(showEmojis: false);
  }

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

  void clearSearch() {
    searchController.clear();
    state = state.copyWith(messages: [...allMessages]);
  }


  // void searchChats(String query) {
  //   final lowercaseQuery = query.toLowerCase();
  //   final filtered = allMessages.where((m) => (m.text ?? "").toLowerCase().contains(lowercaseQuery)).toList();
  //   state = state.copyWith(messages: query.isEmpty ? [...allMessages] : filtered);
  // }
  void searchChats(String query) {
  if (query.isEmpty) {
    state = state.copyWith(messages: [...allMessages]);
    return;
  }
  final filtered = allMessages.where(
    (m) => (m.text ?? "").toLowerCase().contains(query.toLowerCase())
  ).toList();
  state = state.copyWith(messages: filtered);
}


  void closeSearchAndKeyboard() {
    if (state.isSearching) toggleSearch();
    keyboardFocusNode.unfocus();
    hideEmojiPicker();
  }

  void stopSearching() {
    state = state.copyWith(isSearching: false);
  }
  
  // =====================================================
  // Section: Recording Audio helpers
  // =====================================================

  Future<void> startAudioRecording() async {
    await recorder.startRecording();
    state = state.copyWith(isRecording: true);
  }

  Future<void> cancelAudioRecording() async {
    await recorder.cancelRecording();
    state = state.copyWith(isRecording: false);
  }

  void stopAudioRecording() async {
    final String? recordingPath = await recorder.stopRecording();
    if (recordingPath == null) return;

    final savedAudio = await MediaHandler.saveAudio(recordingPath);
    if (savedAudio == null) return;

    await deleteInitMessage();

    await _isar.writeTxn(() async {
      await _isar.medias.put(savedAudio);
    });

    final persistedMedia = await _isar.medias.get(savedAudio.isarId);
    if (persistedMedia == null) return;

    final newMessage = Message()
      ..text = "🎙️ Recording"
      ..isSender = true
      ..time = DateTime.now()
      ..media.value = persistedMedia;

    await _isar.writeTxn(() async {
      await _isar.messages.put(newMessage);
      await newMessage.media.save();

      final managedChat = await _isar.chats.get(_chat!.isarID);
      if (managedChat != null) {
        await managedChat.messages.load();
        managedChat.messages.add(newMessage);
        await managedChat.messages.save();
        await _isar.chats.put(managedChat);
        _chat = managedChat;
      }
    });

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages], isRecording: false);
    // state = state.copyWith(messages: [...state.messages, newMessage]);
  }


  Future<void> pickDocument() async {
    final Media? pickedMedia = await MediaHandler.pickDocument();

    if (pickedMedia == null || _chat == null) return;
    await deleteInitMessage();

    await _isar.writeTxn(() async {
      await _isar.medias.put(pickedMedia);
    });

    final persistedMedia = await _isar.medias.get(pickedMedia.isarId);
    if (persistedMedia == null) return;

    final newMessage = Message()
      ..text = "📃 Document"
      ..isSender = true
      ..time = DateTime.now()
      ..media.value = persistedMedia;

    await _isar.writeTxn(() async {
      await _isar.messages.put(newMessage);
      await newMessage.media.save();

      final managedChat = await _isar.chats.get(_chat!.isarID);
      if (managedChat != null) {
        await managedChat.messages.load();
        managedChat.messages.add(newMessage);
        await managedChat.messages.save();
        await _isar.chats.put(managedChat);
        _chat = managedChat;
      }
    });

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages], isRecording: false);
    // state = state.copyWith(messages: [...state.messages, newMessage]);
  }

  Future<void> pickAudio() async {
    final Media? pickedMedia = await MediaHandler.pickDocument(fileType: FileType.audio);

    if (pickedMedia == null || _chat == null) return;
    await deleteInitMessage();

    await _isar.writeTxn(() async {
      await _isar.medias.put(pickedMedia);
    });

    final persistedMedia = await _isar.medias.get(pickedMedia.isarId);
    if (persistedMedia == null) return;

    final newMessage = Message()
      ..text = "🎧 Audio"
      ..isSender = true
      ..time = DateTime.now()
      ..media.value = persistedMedia;

    await _isar.writeTxn(() async {
      await _isar.messages.put(newMessage);
      await newMessage.media.save();

      final managedChat = await _isar.chats.get(_chat!.isarID);
      if (managedChat != null) {
        await managedChat.messages.load();
        managedChat.messages.add(newMessage);
        await managedChat.messages.save();
        await _isar.chats.put(managedChat);
        _chat = managedChat;
      }
    });

    allMessages.add(newMessage);
    state = state.copyWith(messages: [...allMessages], isRecording: false);
    // state = state.copyWith(messages: [...state.messages, newMessage]);
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
  
  
  /// Context menu actions
  void handleMessageMenuAction(String action, Message message, BuildContext? context) async {
    switch (action) {
      case 'deleteMessage':
        deleteMessage(message);
        break;
      case 'reply':
        unSelectAllMessages();
        // setAnchorMessage(message);
        showReplyAnchor(context ?? navigatorKey.currentContext!); // show hidden
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setAnchorMessage(message); // trigger slide
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
                    (Mdi.delete_empty_outline), // (IconParkTwotone.delete_five), // Iconify(Fluent.delete_28_regular)
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