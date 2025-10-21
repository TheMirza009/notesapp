// import 'package:isar_community/isar.dart';
// import 'package:notesapp/core/controllers/isar_database.dart';
// import 'package:notesapp/root/data/enums/bubble_style.dart';
// import 'package:uuid/uuid.dart';
// import 'message_model.dart';
// import 'media_model.dart';

// part 'chat_model.g.dart';

// @collection
// class Chat {
//   Id isarID = Isar.autoIncrement;

//   @Index(unique: true)
//   late String uuid;

//   String? title;
//   late String preview;
//   DateTime date = DateTime.now();
//   String? chatPhotoPath;
//   String? chatBackgroundPath;

//   // Enum field for bubble style, default to opaque
//   @enumerated
//   BubbleStyle bubbleStyle = BubbleStyle.opaque;

//   IsarLinks<Message> messages = IsarLinks<Message>();

//   Chat() {
//     uuid = const Uuid().v7();
//     preview = "";
//   }

//   Chat copyWith({
//     String? title,
//     String? preview,
//     DateTime? date,
//     String? chatPhotoPath,
//     IsarLinks<Message>? messages,
//     List<Media>? media,
//     BubbleStyle? bubbleStyle, // Add here
//   }) {
//     final newChat = Chat()
//       ..isarID = isarID
//       ..uuid = uuid
//       ..title = title ?? this.title
//       ..preview = preview ?? this.preview
//       ..date = date ?? this.date
//       ..chatPhotoPath = chatPhotoPath ?? this.chatPhotoPath
//       ..bubbleStyle = bubbleStyle ?? this.bubbleStyle;

//     if (messages != null) {
//       newChat.messages.addAll(messages);
//     } else {
//       newChat.messages.addAll(this.messages.toList());
//     }

//     return newChat;
//   }

//   factory Chat.emptyChat() {
//     final chat = Chat();

//     final firstMessage =
//         Message()
//           ..text = "This is a new chat. Start typing to create your first note."
//           ..isSender = false
//           ..time = DateTime.now();

//     chat.messages.add(firstMessage);
//     chat.preview = firstMessage.text;
//     chat.date = firstMessage.time;

//     // Bubble style is already defaulted to opaque
//     return chat;
//   }
// }

// import 'dart:typed_data';
// import 'package:isar_community/isar.dart';
// import 'message_model.dart';
// import '../enums/media_type.dart';

// part 'media_model.g.dart';

// @collection
// class Media {
//   Id isarId = Isar.autoIncrement;

//   late String name;
//   String? path;
//   late String extension;

//   @enumerated
//   late Mediatype type;

//   /// New field to store width / height ratio
//   double? aspectRatio;

//   @Backlink(to: 'media')
//   final IsarLinks<Message> messagesBacklink = IsarLinks<Message>();

//   Media();

//   factory Media.text() {
//     final media = Media();
//     media.name = "";
//     media.extension = "txt";
//     media.type = Mediatype.text;
//     media.path = null;
//     return media;
//   }

//   factory Media.fromFilePath(String filePath) {
//     final media = Media();
//     final segments = filePath.split('/');
//     media.name = segments.isNotEmpty ? segments.last : filePath;
//     media.path = filePath;
//     final ext = media.name.split('.').last.toLowerCase();
//     media.extension = ext;
//     media.type = _detectType(ext);
//     return media;
//   }

//   factory Media.fromLink(String url) {
//     final media = Media();
//     final uri = Uri.parse(url);
//     media.name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
//     media.path = url;
//     media.extension = media.name.contains('.') ? media.name.split('.').last.toLowerCase() : '';
//     media.type = Mediatype.link;
//     return media;
//   }

//   factory Media.fromImageBytes(Uint8List bytes) {
//     final media = Media();
//     media.name = "pasted_${DateTime.now().millisecondsSinceEpoch}.png";
//     media.extension = "png";
//     media.type = Mediatype.image;
//     media.path = null;

//     return media;
//   }

//   static Mediatype _detectType(String ext) {
//     if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) return Mediatype.image;
//     if (['mp4', 'mov', 'mkv', 'avi'].contains(ext)) return Mediatype.video;
//     if (['mp3', 'wav', 'aac', 'ogg', 'flac', 'opus', 'm4a', 'amr', 'wma'].contains(ext)) return Mediatype.audio;
//     if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) return Mediatype.document;
//     return Mediatype.unknown;
//   }

//   @override
//   String toString() => 'Media(name: $name, type: $type, ext: $extension, path: ${path ?? "remote"}, aspectRatio: $aspectRatio)';
// }

// import 'package:isar_community/isar.dart';
// import 'package:uuid/uuid.dart';
// import 'media_model.dart';
// import 'chat_model.dart';

// part 'message_model.g.dart';

// @collection
// class Message {
//   Id isarId = Isar.autoIncrement;

//   late String id;
//   late String text;
//   late DateTime time;
//   late bool isSender;

//   IsarLink<Media> media = IsarLink<Media>();
//   IsarLink<Message> replyingTo = IsarLink<Message>();

//   @Backlink(to: 'messages')
//   final IsarLink<Chat> chat = IsarLink<Chat>();

//   Message() {
//     id = const Uuid().v7();
//     text = "";
//     time = DateTime.now();
//     isSender = true;
//   }

//   Message copyWith({
//     String? id,
//     String? text,
//     DateTime? time,
//     bool? isSender,
//     Media? media,
//     Message? replyingTo,
//   }) {
//     final newMessage = Message()
//       ..id = id ?? this.id
//       ..text = text ?? this.text
//       ..time = time ?? this.time
//       ..isSender = isSender ?? this.isSender;

//     // Copy media link
//     if (media != null) {
//       newMessage.media.value = media;
//     } else if (this.media.value != null) {
//       newMessage.media.value = this.media.value;
//     }

//     // Copy replyingTo link
//     if (replyingTo != null) {
//       newMessage.replyingTo.value = replyingTo;
//     } else if (this.replyingTo.value != null) {
//       newMessage.replyingTo.value = this.replyingTo.value;
//     }

//     return newMessage;
//   }

//   @override
//   String toString() =>
//       'Message(id: $id, text: "$text", isSender: $isSender, time: $time, media: ${media.value}, replyingTo: ${replyingTo.value?.id})';
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
// import 'package:notesapp/core/controllers/isar_database.dart';
// import 'package:notesapp/core/extensions/chat_extensions.dart';
// import 'package:notesapp/root/data/enums/chatlist_filter.dart';
// import 'package:notesapp/root/data/models/chat_model.dart';

// class ChatListState {
//   final List<Chat> chats;
//   final Chat? selectedChat;
//   final bool isLoading; 

//   const ChatListState({
//     this.chats = const [],
//     this.selectedChat,
//     this.isLoading = false,
//   });

//   ChatListState copyWith({
//     List<Chat>? chats,
//     Chat? selectedChat,
//     bool? isLoading,
//   }) {
//     return ChatListState(
//       chats: chats ?? this.chats,
//       selectedChat: selectedChat ?? this.selectedChat,
//       isLoading: isLoading ?? this.isLoading,
//     );
//   }
// }

// /// The provider
// final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
//   return ChatListNotifier();
// });


// /// Notifier that controls a list of chats stored in Isar
// class ChatListNotifier extends StateNotifier<ChatListState> {
//   List<Chat> _allChats = [];// master list, source of truth
//   ChatlistFilter _currentFilter = ChatlistFilter.oldestCreated; // default
//   ChatListNotifier() : super(const ChatListState()) {
//     loadChats();
//   }

//   /// Load all chats from DB
//   Future<void> loadChats() async {
//     state = state.copyWith(isLoading: true);
//     final loadedChats = await IsarDatabase.loadAllChats();
//     _allChats = loadedChats;
//     state = state.copyWith(chats: loadedChats, isLoading: false);
//   }

//   Future<void> refreshChat(int isarId) async {
//   final fresh = await IsarDatabase.isar.chats.get(isarId);
//   if (fresh == null) return;

//   await fresh.messages.load();
//   _allChats = _allChats.map((c) => c.isarID == isarId ? fresh : c).toList();
//   final updatedChats = state.chats.map((c) => c.isarID == isarId ? fresh : c).toList();
//   final newSelected = state.selectedChat?.isarID == isarId ? fresh : state.selectedChat;

//   state = state.copyWith(chats: updatedChats, selectedChat: newSelected);
// }

//   /// Create + persist + add to state
//   Future<Chat> addChat() async {
//     final savedChat = await IsarDatabase.addNewChat();
//     _allChats = [..._allChats, savedChat];
//     state = state.copyWith(chats: [...state.chats, savedChat]);
//     return savedChat;
//   }

//   /// Remove chat
//   Future<void> removeChat(Chat chat) async {
//     await IsarDatabase.isar.writeTxn(() async {
//       await IsarDatabase.isar.chats.delete(chat.isarID);
//     });

//     _allChats = _allChats.where((c) => c.isarID != chat.isarID).toList();

//     state = state.copyWith(
//       chats: state.chats.where((c) => c.isarID != chat.isarID).toList(),
//       selectedChat: state.selectedChat?.isarID == chat.isarID
//           ? null
//           : state.selectedChat,
//     );
//   }

//   /// Clear all chats
//   Future<void> clearChats() async {
//     await IsarDatabase.clearRepo();
//     _allChats = [];
//     state = const ChatListState();
//   }

//   /// Update chat and keep state consistent
//   Future<void> updateChat(Chat updatedChat) async {
//     await IsarDatabase.saveChat(updatedChat);

//     _allChats = _allChats
//         .map((c) => c.isarID == updatedChat.isarID ? updatedChat : c)
//         .toList();

//     final updatedChats = state.chats
//         .map((c) => c.isarID == updatedChat.isarID ? updatedChat : c)
//         .toList();

//     final newSelected = state.selectedChat?.isarID == updatedChat.isarID
//         ? updatedChat
//         : state.selectedChat;

//     state = state.copyWith(chats: updatedChats, selectedChat: newSelected);
//   }

//   /// Search chats by title
//   void searchChats(String query) {
//     if (query.isEmpty) {
//       clearSearch();
//       return;
//     }
//     final lowercaseQuery = query.toLowerCase();
//     state = state.copyWith(
//       chats: _allChats.where(
//         (chat) => (chat.title ?? "").toLowerCase().contains(lowercaseQuery)).toList(),
//     );
//   }

//   /// Reset to full list
//   void clearSearch() {
//     state = state.copyWith(chats: _allChats);
//   }

//   /// Select chat
//   void selectChat(Chat chat) {
//     state = state.copyWith(selectedChat: chat);
//   }

//   /// clear selectedChat
//   void clearSelectedChat() {
//   state = state.copyWith(selectedChat: null);
//   }

//   /// Change selected chat title
//   void changeSelectedChatTitle(String newTitle) {
//     if (state.selectedChat == null) return;
//     final updatedChat = state.selectedChat!.copyWith(title: newTitle);
//     final updatedChats = state.chats
//         .map((c) => c.isarID == updatedChat.isarID ? updatedChat : c)
//         .toList();

//     state = state.copyWith(chats: updatedChats, selectedChat: updatedChat);
//   }

//   /// Get chat by ID
//   Chat getChatByID(String uuid) {
//     return _allChats.firstWhere((chat) => chat.uuid == uuid);
//   }

//   /// Sort chats based on the current filter
//   void applyFilter(ChatlistFilter filter) {
//     _currentFilter = filter;

//     List<Chat> sortedChats = List.from(_allChats); // clone master list

//     switch (filter) {
//       case ChatlistFilter.alphabetical:
//         sortedChats.sort(
//           (a, b) => (a.title ?? "").toLowerCase().compareTo(
//             (b.title ?? "").toLowerCase(),
//           ),
//         );
//         break;

//       case ChatlistFilter.newestCreated:
//         sortedChats.sort((a, b) => b.date.compareTo(a.date));
//         break;

//       case ChatlistFilter.oldestCreated:
//         sortedChats.sort((a, b) => a.date.compareTo(b.date));
//         break;

//       case ChatlistFilter.newestModified:
//         sortedChats.sort(
//           (a, b) => b.loadLastMessageTime().compareTo(a.loadLastMessageTime()),
//         );
//         break;

//       case ChatlistFilter.oldestModified:
//         sortedChats.sort(
//           (a, b) => a.loadLastMessageTime().compareTo(b.loadLastMessageTime()),
//         );
//         break;
//     }

//     state = state.copyWith(chats: sortedChats);
//   }
// }

// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:iconify_flutter/icons/mdi.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:isar_community/isar.dart';
// import 'package:notesapp/core/Theme/theme_constants.dart';
// import 'package:notesapp/core/controllers/recording_handler.dart';
// import 'package:notesapp/root/screens/Chat_Forward/chat_forward_screen.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/anchor_wrapper.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/attachment/overlay_controller.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/overlays/overlay_handler.dart';
// import 'package:riverpod/riverpod.dart';
// import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// import 'package:notesapp/core/controllers/isar_database.dart';
// import 'package:notesapp/core/controllers/media_handler.dart';
// import 'package:notesapp/core/extensions/message_list_extensions.dart';
// import 'package:notesapp/core/utils/global_keys.dart';
// import 'package:notesapp/core/utils/utils.dart';
// import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
// import 'package:notesapp/root/data/enums/media_type.dart';
// import 'package:notesapp/root/data/models/chat_model.dart';
// import 'package:notesapp/root/data/models/media_model.dart';
// import 'package:notesapp/root/data/models/message_model.dart';
// import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
// import 'package:notesapp/root/widgets/custom_icon_dialogue.dart';
// import 'package:typeset/typeset.dart';
// import 'package:uuid/uuid.dart';
// import 'chat_state.dart';

// /// Provider for ChatStateNotifier
// final chatStateController = NotifierProvider<ChatStateNotifier, ChatState>(() => ChatStateNotifier());

// class ChatStateNotifier extends Notifier<ChatState> {
//   final _isar = IsarDatabase.isar; // Master references & controllers (not part of state)
//   List<Message> allMessages = [];
//   final TextEditingController searchController = TextEditingController();
//   final TypeSetEditingController keyboardController = TypeSetEditingController();
//   final FocusNode searchFocusNode = FocusNode();
//   final FocusNode keyboardFocusNode = FocusNode();
//   final ItemScrollController itemScrollController = ItemScrollController();
//   final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
//   final Recorder recorder = Recorder();
//   Chat? _chat;
//   bool isLoading = false;
//   bool get isReplying => state.anchorMessage != null;

//   @override
//   ChatState build() {
//     keyboardFocusNode.addListener(() {
//       if (keyboardFocusNode.hasFocus) hideEmojiPicker();
//     });

//     final selectedChat = ref.watch(chatListProvider.select((s) => s.selectedChat));
//     if (selectedChat == null) return ChatState();

//     _chat = selectedChat;
//     _hydrateMessages(); // Load messages into state
//     return ChatState(); // empty initial
//   }

//   // =====================================================
//   // Helper: Centralized DB helpers to reduce redundancy
//   // =====================================================

//   /// Persist a Media object and return the managed (persisted) instance.
//   Future<Media?> _persistMedia(Media media) async {
//     await _isar.writeTxn(() async {
//       await _isar.medias.put(media);
//     });
//     return await _isar.medias.get(media.isarId);
//   }

//   /// Core helper to create a Message, optionally attach persisted media & reply link, attach it to the active chat.
//   /// This runs a single writeTxn combining all DB writes for a message-send flow.
//   Future<Message?> _createAndAttachMessage({
//     required Message message,
//     Media? persistedMedia, // managed media (must already be in DB or null)
//     Message? replyingTo, // link to another managed message
//   }) async {
//     if (_chat == null) return null;

//     await _isar.writeTxn(() async {
//       // If replying, link first
//       if (replyingTo != null) {
//         message.replyingTo.value = replyingTo;
//       }

//       // Ensure message is stored to obtain isarId
//       await _isar.messages.put(message);

//       // Attach media if provided
//       if (persistedMedia != null) {
//         message.media.value = persistedMedia;
//         await message.media.save();
//       }

//       // Ensure chat exists in DB
//       Chat? managedChat = await _isar.chats.get(_chat!.isarID);
//       if (managedChat == null) {
//         // chat might be new; put _chat to create managed chat
//         await _isar.chats.put(_chat!);
//         managedChat = await _isar.chats.get(_chat!.isarID);
//       }

//       // Attach message to chat and save
//       if (managedChat != null) {
//         await managedChat.messages.load();
//         managedChat.messages.add(message);
//         await managedChat.messages.save();
//         await _isar.chats.put(managedChat);
//         _chat = managedChat;
//       }

//       // If replying link exists, save it as well
//       if (replyingTo != null) {
//         await message.replyingTo.save();
//       }
//     });

//     return message;
//   }

//   /// Delete a message within a single DB transaction (removes message record and removes links from chat)
//   /// Returns a reference to the media (if any) so caller can check and perform file cleanup outside the txn.
//   Future<Media?> _deleteMessageManaged(Message message) async {
//     Media? mediaRef;
//     await _isar.writeTxn(() async {
//       final managedMsg = await _isar.messages.get(message.isarId);
//       if (managedMsg != null) {
//         // Grab media reference before deletion
//         await managedMsg.media.load();
//         mediaRef = managedMsg.media.value;

//         // Delete the message record
//         await _isar.messages.delete(managedMsg.isarId);
//       }

//       // Remove from chat links if chat exists
//       if (_chat != null) {
//         final managedChat = await _isar.chats.get(_chat!.isarID);
//         if (managedChat != null) {
//           await managedChat.messages.load();
//           // Remove any linked references with same isarId
//           final toRemove = managedChat.messages.where((m) => m.isarId == message.isarId).toList();
//           if (toRemove.isNotEmpty) {
//             for (final r in toRemove) {
//               managedChat.messages.remove(r);
//             }
//             await managedChat.messages.save();
//             await _isar.chats.put(managedChat);
//             _chat = managedChat;
//           }
//         }
//       }
//     });

//     return mediaRef;
//   }

//   /// Helper: determine whether a given media (by path) is used by any message other than an optional excluded message.
//   Future<bool> _isMediaUsedByOthers(String? mediaPath, {int? excludingMessageIsarId}) async {
//     if (mediaPath == null) return false;
//     // Fetch all messages and preload media to inspect paths.
//     final msgs = await _isar.messages.where().findAll();
//     for (final m in msgs) {
//       await m.media.load();
//     }
//     // Use your existing extension function if available
//     final dup = msgs.hasDuplicateMediaPathByPath(mediaPath, excludingIsarId: excludingMessageIsarId);
//     return dup;
//   }

//   // =====================================================
//   // Section: Messages CRUD (refactored to reuse helpers)
//   // =====================================================

//   Future<void> _hydrateMessages() async {
//     if (_chat == null || isLoading) return;
//     isLoading = true;

//     final freshChat = await _isar.chats.get(_chat!.isarID);
//     if (freshChat != null) {
//       await freshChat.messages.load();
//       await Future.wait(freshChat.messages.map((m) => m.media.load()));
//       isLoading = false;
//       allMessages = freshChat.messages.toList();
//       state = state.copyWith(messages: allMessages);
//     }
//   }

//   Future<void> updateMessage(Message message) async {
//     // Single txn to update message
//     await _isar.writeTxn(() async {
//       final existing = await _isar.messages.get(message.isarId);
//       if (existing != null) {
//         existing.text = message.text;
//         existing.isSender = message.isSender;
//         await _isar.messages.put(existing);
//       } else {
//         await _isar.messages.put(message);
//       }
//     });

//     final messages = [...state.messages];
//     final index = messages.indexWhere((m) => m.isarId == message.isarId);
//     if (index != -1) {
//       messages[index] = message;
//     } else {
//       messages.add(message);
//     }

//     state = state.copyWith(messages: messages);
//   }

//   Future<void> sendMessage(String text) async {
//     if (_chat == null) return;
//     await deleteInitMessage();

//     final newMessage = Message()
//       ..text = text
//       ..time = DateTime.now()
//       ..isSender = true;

//     // Reuse centralized helper for full DB persistence & linking
//     await _createAndAttachMessage(
//       message: newMessage,
//       persistedMedia: null,
//       replyingTo: state.anchorMessage,
//     );

//     allMessages.add(newMessage);
//     state = state.copyWith(messages: [...allMessages], anchorMessage: null);
//     scrollToBottom();
//   }

//   Future<void> forwardMessage({
//     required Message original,
//     required Chat targetChat,
//   }) async {
//     // Preload before transaction
//     try {
//       await original.media.load();
//     } catch (_) {}
//     try {
//       await original.replyingTo.load();
//     } catch (_) {}

//     final newMessage = Message()
//       ..id = const Uuid().v7()
//       ..text = original.text
//       ..time = DateTime.now()
//       ..isSender = true;

//     // Clone media if present (no DB assignment yet)
//     final originalMedia = original.media.value;
//     Media? clonedMedia;
//     if (originalMedia != null) {
//       clonedMedia = Media()
//         ..name = originalMedia.name
//         ..path = originalMedia.path
//         ..extension = originalMedia.extension
//         ..type = originalMedia.type
//         ..aspectRatio = originalMedia.aspectRatio;
//     }

//     // Persist media + message + attach to targetChat in a single txn (reuse helper semantics)
//     await _isar.writeTxn(() async {
//       if (clonedMedia != null) {
//         await _isar.medias.put(clonedMedia);
//       }
//       await _isar.messages.put(newMessage);

//       if (clonedMedia != null) {
//         newMessage.media.value = clonedMedia;
//         await newMessage.media.save();
//       }

//       if (original.replyingTo.value != null) {
//         newMessage.replyingTo.value = original.replyingTo.value;
//         await newMessage.replyingTo.save();
//       }

//       // Attach to targetChat
//       await targetChat.messages.load();
//       targetChat.messages.add(newMessage);
//       await targetChat.messages.save();
//       await _isar.chats.put(targetChat);
//     });

//     // Update UI if forwarding to current chat
//     final currentChat = _chat;
//     if (currentChat != null && currentChat.isarID == targetChat.isarID) {
//       allMessages.add(newMessage);
//       state = state.copyWith(messages: [...allMessages]);
//     }
//   }

//   Future<void> pickImage({Uint8List? imageBytes, bool? isCamera = false, Media? media}) async {
//     final Media? pickedMedia = imageBytes != null
//         ? await MediaHandler.fromImageBytes(imageBytes)
//         : (media ?? await MediaHandler.pickImage(source: (isCamera ?? false) ? ImageSource.camera : ImageSource.gallery));

//     if (pickedMedia == null || _chat == null) return;
//     await deleteInitMessage();

//     // Persist media in a centralized helper
//     final persisted = await _persistMedia(pickedMedia);
//     if (persisted == null) return;

//     final newMessage = Message()
//       ..text = "📷 Photo"
//       ..isSender = true
//       ..time = DateTime.now();

//     await _createAndAttachMessage(
//       message: newMessage,
//       persistedMedia: persisted,
//       replyingTo: state.anchorMessage,
//     );

//     allMessages.add(newMessage);
//     state = state.copyWith(messages: [...allMessages]);
//   }

//   Future<void> deleteInitMessage() async {
//     if (_chat == null || state.messages.isEmpty) return;

//     const initID = "0000";
//     const initText = "This is a new chat. Start typing to create your first note.";

//     final firstMessage = state.messages.first;
//     if (firstMessage.id == initID && firstMessage.text == initText && firstMessage.isSender == false && state.messages.length == 1) {
//       deleteMessage(firstMessage);
//     }
//   }

//   Future<void> deleteMessage(Message message) async {
//     // Delete message within DB and get media reference back
//     final mediaRef = await _deleteMessageManaged(message);

//     // If message had media, check if that media is used by any other message; if not, delete file
//     if (mediaRef != null && mediaRef.type != Mediatype.text) {
//       // See if used by others excluding current message
//       final usedByOthers = await _isMediaUsedByOthers(mediaRef.path, excludingMessageIsarId: message.isarId);

//       if (!usedByOthers) {
//         // Offload file deletion to background isolate to avoid blocking UI
//         try {
//           await compute(_backgroundDeleteMedia, mediaRef.path ?? '');
//         } catch (_) {
//           // fallback to direct call if compute fails
//           await MediaHandler.deleteMedia(mediaRef);
//         }
//       }
//     }

//     // Update in-memory collections & state
//     allMessages.removeWhere((m) => m.isarId == message.isarId);
//     unSelectAllMessages();
//     state = state.copyWith(messages: [...allMessages]);
//   }

//   /// Background isolate function to delete a media file path. Runs via compute().
//   /// Note: compute only accepts/top-level functions.
//   static Future<bool> _backgroundDeleteMedia(String path) async {
//     try {
//       if (path.isEmpty) return false;
//       final file = File(path);
//       if (await file.exists()) {
//         await file.delete();
//       }
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

//   /// Function to delete selected messages from chat
//   Future<void> deleteSelected() async {
//     final selected = state.selectedMessages;
//     if (selected.isEmpty) return;

//     // We will collect media references to inspect after the txn.
//     final List<Media> mediaToCheck = [];

//     await _isar.writeTxn(() async {
//       for (final m in selected) {
//         final managedMsg = await _isar.messages.get(m.isarId);
//         if (managedMsg != null) {
//           await managedMsg.media.load();
//           if (managedMsg.media.value != null) {
//             mediaToCheck.add(managedMsg.media.value!);
//           }
//         }
//         await _isar.messages.delete(m.isarId);

//         if (_chat != null) {
//           final managedChat = await _isar.chats.get(_chat!.isarID);
//           if (managedChat != null) {
//             await managedChat.messages.load();
//             managedChat.messages.removeWhere((mm) => mm.isarId == m.isarId);
//             await managedChat.messages.save();
//             await _isar.chats.put(managedChat);
//             _chat = managedChat;
//           }
//         }
//       }
//     });

//     // Outside txn: for each media, check usage and delete files off main isolate
//     for (final media in mediaToCheck) {
//       if (media.type != Mediatype.text) {
//         final usedByOthers = await _isMediaUsedByOthers(media.path);
//         if (!usedByOthers) {
//           try {
//             await compute(_backgroundDeleteMedia, media.path ?? '');
//           } catch (_) {
//             await MediaHandler.deleteMedia(media);
//           }
//         }
//       }
//     }

//     unSelectAllMessages();
//     allMessages.removeWhere((m) => selected.contains(m));
//     state = state.clearSelection().copyWith(messages: allMessages);
//   }

//   /// Function to change the message sender position
//   void toggleSender(Message message) async {
//     message.isSender = !message.isSender;

//     await _isar.writeTxn(() async {
//       await _isar.messages.put(message); // update
//     });

//     final index = allMessages.indexWhere((m) => m.isarId == message.isarId);
//     if (index != -1) allMessages[index] = message;

//     state = allMessages.length == 1
//         ? state.copyWith(messages: [message.copyWith()]) // new instance for first-message animation (BUG FIX)
//         : state.copyWith(messages: [...allMessages]);
//   }

//   // =====================================================
//   // Section: Message selection & highlight
//   // =====================================================

//   /// Long press to hold message
//   void selectMessage(Message message) {
//     state = state.selectMessage(message);
//     debugPrint("Selected: ${state.selectedMessages.length}");
//   }

//   /// Unselect while selection mode
//   void unselectMessage(Message message) {
//     state = state.unselectMessage(message);
//   }

//   /// Unselects all messages and exits selection mode
//   void unSelectAllMessages() {
//     state = state.clearSelection();
//   }

//   /// Selects all messages while in selection mode
//   void selectAllMessages() {
//     state = state.copyWith(
//       selectedMessages: [...state.messages],
//     );
//   }

//   /// Exposes number of selected messages
//   int selectCount() => state.selectedMessages.length;

//   /// Highlights a message temporarily when reply wrapper clicked
//   void highlightMessageTemporarily(Message message) {
//     state = state.highlightMessage(message);
//     Future.delayed(const Duration(milliseconds: 700), () {
//       if (state.highlightedMessage?.isarId == message.isarId) {
//         state = state.clearHighlight();
//       }
//     });
//   }

//   // =====================================================
//   // Section: Chat bar / emoji / anchor
//   // =====================================================

//   /// Reply anchor set
//   Future<void> setAnchorMessage(Message message, BuildContext context) async {
//     final overlayHandler = ref.read(overlayHandlerProvider);
//     state = state.copyWith(anchorMessage: message);
//     if (!keyboardFocusNode.hasFocus) {
//       keyboardFocusNode.requestFocus();
//     }

//     // Ensure the attachment board is closed via the centralized handler
//     await overlayHandler.closeAttachmentBoard();
//     overlayHandler.showReplyAnchor(context);
//   }

//   /// Clears reply anchor message
//   void clearAnchorMessage() {
//     final newState = state.copyWith(anchorMessage: null);
//     state = newState;
//     keyboardFocusNode.unfocus();
//   }

//   /// Toggles emoji board
//   void toggleEmojiPicker() {
//     if (state.showEmojis) {
//       state = state.copyWith(showEmojis: false);
//       keyboardFocusNode.requestFocus();
//     } else {
//       if (keyboardFocusNode.hasFocus) keyboardFocusNode.unfocus();
//       Future.delayed(const Duration(milliseconds: 100), () {
//         state = state.copyWith(showEmojis: true);
//       });
//     }
//   }

//   /// hides emoji board
//   void hideEmojiPicker() {
//     if (state.showEmojis) state = state.copyWith(showEmojis: false);
//   }

//   /// Toggles search
//   void toggleSearch() async {
//     final newSearching = !state.isSearching;
//     if (!newSearching) {
//       clearSearch();
//     } else {
//       searchController.clear();
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (searchFocusNode.canRequestFocus) searchFocusNode.requestFocus();
//       });
//     }
//     state = state.copyWith(isSearching: newSearching);
//   }

//   /// Clears search and resets results
//   void clearSearch() {
//     searchController.clear();
//     state = state.copyWith(messages: [...allMessages]);
//   }

//   /// Filters chat by query
//   void searchChats(String query) {
//     if (query.isEmpty) {
//       state = state.copyWith(messages: [...allMessages]);
//       return;
//     }
//     final filtered = allMessages.where((m) => (m.text ?? "").toLowerCase().contains(query.toLowerCase())).toList();
//     state = state.copyWith(messages: filtered);
//   }

//   /// Closes search and resets chat
//   void closeSearchAndKeyboard() {
//     if (state.isSearching) toggleSearch();
//     clearSearch();
//     keyboardFocusNode.unfocus();
//     hideEmojiPicker();
//   }

//   void closeKeyboard() {
//     keyboardFocusNode.unfocus();
//     hideEmojiPicker();
//   }

//   void stopSearching() {
//     state = state.copyWith(isSearching: false);
//   }

//   // =====================================================
//   // Section: Recording Audio helpers (refactored)
//   // =====================================================

//   Future<void> startAudioRecording() async {
//     await recorder.startRecording();
//     state = state.copyWith(isRecording: true, anchorMessage: state.anchorMessage);
//   }

//   Future<void> cancelAudioRecording() async {
//     ref.read(overlayHandlerProvider).hideRecordBar(instant: false);
//     await recorder.cancelRecording();
//     state = state.copyWith(isRecording: false, anchorMessage: state.anchorMessage);
//   }

//   void stopAudioRecording() async {
//     final String? recordingPath = await recorder.stopRecording();
//     if (recordingPath == null) return;

//     final savedAudio = await MediaHandler.saveAudio(recordingPath);
//     if (savedAudio == null) return;

//     await deleteInitMessage();

//     // Persist media then create message via centralized helper
//     final persisted = await _persistMedia(savedAudio);
//     if (persisted == null) return;

//     final newMessage = Message()
//       ..text = "🎙️ Recording"
//       ..isSender = true
//       ..time = DateTime.now();

//     await _createAndAttachMessage(
//       message: newMessage,
//       persistedMedia: persisted,
//       replyingTo: state.anchorMessage,
//     );

//     allMessages.add(newMessage);
//     state = state.copyWith(messages: [...allMessages], isRecording: false);
//   }

//   Future<void> pickDocument() async {
//     final Media? pickedMedia = await MediaHandler.pickDocument();

//     if (pickedMedia == null || _chat == null) return;
//     await deleteInitMessage();

//     final persisted = await _persistMedia(pickedMedia);
//     if (persisted == null) return;

//     final newMessage = Message()
//       ..text = "📃 Document"
//       ..isSender = true
//       ..time = DateTime.now();

//     await _createAndAttachMessage(
//       message: newMessage,
//       persistedMedia: persisted,
//       replyingTo: state.anchorMessage,
//     );

//     allMessages.add(newMessage);
//     state = state.copyWith(messages: [...allMessages]);
//   }

//   Future<void> pickAudio() async {
//     final Media? pickedMedia = await MediaHandler.pickDocument(fileType: FileType.audio);

//     if (pickedMedia == null || _chat == null) return;
//     await deleteInitMessage();

//     final persisted = await _persistMedia(pickedMedia);
//     if (persisted == null) return;

//     final newMessage = Message()
//       ..text = "🎧 Audio"
//       ..isSender = true
//       ..time = DateTime.now();

//     await _createAndAttachMessage(
//       message: newMessage,
//       persistedMedia: persisted,
//       replyingTo: state.anchorMessage,
//     );

//     allMessages.add(newMessage);
//     state = state.copyWith(messages: [...allMessages]);
//   }

//   // =====================================================
//   // Section: Scroll helpers
//   // =====================================================

//   void scrollToBottom() {
//     if (!itemScrollController.isAttached) return;

//     itemScrollController.scrollTo(
//       index: state.messages.length - 1,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeOut,
//       alignment: 0.0,
//     );
//   }

//   void scrollToMessage(int isarID, {bool animated = true}) {
//     final index = state.messages.indexWhere((m) => m.isarId == isarID);
//     if (index == -1 || !itemScrollController.isAttached) return;

//     itemScrollController.scrollTo(
//       index: index,
//       duration: animated ? const Duration(milliseconds: 300) : Duration.zero,
//       curve: Curves.easeIn,
//       alignment: 0.1,
//     );

//     final msg = state.messages.firstWhere((m) => m.isarId == isarID);
//     highlightMessageTemporarily(msg);
//   }

//   // =====================================================
//   // Section: Chat cleanup / clear
//   // =====================================================

//   void clearChat() async {
//     if (_chat == null) return;
//     await _isar.writeTxn(() async {
//       await _chat!.messages.filter().deleteAll();
//       await _chat!.messages.save();
//       await _isar.chats.put(_chat!);
//     });
//     state = ChatState();
//   }

//   void removeChatIfEmpty() async {
//     if (_chat == null) return;
//     final managedChat = await _isar.chats.get(_chat!.isarID);
//     if (managedChat == null) return;
//     await managedChat.messages.load();

//     if (managedChat.messages.isEmpty) {
//       ref.read(chatListProvider.notifier).removeChat(managedChat);
//       return;
//     }

//     const initText = "This is a new chat. Start typing to create your first note.";
//     const initID = "0000";

//     final isInit = managedChat.messages.length == 1 &&
//         managedChat.messages.first.text == initText &&
//         managedChat.messages.first.id == initID;

//     if (isInit) ref.read(chatListProvider.notifier).removeChat(managedChat);
//   }

//   /// Context menu actions
//   void handleMessageMenuAction(String action, Message message, BuildContext? context) async {
//     switch (action) {
//       case 'deleteMessage':
//         deleteMessage(message);
//         break;
//       case 'reply':
//         unSelectAllMessages();
//         ref.read(overlayHandlerProvider).showReplyAnchor(context ?? navigatorKey.currentContext!); // show hidden
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           setAnchorMessage(message, context!); // trigger slide
//         });
//         break;
//       case 'forward':
//         unSelectAllMessages();
//         Navigator.push(navigatorKey.currentContext!, CupertinoPageRoute(builder: (_) => ChatForwardScreen(message: message)));
//         break;
//       case 'copy':
//         Utils.copyToClipboard(message.text);
//         unSelectAllMessages();
//         break;
//       case 'toggleSender':
//         message.isSender = !message.isSender;
//         updateMessage(message);
//         unSelectAllMessages();
//         break;
//       case "share":
//         await Utils.shareToApps(XFile(message.media.value!.path!));
//         unSelectAllMessages();
//         break;
//     }
//   }

//   void handleChatScreenOptions(String action, Chat chat) {
//     switch (action) {
//       case "chatInfo":
//         Navigator.push(
//           navigatorKey.currentContext!,
//           CupertinoPageRoute(builder: (_) => ChatDetailScreen(chat: chat)),
//         );
//         break;
//       case "chatMedia":
//         Navigator.push(
//           navigatorKey.currentContext!,
//           CupertinoPageRoute(builder: (_) => ChatDetailScreen(chat: chat, scrollToMedia: true,)),
//         );
//         break;
//       case "search":
//         toggleSearch();
//       case "clearChat":
//         showCupertinoDialog(
//           context: navigatorKey.currentContext!,
//           builder:
//               (_) => CustomAlertDialog(
//                 title: "Delete all notes",
//                 content: "Are you sure you want to delete all notes?",
//                 iconColor: Colors.redAccent,
//                 iconData:
//                     (Mdi.delete_empty_outline),
//                 iconSize: 25,
//                 option: TextButton(
//                   onPressed: () {
//                     Navigator.pop(navigatorKey.currentContext!);
//                     clearChat();
//                   },
//                   child: Text(
//                     "Delete",
//                     style: TextStyle(color: Colors.redAccent),
//                   ),
//                 ),
//               ),
//         );
//     }
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     keyboardController.dispose();
//     searchFocusNode.dispose();
//     keyboardFocusNode.dispose();
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
// import 'package:notesapp/core/Theme/gradients.dart';
// import 'package:notesapp/core/extensions/context_extensions.dart';
// import 'package:notesapp/root/data/models/chat_model.dart';
// import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/components/auto_hide_scroll_to_bottom.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/attachment/overlay_controller.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/bottom_message_bar_wrapper.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/chat_appbar_wrapper.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/chat_searchbar.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/emoji_board_wrapper.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/message_list_wrapper.dart';
// import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier_o.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/overlays/overlay_handler.dart';

// //TODO: 2. Notifier needs robustness and double checks
// //TODO: 5. Full-sized images being shown as thumbnails
// //TODO: 6. Everything rebuilds when the long press is called
// //TODO: 7. Search does not show new messages
// //TODO: 8. First message does not change isSender state.
// //TODO: 9. Clear Chat does not delete all messages properly.
// //TODO: 10. Square images not being displayed properly.
// //TODO: 11. State problems ocurring again.
// //TODO: 12. Audio/Documents being replied to errors 
// //TODO: 13. Preferable to revamp the overall messagebar structure 
// //TODO: 14. If a media has duplicates, don't delete it
// //TODO: 14. Audio players need to be robusted
// //TODO: 14. Hero-Overlay needs implementation in ChatDetailScreen
// //TODO: 14. Media other than images need to be formatted inside ChatDetailScreen
// //TODO: 14. Search needs to be handled inside Forward screen
// //TODO: 14. Camera needs robustness
// //TODO: 14. GIF / Pasting needs robustness
// //TODO: 14. Reply wrapper needs to handle other media
// //TODO: 14. Audio record UI / overlay needs implementation

// final StateProvider<bool> isNewChat = StateProvider((_) => false);

// class ChatScreen extends ConsumerWidget {
//   const ChatScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // final notifier = ref.read(chatMessagesController.notifier);
//     final notifier = ref.read(chatStateController.notifier);
//     final overlayHandler = ref.read(overlayHandlerProvider);
//     final canPop = ref.watch(chatStateController.select((s) => !s.isSearching && !s.showEmojis)) && overlayHandler.allClosed;
//     final backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;
//     final newChat = ref.read(isNewChat);
//     debugPrint("🔃 ChatScreen rebuilt");

//     if (newChat) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         ref.read(chatStateController.notifier).keyboardFocusNode.requestFocus();
//         ref.read(isNewChat.notifier).state = false;
//       });
//     }

//     return PopScope(
//       canPop: canPop,
//       onPopInvokedWithResult: (didPop, result) {
//         final state = ref.read(chatStateController);
//         final notifier = ref.read(chatStateController.notifier);

//         // intercept back button
//         if (state.showEmojis) {
//           notifier.hideEmojiPicker();
//           return; // prevent popping
//         }

//         if (state.isSearching) {
//           notifier.stopSearching();
//           notifier.closeSearchAndKeyboard();
//           return; // prevent popping
//         }

//         // ✅ nothing to intercept → allow pop
//         notifier.unSelectAllMessages();
//         notifier.clearAnchorMessage();
//         notifier.removeChatIfEmpty();
//         overlayHandler.closeAttachmentBoard(instant: true);
//         overlayHandler.hideRecordBar(instant: true);
//         overlayHandler.hideReplyAnchor(instant: true);
//         notifier.cancelAudioRecording();
//       },
//       child: GestureDetector(
//         onTap: () {
//           notifier.stopSearching();
//           notifier.searchFocusNode.unfocus();
//           notifier.keyboardFocusNode.unfocus();
//           notifier.hideEmojiPicker();
//           notifier.unSelectAllMessages();
//           ref.read(overlayHandlerProvider).closeAttachmentBoard();
//         },
//         child: Scaffold(
//           backgroundColor: Colors.transparent,
//           body: Container(
//             decoration: BoxDecoration(gradient: backgroundGradient),
//             child: Column(
//               children: [
//                 const ChatAppBarWrapper(),
//                 const ChatSearchBar(),
//                 const MessageListWrapper(),
//                 const BottomMessageBarWrapper(),
//                 const EmojiBoardWrapper(),
//               ],
//             ),
//           ),
//           floatingActionButton: Consumer(
//             builder: (context, ref, _) {
//               final state = ref.watch(chatStateController);
//               if (state.showEmojis || state.isSearching || state.messages.isEmpty) {
//                 return const SizedBox.shrink(); // hide FAB
//               }

//               return AutoHideScrollToBottom(
//                 itemScrollController: notifier.itemScrollController,
//                 itemPositionsListener: notifier.itemPositionsListener,
//                 lastIndex: state.messages.length - 1,
//                 bottomPadding: notifier.isReplying ? 135 : 80,
//                 backgroundColor: context.isLight ? const Color(0xFFD5F0FF) : const Color(0xFF94C1DB),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }


// import 'dart:io';

// import 'package:extended_image/extended_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:notesapp/core/Theme/theme_constants.dart';
// import 'package:notesapp/core/extensions/context_extensions.dart';
// import 'package:notesapp/core/extensions/media_extensions.dart';
// import 'package:notesapp/core/extensions/message_extensions.dart';
// import 'package:notesapp/core/extensions/message_list_extensions.dart';
// import 'package:notesapp/core/utils/context_menu_options.dart';
// import 'package:notesapp/root/data/enums/bubble_style.dart';
// import 'package:notesapp/root/data/models/message_model.dart';
// import 'package:notesapp/root/screens/Chat_Detail/chat_detail_base_state.dart';
// import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
// import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/components/date_chip.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/anchor_wrapper.dart';
// import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier_o.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/message_bubble.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/overlays/overlay_handler.dart';
// import 'package:notesapp/root/screens/Settings/notifier/settings_notifier.dart';
// import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
// import 'package:notesapp/root/widgets/nothing_to_see.dart';
// import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';
// import 'package:open_file/open_file.dart';
// import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
// import 'package:url_launcher/url_launcher.dart';

// class MessageListWrapper extends ConsumerWidget {
//   const MessageListWrapper({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final notifier = ref.read(chatStateController.notifier);
//     final messages = ref.watch( chatStateController.select((s) => s.messages));
//     final isLoading = ref.watch(chatStateController.notifier).isLoading;

//   //   WidgetsBinding.instance.addPostFrameCallback((_) {
//   //   if (notifier.itemScrollController.isAttached && messages.isNotEmpty) {
//   //     notifier.itemScrollController.jumpTo(index: messages.length - 1);
//   //   }
//   // });

//     return Expanded(
//       child: isLoading ? LoadIndicator() : messages.isEmpty
//           ? const NothingToSee()
//           : ScrollablePositionedList.builder(
//               itemScrollController: notifier.itemScrollController,
//               itemPositionsListener: notifier.itemPositionsListener,
//               itemCount: messages.length + 1,
//               itemBuilder: (context, index) {
//                 if (index == messages.length) {
//                   return const SizedBox( height: 150);
//                 }

//                 final message = messages[index]; // 👈 Get the message directly
//                 return ProviderScope(
//                   overrides: [
//                     // messageIdProvider.overrideWith((_) => messageId),
//                     messageProvider.overrideWithValue(message), // 👈 Pass the message instead of finding it later
//                   ],
//                   child: const _MessageItemBuilder(),
//                 );
//               },
//             ),
//     );
//   }
// }

// // Provide the ID instead of index
// final messageIdProvider = Provider<int>((_) => throw UnimplementedError());
// final messageProvider = Provider<Message>((_) => throw UnimplementedError());

// class _MessageItemBuilder extends ConsumerWidget {
//   const _MessageItemBuilder({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final message = ref.watch(messageProvider);
//     final bubbleStyle = ref.watch(settingsController)?.selectedBubbleStyle ?? BubbleStyle.opaque;

//     if (message == null) {
//       return const SizedBox.shrink(); // Message got deleted -> don't render
//     }

//     if (message.isImage) {
//       final path = message.media.value?.path;
//       if (path != null) {
//         precacheImage(ExtendedFileImageProvider(File(path), cacheRawData: true), context);
//       }
//     }

//     // 👇 Watch only derived info for this index
//     final info = ref.watch( chatStateController.select((s) => s.messages.layoutInfoById(message.isarId)));
//     final isHighlighted = ref.watch( chatStateController.select((s) => s.highlightedMessage?.isarId == message.isarId), );
//     final isSelected = ref.watch( chatStateController.select((s) => s.selectedMessages.any((m) => m.isarId == message.isarId)), );
//     final isSelecting = ref.watch( chatStateController.select((s) => s.isSelecting), );

//     debugPrint("🔃 Built message: ${message.text}");

//     return Column(
//       children: [
//         if (info.showDateChip) DateChip(message.time),
//         RepaintBoundary(
//           child: MessageBubble(
//             style: bubbleStyle,
//             message: message,
//             isSelecting: isSelecting,
//             isSelected: isSelected,
//             isHighlighted: isHighlighted,
//             topPadding: info.topPadding,
//             bottomPadding: info.bottomPadding,
//             // interactions
//             onSwipe: () {
//               ref.read(overlayHandlerProvider).showReplyAnchor(context); // show hidden
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 ref.read(chatStateController.notifier).setAnchorMessage(message, context); // trigger slide
//               });
//             },
//             onTapWhileSelecting: () => isSelected
//                 ? ref.read(chatStateController.notifier).unselectMessage(message)
//                 : ref.read(chatStateController.notifier).selectMessage(message),
//             onTap: () async {
//               if (message.isImage) {
//                 final allImages = ref.read(chatStateController).messages.imageMedias;
//                 final initialIndex = allImages.indexOfMediaIsarID(message);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => GalleryViewWrapper(
//                       galleryItems: allImages,
//                       initialIndex: initialIndex,
//                       showOptions: true,
//                       options: galleryOptions,
//                       onOptionSelect: (value) => handleGalleryOptions(context, ref, value, allImages[initialIndex]),
//                     ),
//                   ),
//                 );
//               } else if (message.isDocument) {
//                 await OpenFile.open(message.media!.value!.path!);
//               } else {
//                 ref.read(chatStateController.notifier).toggleSender(message);
//               }
//             },
//             onLongPress: (pos) {
//               final notifier = ref.read(chatStateController.notifier);
//               notifier.selectMessage(message);
//               notifier.searchFocusNode.unfocus();
//               notifier.keyboardFocusNode.unfocus();
//               CustomContextMenu.showMenuAt(
//                 context,
//                 position: pos,
//                 menuItems: messageHoldOptions(isImage: (message.isImage || message.isDocument || message.isAudio) ),
//                 triangleHorizontalOffset: message.isSender ? 120 : 40,
//                 onSelected: (val) => notifier.handleMessageMenuAction(val, message, context),
//               );
//             },
//             onReplyTap: () => ref.read(chatStateController.notifier).scrollToMessage(message.replyingTo.value!.isarId),
//           ),
//         ),
//       ],
//     );
//   }
// }


// class LoadIndicator extends StatelessWidget {
//   const LoadIndicator({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.topCenter, // 👈 top center instead of center
//       child: Padding(
//         padding: const EdgeInsets.only(top: 50), // optional spacing from top
//         child: SizedBox(
//           height: 40,
//           width: 40,
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             strokeCap: StrokeCap.round,
//             color: context.isLight
//                 ? ThemeConstants.sacredSeed
//                 : ThemeConstants.sinisterSeed,
//           ),
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:notesapp/core/Theme/theme_constants.dart';
// import 'package:notesapp/core/extensions/context_extensions.dart';
// import 'package:notesapp/core/extensions/message_extensions.dart';
// import 'package:notesapp/root/data/enums/bubble_style.dart';
// import 'package:notesapp/root/data/enums/media_type.dart';
// import 'package:notesapp/root/data/models/message_model.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/ripple_well.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/swipable.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/message_content_builder.dart';
// import 'package:notesapp/root/screens/Chat_screen/widgets/components/reply_wrapper.dart';
// import 'package:notesapp/root/widgets/glass_container.dart';

// class MessageBubble extends StatefulWidget {
//   final Message message;

//   /// Selection state
//   final bool isSelecting;
//   final VoidCallback? onTapWhileSelecting;

//   /// Dismissible
//   final Widget? dismissBackground;
//   final void Function()? onSwipe;

//   /// RippleWell props
//   final void Function()? onTap;
//   final void Function()? onReplyTap;
//   final void Function(Offset)? onLongPress;
//   final BorderRadius? rippleBorderRadius;
//   final Color? rippleColor;

//   /// GlassContainer props
//   final double blurX;
//   final double blurY;
//   final double borderRadius;
//   final double borderWidth;
//   final Color borderColor;
//   final Color? backgroundColor;
//   final EdgeInsetsGeometry? padding;
//   final double? width;
//   final double? height;
//   final double? topPadding;
//   final double? bottomPadding;

//   /// Style
//   final BubbleStyle style;
//   final bool? isHighlighted;
//   final bool? isSelected; 

//   const MessageBubble({
//     super.key,
//     required this.message,
//     this.style = BubbleStyle.opaque,
//     this.isSelecting = false,
//     this.onTapWhileSelecting,
//     this.dismissBackground,
//     this.onSwipe,
//     this.onTap,
//     this.onLongPress,
//     this.rippleBorderRadius,
//     this.rippleColor,
//     this.blurX = 25,
//     this.blurY = 25,
//     this.borderRadius = 15,
//     this.borderWidth = 1.0,
//     this.borderColor = const Color.fromARGB(100, 255, 255, 255),
//     this.backgroundColor,
//     this.padding,
//     this.width,
//     this.height,
//     this.topPadding = 5,
//     this.bottomPadding = 5,
//     this.onReplyTap,
//     this.isHighlighted = false,
//     this.isSelected = false,
//   });

//   @override
//   State<MessageBubble> createState() => _MessageBubbleState();
// }

// class _MessageBubbleState extends State<MessageBubble> with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => (widget.message.media?.value?.type != Mediatype.audio) ?? true;
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     final bubblePadding = _getDefaultPadding();
//     final bubbleColor = _getBubbleColor(context);
//     final glassColor = _getGlassColor();

//     Widget styleBuilder(BubbleStyle style) {
//       return switch (style) {
//         BubbleStyle.glass => glassBubble(
//           glassColor: glassColor,
//           glassPadding: bubblePadding,
//         ),
//         BubbleStyle.opaque => opaqueBubble(
//           messageBubbleColor: bubbleColor,
//           bubblePadding: bubblePadding,
//           isHighlighted: widget.isHighlighted ?? false,
//         ),
//       };
//     }

//     return Swipeable(
//       isSender: widget.message.isSender,
//       isSelecting: widget.isSelecting,
//       onSwiped: widget.onSwipe,
//       child: Stack(
//         children: [
//           AnimatedAlign(
//             duration: Duration(milliseconds: 300),
//             curve: Curves.easeInOutQuint,
//             alignment:  widget.message.isSender ? Alignment.centerRight : Alignment.centerLeft,
//             child: AnimatedPadding(
//               duration: Duration(milliseconds: 300),
//             curve: Curves.easeInOutQuint,
//               padding: EdgeInsets.only(
//                 left: widget.message.isSender ? 45.0 : 8,
//                 right: widget.message.isSender ? 8 : 45,
//                 top: widget.topPadding ?? 5,
//                 bottom: widget.bottomPadding ?? 5,
//               ),
//               child: Column(
//                 crossAxisAlignment: widget.message.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                 children: [
//                   if (widget.message.replyingTo.value != null)
//                     ReplyWrapper(
//                       replyMessage: widget.message.replyingTo.value!,
//                       backgroundColor: Colors.blueGrey.withOpacity(context.isLight ? 0.1 : 0.07),
//                       iconColor: context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark,
//                       onTap: widget.onReplyTap ?? () {
//                         debugPrint("Reply tapped");
//                         final media = widget.message.replyingTo.value!.media.value;
//                         if (media != null) {
//                           debugPrint("Media path: ${media.path}");
//                         }
//                       },
//                     ),
//                   styleBuilder(widget.style),
//                 ],
//               ),
//             ),
//           ),

//           // Full-width selection overlay
//           if (widget.isSelecting)
//             Positioned.fill(
//               child: GestureDetector(
//                 onTap: widget.onTapWhileSelecting,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(vertical: 5),
//                   color: widget.isSelected ?? false
//                       ? Colors.blue.withValues(alpha: 0.2)
//                       : Colors.transparent,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ------------------------
//   EdgeInsets _getDefaultPadding() {
//     return widget.message.isImage
//         ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
//         : widget.message.isDocument ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 15, vertical: 10);
//   }

//   Color _getBubbleColor(BuildContext context) {
//     return widget.message.isSender
//         ? (context.isLight
//             ? ThemeConstants.senderBlue
//             : ThemeConstants.senderBlueDark)
//         : (context.isLight
//             ? ThemeConstants.hometoolbarLight3
//             : ThemeConstants.darkIconBorder);
//   }

//   Color _getHighlightedBubbleColor(BuildContext context) {
//     return widget.message.isSender
//         ? (context.isLight
//             ? const Color(0xFFF5FBFF)
//             : const Color(0xFF5A9CC0))
//         : (context.isLight
//             ? const Color(0xFFFFFFFF)
//             : const Color(0xFF677F8D));
//   }

//   Color _getGlassColor() {
//     return widget.message.isSender
//         ? Colors.blue.withValues(alpha: 0.15)
//         : Colors.white.withValues(alpha: 0.15);
//   }

//   // ------------------------
//   Widget opaqueBubble({
//     required Color messageBubbleColor,
//     required EdgeInsets bubblePadding,
//     required bool isHighlighted,
//   }) {
//     return RippleWell(
//           borderRadius: widget.rippleBorderRadius ?? BorderRadius.circular(widget.borderRadius),
//           materialColor: messageBubbleColor,
//           onTap: widget.isSelecting ? widget.onTapWhileSelecting : widget.onTap,
//           onLongPress: widget.onLongPress,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(widget.borderRadius),
//               color: isHighlighted ? _getHighlightedBubbleColor(context) : Colors.transparent,
//               boxShadow: [
//                  BoxShadow(
//                   color: Colors.white.withOpacity(
//                     isHighlighted ? (context.isLight ? 0.9 : 0.3) : 0.0,
//                   ),
//                   blurRadius: 16,
//                   spreadRadius: 2,
//                 ),
//               ],
//               // border: Border.all( // width: isHighlighted ? 1.5 : 0, // color: isHighlighted ? Colors.white : Colors.transparent, // ),
//             ),
//             child: Padding(
//         padding: bubblePadding,
//         child: MessageContentBuilder(message: widget.message), // <— use cached child
//           ),
//         )
//     );
//   }

//   Widget glassBubble({required Color glassColor, required EdgeInsets glassPadding}) {
//     return RippleWell(
//       borderRadius: widget.rippleBorderRadius ?? BorderRadius.circular(widget.borderRadius),
//       materialColor: widget.rippleColor,
//       onTap: widget.isSelecting ? widget.onTapWhileSelecting : widget.onTap,
//       onLongPress: widget.onLongPress,
//       child: GlassContainer(
//         blurX: widget.blurX,
//         blurY: widget.blurY,
//         borderRadius: widget.borderRadius,
//         borderWidth: widget.borderWidth,
//         borderColor: widget.borderColor,
//         backgroundColor: widget.backgroundColor ?? glassColor,
//         padding: glassPadding,
//         width: widget.width,
//         height: widget.height,
//         child: MessageContentBuilder(message: widget.message),
//       ),
//     );
//   }
// }



// import 'dart:io';
// import 'package:extended_image/extended_image.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:notesapp/core/Theme/theme_constants.dart';
// import 'package:notesapp/core/extensions/context_extensions.dart';
// import 'package:notesapp/core/utils/global_keys.dart';
// import 'package:notesapp/core/utils/utils.dart';
// import 'package:notesapp/root/data/enums/media_type.dart';
// import 'package:notesapp/root/data/models/message_model.dart';
// import 'package:notesapp/root/widgets/voice_message/components/voice_controller.dart';
// import 'package:notesapp/root/widgets/voice_message/components/voice_message_view.dart';
// import 'package:typeset/typeset.dart';

// class MessageContentBuilder extends StatelessWidget {
//   final Message message;

//   const MessageContentBuilder({super.key, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     if (message.media.value == null || message.media.value!.type == Mediatype.text) {
//       return _buildTextWithTimestamp();
//     }

//     switch (message.media.value?.type) {
//       case Mediatype.text:
//         return _buildTextWithTimestamp();
//       case Mediatype.image:
//         return RepaintBoundary(child: _buildImageWithOverlay());
//       case Mediatype.video:
//         return _buildVideoMessage();
//       case Mediatype.audio:
//         return _buildAudioMessage();
//       case Mediatype.document:
//         return _buildDocumentMessage();
//       default:
//         return const SizedBox.shrink();
//     }
//   }

//   /// TEXT MESSAGE + timestamp
//   Widget _buildTextWithTimestamp() {
//     return IntrinsicWidth(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Flexible(
//                 child: TypeSet(
//                   message.text,
//                   style: const TextStyle(fontSize: 20),
//                   softWrap: true,
//                   monospaceStyle: TextStyle(
//                     fontFamily: "Consolas",
//                     backgroundColor: ThemeConstants.iconColorNeutral.withValues(
//                       alpha: navigatorKey.currentContext!.isLight ? 0.2 : 0.5,
//                     ),
//                   ),
//                   linkRecognizerBuilder: (linkText, url) {
//                       return TapGestureRecognizer()
//                         ..onTap = () {
//                           debugPrint('URL: $url and Text: $linkText');
//                         };
//                     },
//                 ),
//               ),
//             ],
//           ),
//           Align(
//             alignment: Alignment.bottomRight,
//             child: Text(
//               DateFormat.jm().format(message.time),
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: ThemeConstants.subtitleLight,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// IMAGE MESSAGE + gradient overlay + timestamp
//   Widget _buildImageWithOverlay() {
//     final media = message.media.value;

//     if (media == null || media.path == null) {
//       return const SizedBox(
//         width: 100,
//         height: 100,
//         child: Center(child: Icon(Icons.broken_image)),
//       );
//     }

//     final file = File(media.path!);

//     // 🔑 Detect GIF by extension
//     final ext = (media.extension ?? "").toLowerCase();
//     if (ext == "gif") {
//       return _buildGifMessage();
//     }

//     final maxHeight = ThemeConstants.screenHeight * 0.5;
//     final maxWidth = ThemeConstants.screenWidth * 0.7;

//     // Use stored aspect ratio, fallback to 1 if null
//     final aspectRatio = media.aspectRatio ?? 1.0;

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(6),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxHeight: maxHeight,
//           maxWidth: maxWidth,
//           ),
//         child: AspectRatio(
//           aspectRatio: aspectRatio,
//           child: Stack(
//             alignment: Alignment.bottomRight,
//             children: [
//               // Image.file(file, fit: BoxFit.cover),
//               ExtendedImage.file(
//                 file,
//                 fit: BoxFit.cover,
//                 cacheHeight: maxHeight.toInt(), // 🔑 downsample at decode
//                 cacheWidth: maxWidth.toInt(), // 🔑 downsample at decode
//                 clearMemoryCacheIfFailed: true,
//                 gaplessPlayback: true,
//                 cacheRawData: true, // 🔥 memory + disk caching
//                 clearMemoryCacheWhenDispose: false,
//                 compressionRatio: 0.5,
//               ),
//               Container(
//                 height: 50,
//                 alignment: Alignment.bottomRight,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withAlpha(0),
//                       Colors.black.withAlpha(255),
//                     ],
//                   ),
//                 ),
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text(
//                   DateFormat.jm().format(message.time),
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: ThemeConstants.subtitleLight,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildGifMessage() {
//     final media = message.media.value;
//     if (media == null || media.path == null) return const SizedBox();

//     return IntrinsicWidth(
//       child: Column(
//         spacing: 5,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(6),
//             child: Image.file(
//               File(media.path!),
//               fit: BoxFit.contain,
//               gaplessPlayback: true, // keeps playing
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text("GIF", style: const TextStyle(
//                   fontSize: 12,
//                   color: ThemeConstants.subtitleLight,
//                 ),),
//               Text(
//                 DateFormat.jm().format(message.time),
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: ThemeConstants.subtitleLight,
//                 ),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }


//   Future<double> _getImageAspectRatio(File file) async {
//     final image = await decodeImageFromList(file.readAsBytesSync());
//     return image.width / image.height;
//   }

//   Widget _buildAudioMessage() {
//     debugPrint("Voice message built");
//     final bool isLight = navigatorKey.currentContext!.isLight;
//     final bool isSender = message.isSender;
//     final Color bgColor =
//         isSender
//             ? (isLight
//                 ? ThemeConstants.senderBlue
//                 : ThemeConstants.senderBlueDark)
//             : (isLight
//                 ? ThemeConstants.hometoolbarLight3
//                 : ThemeConstants.darkIconBorder);

//     // VoiceController controller = VoiceController(
//     //     audioSrc: message.media.value!.path!,
//     //     maxDuration: Duration(minutes: 1),
//     //     noiseCount: 35,
//     //     isFile: true,
//     //     onComplete: () {},
//     //     onPause: () {},
//     //     onPlaying: () {},
//     //   );

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.end,
//       children: [
//         VoiceMessageView(
//           // controller: controller,
//           audioSrc: message.media.value!.path!,
//           isFile: true,
//           innerPadding: 0,
//           backgroundColor: Colors.transparent, // bgColor,
//           circlesColor: ThemeConstants.sinisterSeed,
//           activeWaveColor: ThemeConstants.sinisterSeed,
//           inactiveWaveColor: ThemeConstants.iconColorNeutral,
//           showDuration: true,
//           showSentTime: true,
//           sentTime: message.time,
//         ),
        
//       ],
//     );
//   }

//   Widget _buildVideoMessage() => const Icon(Icons.video_call);

//   Widget _buildDocumentMessage() {
//     const TextStyle subStyle = TextStyle(color: ThemeConstants.iconColorNeutral, fontSize: 13);
//     return IntrinsicWidth(
//     child: Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
//           decoration: BoxDecoration(
//             color: const Color(0x0F000000),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   const Icon(Icons.insert_drive_file, color: Colors.red),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Column(
//                       children: [
//                         Text(
//                           message.media.value?.name ?? "Unknown file",
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 2,
//                         ),
//                         SizedBox(height: 5),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             // FutureBuilder to show file size
//                             if (message.media.value?.path != null)
//                               FutureBuilder<String>(
//                                 future: Utils.getFileSize(
//                                   message.media.value!.path!,
//                                 ),
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==  ConnectionState.waiting) {
//                                     return const Text('Loading size...', style: subStyle,);
//                                   } else if (snapshot.hasError) {
//                                     return const Text('Size unknown', style: subStyle,);
//                                   } else {
//                                     return Text(snapshot.data ?? '', style: subStyle,);
//                                   }
//                                 },
//                               ),
                            
//                             Text(message.media.value?.extension.toUpperCase() ?? "", style: subStyle),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 10)
//                 ],
//               ),
//             ],
//           ),
//         ),
        
//         const SizedBox(height: 3),
//         Align(
//           alignment: Alignment.bottomRight,
//           child: Padding(
//             padding: const EdgeInsets.only(right: 8.0),
//             child: Text(
//               DateFormat.jm().format(message.time),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: ThemeConstants.subtitleLight,
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );}
// }


// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:notesapp/core/Theme/theme_constants.dart';
// import 'package:notesapp/core/extensions/context_extensions.dart';
// import 'package:notesapp/root/widgets/voice_message/components/helpers/custom_track_shape.dart';
// import 'package:notesapp/root/widgets/voice_message/components/helpers/play_status.dart';
// import 'package:notesapp/root/widgets/voice_message/components/helpers/utils.dart';
// import 'package:notesapp/root/widgets/voice_message/components/voice_controller.dart';
// import 'package:notesapp/root/widgets/voice_message/components/widgets/noises.dart';
// import 'package:notesapp/root/widgets/voice_message/components/widgets/play_pause_button.dart';

// /// VoiceMessageView now owns the VoiceController lifecycle.
// /// Create one controller per view in initState and dispose it in dispose().
// class VoiceMessageView extends StatefulWidget {
//   const VoiceMessageView({
//     super.key,
//     required this.audioSrc,
//     required this.isFile,
//     this.backgroundColor = Colors.white,
//     this.activeWaveColor = Colors.red,
//     this.inactiveWaveColor,
//     this.circlesColor = Colors.red,
//     this.innerPadding = 12,
//     this.cornerRadius = 20,
//     this.size = 38,
//     this.refreshIcon = const Icon(
//       Icons.refresh,
//       color: Colors.white,
//     ),
//     this.pauseIcon = const Icon(
//       Icons.pause_rounded,
//       color: Colors.white,
//     ),
//     this.playIcon = const Icon(
//       Icons.play_arrow_rounded,
//       color: Colors.white,
//     ),
//     this.stopDownloadingIcon = const Icon(
//       Icons.close,
//       color: Colors.white,
//     ),
//     this.playPauseButtonDecoration,
//     this.circlesTextStyle = const TextStyle(
//       color: Colors.white,
//       fontSize: 10,
//       fontWeight: FontWeight.bold,
//     ),
//     this.counterTextStyle = const TextStyle(
//       fontSize: 11,
//       fontWeight: FontWeight.w500,
//     ),
//     this.playPauseButtonLoadingColor = Colors.white,
//     this.noiseCount = 35,
//     this.showDuration = true,
//     this.showSentTime = true,
//     this.sentTime,
//   });

//   final String audioSrc;
//   final bool isFile;
//   final Color backgroundColor;
//   final Color circlesColor;
//   final Color activeWaveColor;
//   final Color? inactiveWaveColor;
//   final TextStyle circlesTextStyle;
//   final TextStyle counterTextStyle;
//   final double innerPadding;
//   final double cornerRadius;
//   final double size;
//   final Widget refreshIcon;
//   final Widget pauseIcon;
//   final Widget playIcon;
//   final Widget stopDownloadingIcon;
//   final Decoration? playPauseButtonDecoration;
//   final Color playPauseButtonLoadingColor;
//   final int noiseCount;
//   final bool? showDuration;
//   final bool? showSentTime;
//   final DateTime? sentTime;

//   @override
//   State<VoiceMessageView> createState() => _VoiceMessageViewState();
// }

// class _VoiceMessageViewState extends State<VoiceMessageView> with TickerProviderStateMixin {
//   late VoiceController controller;

//   @override
//   void initState() {
//     super.initState();

//     // Create the controller once and dispose it when the widget is removed.
//     controller = VoiceController(
//       audioSrc: widget.audioSrc,
//       maxDuration: Duration.zero, // will be set in init()
//       isFile: widget.isFile,
//       noiseCount: widget.noiseCount,
//       onComplete: () {
//         // update UI or callbacks if needed
//         if (mounted) setState(() {});
//       },
//       onPause: () {
//         if (mounted) setState(() {});
//       },
//       onPlaying: () {
//         if (mounted) setState(() {});
//       },
//       onError: (err) {
//         // handle error if necessary
//       },
//     );
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final color = widget.circlesColor;

//     final newTheme = theme.copyWith(
//       sliderTheme: SliderThemeData(
//         trackShape: CustomTrackShape(),
//         thumbShape: SliderComponentShape.noThumb,
//         minThumbSeparation: 0,
//       ),
//       splashColor: Colors.transparent,
//     );

//     final timeStyle = const TextStyle(
//       height: 1,
//       fontSize: 12,
//       color: ThemeConstants.subtitleLight,
//     );

//     final bool showBothTimes = widget.showDuration == true && widget.showSentTime == true;
//     final bool showEither = widget.showDuration == true || widget.showSentTime == true;
//     final maxWidth = 130 + (controller.noiseCount * .72.width());

//     return Container(
//       width: maxWidth,
//       padding: EdgeInsets.all(widget.innerPadding),
//       decoration: BoxDecoration(
//         color: widget.backgroundColor,
//         borderRadius: BorderRadius.circular(widget.cornerRadius),
//       ),
//       child: ValueListenableBuilder(
//         valueListenable: controller.updater,
//         builder: (context, value, child) {
//           final playPauseButton = PlayPauseButton(
//             controller: controller,
//             color: color,
//             loadingColor: widget.playPauseButtonLoadingColor,
//             size: widget.size * (1.2),
//             refreshIcon: widget.refreshIcon,
//             pauseIcon: widget.pauseIcon,
//             playIcon: widget.playIcon,
//             stopDownloadingIcon: widget.stopDownloadingIcon,
//             buttonDecoration: widget.playPauseButtonDecoration,
//           );

//           final mainRow = Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Align(
//                 alignment: showBothTimes ? Alignment.topCenter : Alignment.center,
//                 child: ClipOval(child: playPauseButton),
//               ),
//               Flexible(child: _noises(newTheme)),
//               _changeSpeedButton(color),
//             ],
//           );

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               mainRow,
//               SizedBox(
//                 height: showEither ? 10 : 0,
//                 width: maxWidth - (widget.size * 1.2),
//                 child: Row(
//                   mainAxisAlignment: showBothTimes ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
//                   children: [
//                     if (widget.showDuration ?? true) Text(
//                       controller.remainingTime,
//                       style: timeStyle,
//                     ),
//                     if (widget.showSentTime ?? true) Text(
//                       DateFormat.jm().format(widget.sentTime ?? DateTime.now()),
//                       style: timeStyle,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _noises(ThemeData newTheme) => SizedBox(
//     height: 40,
//     width: controller.noiseWidth,
//     child: Stack(
//       alignment: Alignment.center,
//       children: [
//         AnimatedBuilder(
//           animation: CurvedAnimation(
//             parent: controller.animController,
//             curve: Curves.ease,
//           ),
//           builder: (context, child) {
//             final playedFraction = (controller.animController.value / controller.noiseWidth).clamp(0.0, 1.0);

//             return ShaderMask(
//               blendMode: BlendMode.srcATop,
//               shaderCallback: (rect) {
//                 return LinearGradient(
//                   begin: Alignment.centerLeft,
//                   end: Alignment.centerRight,
//                   stops: [playedFraction, playedFraction],
//                   colors: [
//                     widget.activeWaveColor, // played
//                     widget.inactiveWaveColor ?? widget.backgroundColor.withOpacity(.4), // unplayed
//                   ],
//                 ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
//               },
//               child: Center(
//                 child: Noises(
//                   rList: controller.randoms ?? [],
//                   activeSliderColor: Colors.white, // placeholder for ShaderMask
//                 ),
//               ),
//             );
//           },
//         ),
//         // Invisible Slider on top to detect gestures
//         Opacity(
//           opacity: 0,
//           child: SizedBox(
//             width: controller.noiseWidth,
//             child: Theme(
//               data: newTheme,
//               child: Slider(
//                 value: controller.currentMillSeconds,
//                 max: controller.maxMillSeconds,
//                 onChangeStart: controller.onChangeSliderStart,
//                 onChanged: controller.onChanging,
//                 onChangeEnd: (value) {
//                   controller.onSeek(Duration(milliseconds: value.toInt()));
//                   controller.play();
//                 },
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );

//   Widget _changeSpeedButton(Color color) => GestureDetector(
//     onTap: () {
//       controller.changeSpeed();
//     },
//     child: Container(
//       padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         controller.speed.playSpeedStr,
//         style: widget.circlesTextStyle,
//       ),
//     ),
//   );
// }

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:photo_view/photo_view.dart';

// class PhotoViewWrapper extends StatelessWidget {
//   const PhotoViewWrapper({
//     super.key,
//     required this.imagePath,
//     this.backgroundDecoration,
//     this.minScale,
//     this.maxScale,
//   });

//   final String imagePath;
//   final BoxDecoration? backgroundDecoration;
//   final dynamic minScale;
//   final dynamic maxScale;

//   /// Extracts just the file name from the full path
//   String get fileName => imagePath.split(Platform.pathSeparator).last;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.black12,
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(
//             Icons.arrow_back_ios_new_rounded,
//             color: Colors.white,
//           ),
//         ),
//       ),
//       body: PhotoView(
//         imageProvider: FileImage(File(imagePath)),
//         backgroundDecoration: backgroundDecoration,
//         initialScale: PhotoViewComputedScale.contained,      // Original size
//         minScale: PhotoViewComputedScale.contained * 0.9,    // 70% of original
//         maxScale: PhotoViewComputedScale.covered * 2.0,      // Example max zoom
//         heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
//       ),
//       bottomNavigationBar: Container(
//         height: 100,
//         color: Colors.black12,
//         alignment: Alignment.center,
//         child: Text(
//           fileName,
//           style: const TextStyle(color: Colors.white),
//         ),
//       ),
//     );
//   }
// }


// import 'dart:io';
// import 'package:extended_image/extended_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:notesapp/core/Theme/theme_constants.dart';
// import 'package:notesapp/core/utils/context_menu_options.dart';
// import 'package:notesapp/core/utils/time_format.dart';
// import 'package:notesapp/root/data/models/media_model.dart';
// import 'package:notesapp/root/data/models/message_model.dart';
// import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
// import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
// import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier_o.dart';
// import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';

// class GalleryViewWrapper extends StatefulWidget {
//   const GalleryViewWrapper({
//     super.key,
//     required this.galleryItems,
//     this.initialIndex = 0,
//     this.backgroundDecoration,
//     this.chatTitle,
//     this.isCamera = false,
//     this.onSendImage,
//     this.showOptions = true,
//     this.options,
//     this.onOptionSelect,
//   });

//   final List<Media> galleryItems;
//   final int initialIndex;
//   final BoxDecoration? backgroundDecoration;
//   final String? chatTitle;
//   final bool? isCamera;
//   final VoidCallback? onSendImage;
//   final bool? showOptions;
//   final List<PopupMenuEntry<String>>? options;
//   final Function(String value)? onOptionSelect;


//   @override
//   State<GalleryViewWrapper> createState() => _GalleryViewWrapperState();
// }

// class _GalleryViewWrapperState extends State<GalleryViewWrapper> {
//   late final PageController _pageController;
//   late int currentIndex;
//   bool showOverlay = true;
//   final Color overlayBase = Colors.black26;

//   @override
//   void initState() {
//     super.initState();
//     currentIndex = widget.initialIndex;
//     _pageController = PageController(initialPage: widget.initialIndex);

//     // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   }

//   @override
//   void dispose() {
//     // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // Or SystemUiMode.manual with desired overlays
//     super.dispose();
//   }

//   toggleOverlay() {
//     setState(() {
//       showOverlay = !showOverlay;
//     });

//     // if (showOverlay) {
//     //   // Show status bar
//     //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     // } else {
//     //   // Hide status bar
//     //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
//     // }
//   }

//   /// Get the time from the first linked message (backlink)
//   DateTime? get currentImageTime {
//     final media = widget.galleryItems[currentIndex];
//     return media.messagesBacklink.isNotEmpty
//         ? media.messagesBacklink.first.time
//         : null;
//   }

//   String? get currentChatTitle {
//   final media = widget.galleryItems[currentIndex];
//   if (media.messagesBacklink.isEmpty) return null;
//   final chat = media.messagesBacklink.first.chat.value;
//   return chat?.title;
// }

//   /// Get path for a given index
//   String? mediaPath(int index) => widget.galleryItems[index].path;

//   /// Get file name
//   String get currentFileName {
//     final path = mediaPath(currentIndex);
//     return path != null ? path.split(Platform.pathSeparator).last : "📷 Photo";
//   }

//   @override
//   Widget build(BuildContext context) {

//     return SafeArea(
//       child: Scaffold(
//         extendBodyBehindAppBar: true,
//         extendBody: true,
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(kToolbarHeight),
//           child: IgnorePointer(
//             ignoring: !showOverlay,
//             child: AnimatedOpacity(
//               duration: const Duration(milliseconds: 300),
//               opacity: showOverlay ? 1.0 : 0.0,
//               child: AppBar(
//                 backgroundColor: overlayBase,
//                 leading: IconButton(
//                   onPressed: () {
//                     if (showOverlay) Navigator.pop(context);
//                   },
//                   icon: const Icon(
//                     Icons.arrow_back_ios_new_rounded,
//                     color: Colors.white,
//                   ),
//                 ),
//                 title: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (currentChatTitle != null)
//                       Text(
//                         currentChatTitle!,
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     if (currentImageTime != null)
//                       Text(
//                         TimeFormat.imageTime(currentImageTime!),
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                         ),
//                       ),
//                   ],
//                 ),
//                 actions:
//                     widget.showOptions == true
//                         ? [
//                           CustomContextMenu(
//                             backgroundColor: const Color.fromARGB(255, 13, 24, 30),
//                             icon: const Icon(
//                               Icons.more_vert,
//                               color: Colors.white,
//                             ),
//                             menuItems: widget.options ?? galleryOptions,
//                             onSelected: widget.onOptionSelect ?? (value) =>  debugPrint(value),
//                           ),
//                         ]
//                         : [],
//               ),
//             ),
//           ),
//         ),
//         body: GestureDetector(
//           onTap: toggleOverlay,// () => setState(() => showOverlay = !showOverlay),
//           child: PhotoViewGallery.builder(
//             scrollPhysics: const BouncingScrollPhysics(),
//             itemCount: widget.galleryItems.length,
//             pageController: _pageController,
//             onPageChanged: (index) => setState(() => currentIndex = index),
//             builder: (context, index) {
//               final path = mediaPath(index);
//               return PhotoViewGalleryPageOptions(
//                 imageProvider: ExtendedFileImageProvider(File(path!), cacheRawData: true), // FileImage(File(path!)),
//                 heroAttributes: PhotoViewHeroAttributes(tag: path),
//                 minScale: PhotoViewComputedScale.contained * 0.9,
//                 maxScale: PhotoViewComputedScale.covered * 2.0,
//                 initialScale: PhotoViewComputedScale.contained,
                
//               );
//             },
//             loadingBuilder:
//                 (context, event) => Center(
//                   child: SizedBox(
//                     width: 30,
//                     height: 30,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       value:
//                           event == null
//                               ? 0
//                               : event.cumulativeBytesLoaded /
//                                   (event.expectedTotalBytes ?? 1),
//                     ),
//                   ),
//                 ),
//             backgroundDecoration:
//                 widget.backgroundDecoration ??
//                 const BoxDecoration(color: Colors.black),
//           ),
//         ),
//         bottomNavigationBar: AnimatedOpacity(
//           duration: const Duration(milliseconds: 300),
//           opacity: showOverlay ? 1.0 : 0.0,
//           child: Container(
//             constraints: const BoxConstraints(maxHeight: 70),
//             alignment: Alignment.center,
//             color: Colors.black26,
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: (widget.isCamera ?? false) ? 
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(currentFileName, style: TextStyle(color: Colors.white),),
//                           Consumer(
//                             builder: (context, ref, child) {
//                               return IconButton.filled(
//                                 onPressed: widget.onSendImage ?? () async => await _openPreviewAndRemoveCamera(context, widget.galleryItems[0], ref),
//                                 icon: Icon(
//                                   Icons.send,
//                                   color: ThemeConstants.sinisterSeed,
//                                   size: 30,
//                                 ),
//                               );
//                             }
//                           )
//                 ],
//               )
//                : Text(currentFileName, style: TextStyle(color: Colors.white),),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// Future<void> _openPreviewAndRemoveCamera(BuildContext context, Media media, WidgetRef ref) async {

//   final route = ModalRoute.of(context);
// if (route != null && Navigator.of(context).canPop()) {
//   Navigator.of(context).removeRouteBelow(route); // remove camera
// }

// // Pop first, then add the image
// if (Navigator.of(context).canPop()) {
//   Navigator.of(context).pop(); // pop back to chat
//   // Schedule pickImage after popping completes
//   Future.microtask(() async {
//     await ref.read(chatStateController.notifier).pickImage(media: media);
//   });
// }


//   // Optional: pick image
// }

