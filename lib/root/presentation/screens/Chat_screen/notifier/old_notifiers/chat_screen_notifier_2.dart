// import 'dart:async';
// import 'package:notesapp/core/controllers/isar_database.dart';
// import 'package:notesapp/core/controllers/media_handler.dart';
// import 'package:notesapp/core/utils/utils.dart';
// import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
// import 'package:notesapp/root/data/enums/media_type.dart';
// import 'package:notesapp/root/data/models/chat_model.dart';
// import 'package:notesapp/root/data/models/media_model.dart';
// import 'package:notesapp/root/data/models/message_model.dart';
// import 'package:riverpod/riverpod.dart';
// import 'package:isar/isar.dart';

// /// Provider for the notifier
// final chatScreenController =
//     NotifierProvider.autoDispose<ChatScreenNotifier, Chat?>(
//   () => ChatScreenNotifier(),
// );

// /// ChatScreenNotifier is responsible for managing the lifecycle of a single chat
// class ChatScreenNotifier extends AutoDisposeNotifier<Chat?> {
//   late final Isar _isar;
//   Chat? _chat; // snapshot from chatListProvider
//   bool isLoading = false;
//   bool isSelecting = false;

//   @override
//   Chat? build() {
//     _isar = IsarDatabase.isar;
//     _chat = ref.watch(chatListProvider.notifier).selectedChat;    // Get currently selected chat from chatListProvider
//     if (_chat == null) {                                          // Make sure selectedChat is not null
//       return null;
//     }
//     _hydrateChat(_chat!);                                         // Start async hydration in background
//     return _chat;                                                 // Optimistically return initial reference, UI won’t block
//   }


//  /// ============================== LOAD FROM DATABASE ================================= /// 


//   /// Load full chat with messages + media from Isar and update state
//   Future<void> _hydrateChat(Chat chat) async {
//     if (isLoading) return; // prevent double fetch
//     isLoading = true;

//     final freshChat = await _isar.chats.get(chat.isarID);
//     if (freshChat != null) {
//       await freshChat.messages.load();
//       await Future.wait(freshChat.messages.map((m) => m.media.load()));

//       state = freshChat; // notify listeners with hydrated version
//       debugPrint("Loaded from Isar: $freshChat");
//     }

//     isLoading = false;
//   }

//   /// Load chat synchronously 
//   Future<void> _hydrateChatSync(Chat chat) async {
//     if (isLoading) return;
//     isLoading = true;

//     final freshChat = _isar.chats.getSync(chat.isarID);
//     if (freshChat != null) {
//       freshChat.messages.loadSync();

//       // IMPORTANT: use forEach, not .map()
//       for (final m in freshChat.messages) {
//         m.media.loadSync();
//       }

//       _chat = freshChat; // keep in-memory version updated
//       state = freshChat; // notify listeners immediately
//       debugPrint("Hydrated (sync) from Isar: ${freshChat.title}");
//     }

//     isLoading = false;
//   }

//   /// Function to delete initMessage if present in chat
//   Future<void> deleteInitMessage() async {
//     const String initID = "0000";
//     const String initText = "This is a new chat. Start typing to create your first note.";

//     if (_chat!.messages.isEmpty) return;

//     final first = _chat!.messages.first;
//     if (first.id == initID && first.text == initText) {
//       await deleteMessage(first);
//     }
//   }

//   /// Clears the current chat selection → called when pressing back
//   void clearChat() {
//     ref.read(chatListProvider.notifier).selectedChat = null;
//     state = null;
//   }

//   /// Update Message | isSender // isSelected // Text
//   Future<void> updateMessage(Message message, {bool? refresh = true}) async {
//     await _isar.writeTxn(() async {
//       final existing = await _isar.messages.get(message.isarId);
//       if (existing != null) {
//         existing.text = message.text;
//         existing.isSelected = message.isSelected;
//         existing.isSender = message.isSender;
//         await _isar.messages.put(existing);
//       } else {
//         await _isar.messages.put(message);
//       }
//     });

//     if (refresh == true) await _hydrateChat(_chat!);
//   }

//   /// Send a new text message
//   Future<void> sendMessage(String text) async {
//     if (_chat == null) return;
//     await deleteInitMessage();

//     // Create the message
//     final newMessage = Message().copyWith(
//       text: text,
//       time: DateTime.now(),
//     );

//     await _isar.writeTxn(() async {
//       await _isar.messages.put(newMessage);
//       _chat!.messages.add(newMessage);
//       await _chat!.messages.save();
//     });

//     _chat!
//       ..preview = text
//       ..date = newMessage.time;

//     ref.read(chatListProvider.notifier).updateChat(_chat!);

//     await _hydrateChat(_chat!); // reset from Database
//   }

//   /// Pick image function
//   Future<void> pickImage() async {
//     final pickedMedia = await MediaHandler.pickImage();
//     if (pickedMedia == null) return;

//     await deleteInitMessage();

//     await _isar.writeTxn(() async {
//       await _isar.medias.put(pickedMedia);
//     });

//     final persistedMedia = await _isar.medias.get(pickedMedia.isarId);
//     if (persistedMedia == null) return;

//     final newMessage =
//         Message()
//           ..isSender = true
//           ..isSelected = false
//           ..time = DateTime.now()
//           ..media.value = persistedMedia;

//     await _isar.writeTxn(() async {
//       await _isar.messages.put(newMessage);
//       await newMessage.media.save();
//       _chat!.messages.add(newMessage);
//       await _chat!.messages.save();

//       _chat!.preview = "📷 Photo";
//       _chat!.date = newMessage.time;
//       await _isar.chats.put(_chat!);
//     });

//     ref.read(chatListProvider.notifier).updateChat(_chat!);
//     await _hydrateChat(_chat!);
//   }

//   /// Delete Message
//   Future<void> deleteMessage(Message message) async {
//     await _isar.writeTxn(() async {
//       debugPrint("Deleting: ${message.text}");
//       await _isar.messages.delete(message.isarId);

//       _chat!.messages.remove(message);
//       if (_chat!.messages.isNotEmpty) {
//         final lastMessage = _chat!.messages.toList().last;
//         _chat!.preview = lastMessage.text;
//       } else {
//         _chat!.preview = "No Notes added yet";
//       }
//       await _chat!.messages.save();
//       await _isar.chats.put(_chat!);
//     });

//     if (message.media.value?.type != Mediatype.text && message.media.value != null && state!.messages.isNotEmpty) {
//       await MediaHandler.deleteMedia(message.media.value!);
//     }

//     _hydrateChatSync(_chat!); // Synchronously load chats
//   }

//   /// Function to update Chat title
//   updateChatTitle(String? newTitle) async {
//     _chat!.title = newTitle;
//     await ref.read(chatListProvider.notifier).updateChat(_chat!);
//     await _hydrateChat(_chat!);
//   }

//   /// Context menu actions
//   void handleMessageMenuAction(String action, Message message) {
//     switch (action) {
//       case 'deleteMessage':
//         deleteMessage(message);
//         isSelecting = false;
//         break;
//       case 'reply':
//         debugPrint("Reply to `${message.text}`");
//         break;
//       case 'copy':
//         Utils.copyToClipboard(message.text);
//         break;
//       case 'toggleSender':
//         message.isSender = !message.isSender;
//         updateMessage(message);
//         break;
//     }
//   }

//   void selectMessage(Message message) async {
//     if (message == null) return;
//     isSelecting = true;
//     message.isSelected = true;
//     await updateMessage(message);
//     debugPrint("Selected: ${message.text}");
//   }

//   void unselectMessage(Message message) async {
//     if (message.id == null) return;
//     message.isSelected = false;
//     if (_chat!.messages.every((m) => !m.isSelected)) {
//       unSelectAllMessages();
//     }
//     await updateMessage(message);
//     // await updateMessage(message);
//   }

//   void unSelectAllMessages() async {
//     isSelecting = false;
    
//       for (var m in _chat!.messages) {
//         m.isSelected = false;
//         await updateMessage(m);
//       }
//     // await _hydrateChat(_chat!);
//     state = _chat!;
//   }

//   void selectAllMessages() async {
//     isSelecting = true;
    
//       for (var m in _chat!.messages) {
//         m.isSelected = true;
//         await updateMessage(m);
//       }
//     // await _hydrateChat(_chat!);
//     state = _chat!;
//   }

//   int selectCount() => state!.messages.where((m) => m.isSelected).length;

//   Future<void> deleteSelected() async {
//     if (_chat == null) {
//       debugPrint("No chat loaded");
//       return;
//     }

//     for (final m in _chat!.messages) {
//       debugPrint("Message ${m.text} selected? ${m.isSelected}");
//     }

//     final selected = _chat!.messages.where((m) => m.isSelected).toList();
//     debugPrint("Total selected: ${selected.length}");

//     if (selected.isEmpty) {
//       debugPrint("Early returned");
//       return;
//     }

//     await _isar.writeTxn(() async {
//       for (final m in selected) {
//         await _isar.messages.delete(m.isarId);
//         _chat!.messages.remove(m);

//         // Delete media if needed
//         if (m.media.value?.type != Mediatype.text && m.media.value != null) {
//           await MediaHandler.deleteMedia(m.media.value!);
//         }
//       }
//       await _chat!.messages.save();
//       await _isar.chats.put(_chat!);
//     });

//     unSelectAllMessages();
//     await _hydrateChat(_chat!);
//     state = _chat!;
//   }


//   /// Remove chat if empty
//   void removeChatIfEmpty() {
//     const String initID = "0000";
//     const String initText = "This is a new chat. Start typing to create your first note.";
    
//     final messages = _chat!.messages;
//     if (messages.isEmpty || (messages.length == 1 && messages.first.text == initText && messages.first.text == initID)) {
//       // deleteMessage(messages.first);
//       ref.read(chatListProvider.notifier).removeChat(_chat!);
//     }
//   }
// }
