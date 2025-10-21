import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isar_community/isar.dart';
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
import 'package:riverpod/riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Provider for the notifier
final chatMessagesController =
    NotifierProvider<ChatMessagesNotifier, List<Message>>(
      () => ChatMessagesNotifier(),
    );

class ChatMessagesNotifier extends Notifier<List<Message>> {
  List<Message> _allMessages = []; // Master copy
  final TextEditingController searchController = TextEditingController();
  final TextEditingController keyboardController= TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final FocusNode keyboardFocusNode = FocusNode();
  final itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();
  final _isar = IsarDatabase.isar;
  Chat? _chat; // read-only reference
  bool isLoading = false;
  bool isSelecting = false;
  bool isSearching = false;
  bool showEmojis = false;
  Message? anchorMessage;

  bool get isReplying => anchorMessage != null;

  @override
  List<Message> build() {
    keyboardFocusNode.addListener(() {
      if (keyboardFocusNode.hasFocus) {
        hideEmojiPicker();
      }
    });
    final selectedChat = ref.watch(chatListProvider).selectedChat;
    if (selectedChat == null) {
      return []; // gracefully return empty, no crash
    }
    _chat = selectedChat;
    _hydrateMessages();
    return [];
  }

  /// Load messages from DB and update state
  Future<void> _hydrateMessages() async {
    if (_chat == null || isLoading) return;
    isLoading = true;

    final freshChat = await _isar.chats.get(_chat!.isarID);
    if (freshChat != null) {
      await freshChat.messages.load();
      await Future.wait(freshChat.messages.map((m) => m.media.load()));

      _allMessages = freshChat.messages.toList();
      state = _allMessages;
    }

    isLoading = false;
  }

  /// Update or add a message
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

    // Update state in memory
    final messages = [...state];
    final index = messages.indexWhere((m) => m.isarId == message.isarId);
    if (index != -1) {
      messages[index] = message;
    } else {
      messages.add(message);
    }

    state = messages;
  }

  /// Send a text message
  Future<void> sendMessage(String text) async {
    if (_chat == null) return;

    final newMessage =
        Message()
          ..text = text
          ..time = DateTime.now()
          ..isSender = true;

    await _isar.writeTxn(() async {
      if (anchorMessage != null) {
        newMessage.replyingTo.value = anchorMessage;
      }

      await _isar.messages.put(newMessage);
      if (_chat != null) {
        _chat!.messages.add(newMessage);
        await _chat!.messages.save();
        await _isar.chats.put(_chat!);
      }

      if (anchorMessage != null) {
        await newMessage.replyingTo.save();
      }
    });

    anchorMessage = null;
    _allMessages.add(newMessage);
    state = [..._allMessages];
    deleteInitMessage();
    scrollToBottom();
  }

  /// Pick image and send as message
  Future<void> pickImage({Uint8List? imageBytes}) async {
    final Media? pickedMedia =
        imageBytes != null
            ? await MediaHandler.fromImageBytes(imageBytes)
            : await MediaHandler.pickImage(); // Media Picker Call
    if (pickedMedia == null || _chat == null) return; // Early return on cancel

    // remove init placeholder if present
    await deleteInitMessage(); // Delete initMessage

    // Save Media first
    await _isar.writeTxn(() async {
      // Start first Database write
      await _isar.medias.put(pickedMedia); // Upsert to Media repo
    }); // Get fresh copy from Database

    final persistedMedia = await _isar.medias.get(pickedMedia.isarId);
    if (persistedMedia == null) return;

    final newMessage = // 0 - Message Creation
        Message()
          ..text = "📷 Photo"
          ..isSender = true
          ..time = DateTime.now()
          ..media.value = persistedMedia;

    // Save message and its media relation in one transaction
    await _isar.writeTxn(() async {
      await _isar.messages.put( newMessage, ); // 1 - persist message (assigns isarId)
      await newMessage.media .save(); // 2 - persist the media-to-message relation (this is the crucial step)
      final managedChat = await _isar.chats.get( _chat!.isarID, ); // 3 - attach to a managed chat (re-fetch to ensure it's managed)
      if (managedChat != null) { // 4 - Make sure _chat is not null
        await managedChat.messages.load(); // 5 - Reload assigned messages
        managedChat.messages.add( newMessage, ); // 6 - add new message to loaded chat
        await managedChat.messages .save(); // 7 - Persist the message-to-Chat relationship
        await _isar.chats.put( managedChat, ); // 8 - Upsert the reloaded chat back to isar
        _chat = managedChat; // 9 - refresh reference
      }
    });

    // Update UI state with the *managed* message instance if possible.
    // The `newMessage` now has isar id and media relation stored.
    state = [...state, newMessage]; // 10 - State update

    // Optionally hydrate to ensure freshest managed instances (uncomment if needed)
    // await _hydrateMessages();
  }

  /// Message to delete initial Message ("This is a new chat...")
  Future<void> deleteInitMessage() async {
    if (_chat == null || state == null || state.isEmpty) return;

    const String initID = "0000";
    const String initText = "This is a new chat. Start typing to create your first note.";

    final firstMessage = state!.first;
    if (firstMessage.id == initID && firstMessage.text == initText) {
      deleteMessage(firstMessage);
    }
  }

  /// Delete a single message
  Future<void> deleteMessage(Message message) async {
    await _isar.writeTxn(() async {
      await _isar.messages.delete(message.isarId);
      if (_chat != null) {
        _chat!.messages.remove(message);
        await _chat!.messages.save();
        await _isar.chats.put(_chat!);
      }
    });

    final photoList =
        state
            .where((message) => message.media.value?.type == Mediatype.image)
            .toList();
    final allMessages = await _isar.messages.where().findAll();
    for (final m in allMessages) {
      await m.media.load(); // 👈 ensure media is available
    }
    bool isMedia =
        message.media.value != null &&
        message.media.value!.type != Mediatype.text;
    bool isUsedByMultiple = allMessages.hasDuplicateMediaPath(message);
    debugPrint(
      "Deleting media? ${message.media.value?.path} → used by multiple: $isUsedByMultiple",
    );
    if (isMedia == true && isUsedByMultiple == false) {
      await MediaHandler.deleteMedia(message.media.value!);
    }

    _allMessages.remove(message);
    state = [..._allMessages];

    // state = state.where((m) => m.isarId != message.isarId).toList();
  }

  /// Delete selected messages
  // Future<void> deleteSelected() async {
  //   final selected = _allMessages.where((m) => m.isSelected).toList();
  //   if (selected.isEmpty) return;

  //   await _isar.writeTxn(() async {
  //     for (final m in selected) {
  //       await _isar.messages.delete(m.isarId);
  //       if (_chat != null) {
  //         _chat!.messages.remove(m);
  //       }

  //       // Handle media deletion (only if not reused elsewhere)
  //       if (m.media.value != null && m.media.value!.type != Mediatype.text) {
  //         final allMessages = await _isar.messages.where().findAll();
  //         for (final msg in allMessages) {
  //           await msg.media.load(); // ensure relation is loaded
  //         }
  //         final isUsedByMultiple = allMessages.hasDuplicateMediaPath(m);
  //         if (!isUsedByMultiple) {
  //           await MediaHandler.deleteMedia(m.media.value!);
  //         }
  //       }
  //     }

  //     if (_chat != null) {
  //       await _chat!.messages.save();
  //       await _isar.chats.put(_chat!);
  //     }
  //   });

  //   // Update local collections
  //   unSelectAllMessages();
  //   _allMessages.removeWhere((m) => selected.contains(m));
  //   state = [..._allMessages]; // refresh UI
  // }



  /// Clears the selected chat
  void clearChat() async {
    // ref.read(chatListProvider.notifier).clearSelectedChat();
    await _isar.writeTxn(() async {
      await _chat!.messages.filter().deleteAll();
      await _chat!.messages.save();
      await _isar.chats.put(_chat!);
    });
    state = [];
  }

  void setAnchorMessage(Message message) {
    anchorMessage = message;
    debugPrint(anchorMessage!.text);
    if (!keyboardFocusNode.hasFocus) {keyboardFocusNode.requestFocus();}
    showEmojis = false;
    state = [...state];
  }

  Future<void> clearAnchorMessage() async {
    anchorMessage = null;
    keyboardFocusNode.unfocus();
    state = [...state];
  }


    void toggleEmojiPicker() {
  if (showEmojis) {
    // Emojis open → switch to keyboard
    showEmojis = false;
    state = [...state];
    keyboardFocusNode.requestFocus(); // open keyboard immediately
  } else {
    // Keyboard open → close it first, then animate emojis up
    if (keyboardFocusNode.hasFocus) {
      keyboardFocusNode.unfocus(); // keyboard will close
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      showEmojis = true;
      state = [...state];
    });
  }
}

  void hideEmojiPicker() {
    if (showEmojis) {
      showEmojis = false;
      state = [...state];
    }
  }


  void toggleSearch() async {
    isSearching = !isSearching;

    if (!isSearching) {
      // Closing search → reset and unfocus
      await clearSearch();
      searchFocusNode.unfocus();
    } else {
      // Opening search → clear text
      searchController.clear();

      // Delay focus until SearchBar is mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (searchFocusNode.canRequestFocus) {
          searchFocusNode.requestFocus();
        }
      });
    }

    state = [...state]; // refresh UI
  }

  final Set<Id> _highlighted = {};
  bool isHighlighted(Id id) => _highlighted.contains(id);

  void highlightMessage(Id id) {
    _highlighted.add(id);
    state = [...state]; // rebuild

    Future.delayed(const Duration(milliseconds: 700), () {
      _highlighted.remove(id);
      state = [...state]; // rebuild again
    });
  }

  void scrollToBottom() {
    if (!itemScrollController.isAttached) return;

    itemScrollController.scrollTo(
      index: state.length -1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.0, // ensures the last item is aligned to the bottom
    );
  }



  final Map<int, GlobalKey> messageKeys = {};

  void scrollToIndex(BuildContext context, {bool animated = true}) {

    if (animated) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOut,
      );
    } else {
      Scrollable.ensureVisible(context);
    }
  }

  void scrollToMessage(Id isarID, {bool animated = true}) {
    if (!itemScrollController.isAttached) return;

    final index = state.indexWhere((m) => m.isarId == isarID);
    if (index == -1) return;

    itemScrollController.scrollTo(
      index: index,
      duration: animated ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeIn,
      alignment: 0.1,
    );

    highlightMessage(isarID);
  }

  // void scrollToIndex(int index, {bool animated = true}) {
  //   if (index < 0 || index >= state.length) return;

  //   final scrollOffset = index * 50.0; // estimate or measure row height

  //   if (animated) {
  //     scrollController.animateTo(
  //       scrollOffset,
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeInOut,
  //     );
  //   } else {
  //     scrollController.jumpTo(scrollOffset);
  //   }
  // }
  void searchChats(String query) async {
    if (query.isEmpty) {
      await clearSearch();
      return;
    }
    final lowercaseQuery = query.toLowerCase();
    state =
        _allMessages.where((message) {
          final text = (message.text ?? "").toLowerCase();
          return text.contains(lowercaseQuery);
        }).toList();
  }

  Future<void> clearSearch() async {
    searchController.clear();
    // searchFocusNode.unfocus();
    state = _allMessages;
  }

  /// Method to automatically remove chat if empty
  void removeChatIfEmpty() async {
    if (_chat == null) return;

    // Always re-fetch a managed copy
    final managedChat = await _isar.chats.get(_chat!.isarID);
    if (managedChat == null) return;
    await managedChat.messages.load();

    // Handle empty case
    if (managedChat.messages.isEmpty) {
      ref.read(chatListProvider.notifier).removeChat(managedChat);
      return;
    }

    // Handle init placeholder
    const String initText = "This is a new chat. Start typing to create your first note.";
    const String initID = "0000";

    bool initMessageCheck =
        managedChat.messages.length == 1 &&
        managedChat.messages.first.text == initText &&
        managedChat.messages.first.id == initID;

    if (initMessageCheck) {
      ref.read(chatListProvider.notifier).removeChat(managedChat);
    }
  }

  /// Context menu actions
  // void handleMessageMenuAction(String action, Message message) async {
  //   switch (action) {
  //     case 'deleteMessage':
  //       deleteMessage(message);
  //       isSelecting = false;
  //       break;
  //     case 'reply':
  //       unSelectAllMessages();
  //       setAnchorMessage(message);
  //       break;
  //     case 'copy':
  //       Utils.copyToClipboard(message.text);
  //       unSelectAllMessages();
  //       break;
  //     case 'toggleSender':
  //       message.isSender = !message.isSender;
  //       updateMessage(message);
  //       unSelectAllMessages();
  //       break;
  //     case "share":
  //       await Utils.shareToApps(XFile(message.media.value!.path!));
  //       unSelectAllMessages();
  //       break;
  //   }
  // }

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
}

// final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
//                     showMenu<String>(
//                       context: context,
//                       position: RelativeRect.fromLTRB(
//                         10,
//                         200,
//                         overlay.size.width - 10,
//                         overlay.size.height - 200,
//                       ),
//                       items: const [
//                         PopupMenuItem<String>(
//                           value: "data",
//                           child: Text("Data"),
//                         ),
//                         PopupMenuItem<String>(
//                           value: "settings",
//                           child: Text("Settings"),
//                         ),
//                       ],
//                     );
