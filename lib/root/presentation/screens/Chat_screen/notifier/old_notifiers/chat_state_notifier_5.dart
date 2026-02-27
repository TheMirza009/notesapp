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
// import 'package:notesapp/core/extensions/message_extensions.dart';
// import 'package:notesapp/root/screens/Chat_Forward/chat_forward_screen.dart';
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

// final chatStateController = NotifierProvider<ChatStateNotifier, ChatState>(() => ChatStateNotifier());

// class ChatStateNotifier extends Notifier<ChatState> {
//   // ===== Dependencies =====
//   final _isar = IsarDatabase.isar;
  
//   // ===== Controllers =====
//   final TextEditingController searchController = TextEditingController();
//   final TypeSetEditingController keyboardController = TypeSetEditingController();
//   final FocusNode searchFocusNode = FocusNode();
//   final FocusNode keyboardFocusNode = FocusNode();
//   final ItemScrollController itemScrollController = ItemScrollController();
//   final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
//   final Recorder recorder = Recorder();
  
//   // ===== State =====
//   List<Message> _allMessages = []; // Source of truth
//   Chat? _chat;
//   bool _isHydrating = false;
//   Timer? _batchLoadTimer; // For progressive loading
  
//   // ===== Getters =====
//   bool get isLoading => _isHydrating;
//   bool get isReplying => state.anchorMessage != null;

//   @override
//   ChatState build() {
//     ref.keepAlive();
//     _initializeListeners();

//     final selectedChat = ref.watch(chatListProvider.select((s) => s.selectedChat));
//     if (selectedChat == null) return ChatState();

//     _chat = selectedChat;
    
//     // ✅ Defer hydration to next frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       hydrateMessagesOptimized();
//     });
    
//     return ChatState();
//   }

//   void _initializeListeners() {
//     keyboardFocusNode.addListener(() {
//       if (keyboardFocusNode.hasFocus) hideEmojiPicker();
//     });
//   }

//   // =====================================================
//   // OPTIMIZED MESSAGE LOADING
//   // =====================================================

//   /// ✅ Load messages progressively: visible first, rest in batches
//   Future<void> hydrateMessagesOptimized() async {
//     if (_chat == null || _isHydrating) return;
    
//     _isHydrating = true;
//     state = state.copyWith(isLoading: true);

//     try {
//       // Step 1: Get message IDs only (super fast)
//       final messageIds = await _isar.messages
//           .filter()
//           .chat((q) => q.isarIDEqualTo(_chat!.isarID))
//           .sortByTime() // Oldest first for chat display
//           .isarIdProperty()
//           .findAll();

//       if (messageIds.isEmpty) {
//         _allMessages = [];
//         _updateState(messages: _allMessages, isLoading: false);
//         _isHydrating = false;
//         return;
//       }

//       // Step 2: Load LAST 30 messages (visible on screen)
//       final visibleCount = messageIds.length > 30 ? 30 : messageIds.length;
//       final visibleIds = messageIds.skip(messageIds.length - visibleCount).toList();
      
//       final visibleMessages = await _loadMessageBatch(visibleIds);
      
//       _allMessages = visibleMessages;
//       _updateState(messages: _allMessages, isLoading: false);
//       _isHydrating = false;

//       // Step 3: Load remaining messages progressively
//       if (messageIds.length > 30) {
//         final remainingIds = messageIds.take(messageIds.length - 30).toList();
//         _loadRemainingMessagesInBatches(remainingIds);
//       }
//     } catch (e, stackTrace) {
//       debugPrint('❌ Error hydrating messages: $e');
//       debugPrint(stackTrace.toString());
//       _isHydrating = false;
//       _updateState(isLoading: false);
//     }
//   }

//   /// Load a batch of messages with media
//   Future<List<Message>> _loadMessageBatch(List<int> ids) async {
//     final messages = await _isar.messages.getAll(ids);
//     final validMessages = messages.whereType<Message>().toList();
    
//     // Load media in parallel
//     await Future.wait(
//       validMessages.map((m) => m.media.load().catchError((_) {})),
//       eagerError: false,
//     );
    
//     return validMessages;
//   }

//   /// Progressive loading in background
//   Future<void> _loadRemainingMessagesInBatches(List<int> remainingIds) async {
//     const batchSize = 50;
    
//     for (int i = 0; i < remainingIds.length; i += batchSize) {
//       // Cancel if chat changed
//       if (_chat == null) return;
      
//       // Delay to not block UI
//       await Future.delayed(const Duration(milliseconds: 150));
      
//       final batchIds = remainingIds.skip(i).take(batchSize).toList();
//       final batchMessages = await _loadMessageBatch(batchIds);
      
//       // Prepend older messages
//       _allMessages = [...batchMessages, ..._allMessages];
//       _updateState(messages: _allMessages);
//     }
//   }

//   // =====================================================
//   // CENTRALIZED STATE UPDATE
//   // =====================================================

//   /// ✅ Single method to update state - reduces redundancy
//   void _updateState({
//     List<Message>? messages,
//     bool? isLoading,
//     bool? isSearching,
//     bool? showEmojis,
//     bool? isRecording,
//     bool? isEditing,
//     Message? anchorMessage,
//     Message? highlightedMessage,
//     List<Message>? selectedMessages,
//   }) {
//     state = state.copyWith(
//       messages: messages,
//       isLoading: isLoading,
//       isSearching: isSearching,
//       showEmojis: showEmojis,
//       isRecording: isRecording,
//       isEditing: isEditing,
//       anchorMessage: anchorMessage,
//       highlightedMessage: highlightedMessage,
//       selectedMessages: selectedMessages,
//     );
//   }

//   // =====================================================
//   // OPTIMIZED MESSAGE OPERATIONS
//   // =====================================================

//   /// ✅ Generic media message creator - eliminates duplicate code
//   Future<void> _createMediaMessage({
//     required Media media,
//     required String emoji,
//     required String description,
//   }) async {
//     if (_chat == null) return;
//     await deleteInitMessage();

//     final persisted = await _persistMedia(media);
//     if (persisted == null) {
//       debugPrint('❌ Failed to persist media');
//       return;
//     }

//     final newMessage = Message()
//       ..text = "$emoji $description"
//       ..isSender = true
//       ..time = DateTime.now();

//     final created = await _createAndAttachMessage(
//       message: newMessage,
//       persistedMedia: persisted,
//       replyingTo: state.anchorMessage,
//     );

//     if (created != null) {
//       _allMessages.add(created);
//       _updateState(messages: [..._allMessages], anchorMessage: null);
//       scrollToBottom();
//     }
//   }

//   Future<void> pickImage({
//     Uint8List? imageBytes,
//     bool? isCamera = false,
//     Media? media,
//   }) async {
//     final pickedMedia = imageBytes != null
//         ? await MediaHandler.fromImageBytes(imageBytes)
//         : (media ?? await MediaHandler.pickImage(
//             source: (isCamera ?? false) ? ImageSource.camera : ImageSource.gallery,
//           ));

//     if (pickedMedia != null) {
//       await _createMediaMessage(
//         media: pickedMedia,
//         emoji: '📷',
//         description: 'Photo',
//       );
//     }
//   }

//   Future<void> pickDocument() async {
//     final pickedMedia = await MediaHandler.pickDocument();
//     if (pickedMedia != null) {
//       await _createMediaMessage(
//         media: pickedMedia,
//         emoji: '📃',
//         description: 'Document',
//       );
//     }
//   }

//   Future<void> pickAudio() async {
//     final pickedMedia = await MediaHandler.pickDocument(fileType: FileType.audio);
//     if (pickedMedia != null) {
//       await _createMediaMessage(
//         media: pickedMedia,
//         emoji: '🎧',
//         description: 'Audio',
//       );
//     }
//   }

//   // =====================================================
//   // MESSAGE CRUD WITH ERROR HANDLING
//   // =====================================================

//   Future<void> sendMessage(String text) async {
//     if (_chat == null || text.trim().isEmpty) return;
    
//     try {
//       await deleteInitMessage();

//       final newMessage = Message()
//         ..text = text.trim()
//         ..time = DateTime.now()
//         ..isSender = true;

//       final created = await _createAndAttachMessage(
//         message: newMessage,
//         persistedMedia: null,
//         replyingTo: state.anchorMessage,
//       );

//       if (created != null) {
//         _allMessages.add(created);
//         _updateState(messages: [..._allMessages], anchorMessage: null);
//         scrollToBottom();
//       }
//     } catch (e) {
//       debugPrint('❌ Error sending message: $e');
//       Utils.showGlobalSnackBar('Failed to send message', Colors.red);
//     }
//   }

//   Future<void> updateMessage(Message message) async {
//     try {
//       await _isar.writeTxn(() async {
//         final existing = await _isar.messages.get(message.isarId);
//         if (existing != null) {
//           existing.text = message.text;
//           existing.isSender = message.isSender;
//           await _isar.messages.put(existing);
//         } else {
//           await _isar.messages.put(message);
//         }
//       });

//       final index = _allMessages.indexWhere((m) => m.isarId == message.isarId);
//       if (index != -1) {
//         _allMessages[index] = message;
//         _updateState(messages: [..._allMessages]);
//       }
//     } catch (e) {
//       debugPrint('❌ Error updating message: $e');
//     }
//   }

//   Future<void> deleteMessage(Message message) async {
//     try {
//       final mediaRef = await _deleteMessageManaged(message);

//       // Check media usage and delete if not used
//       if (mediaRef != null && mediaRef.type != Mediatype.text) {
//         final usedByOthers = await _isMediaUsedByOthers(
//           mediaRef.path,
//           excludingMessageIsarId: message.isarId,
//         );

//         if (!usedByOthers) {
//           // Delete in background
//           compute(_backgroundDeleteMedia, mediaRef.path ?? '').catchError((_) {
//             MediaHandler.deleteMedia(mediaRef);
//           });
//         }
//       }

//       _allMessages.removeWhere((m) => m.isarId == message.isarId);
//       _updateState(messages: [..._allMessages], selectedMessages: []);
//     } catch (e) {
//       debugPrint('❌ Error deleting message: $e');
//       Utils.showGlobalSnackBar('Failed to delete message', Colors.red);
//     }
//   }

//   Future<void> deleteSelected() async {
//     final selected = state.selectedMessages;
//     if (selected.isEmpty) return;

//     try {
//       final mediaToCheck = <Media>[];

//       await _isar.writeTxn(() async {
//         for (final m in selected) {
//           final managedMsg = await _isar.messages.get(m.isarId);
//           if (managedMsg != null) {
//             await managedMsg.media.load().catchError((_) {});
//             if (managedMsg.media.value != null) {
//               mediaToCheck.add(managedMsg.media.value!);
//             }
//           }
//           await _isar.messages.delete(m.isarId);

//           if (_chat != null) {
//             final managedChat = await _isar.chats.get(_chat!.isarID);
//             if (managedChat != null) {
//               await managedChat.messages.load();
//               managedChat.messages.removeWhere((mm) => mm.isarId == m.isarId);
//               await managedChat.messages.save();
//               await _isar.chats.put(managedChat);
//               _chat = managedChat;
//             }
//           }
//         }
//       });

//       // Clean up unused media in background
//       for (final media in mediaToCheck) {
//         if (media.type != Mediatype.text) {
//           final usedByOthers = await _isMediaUsedByOthers(media.path);
//           if (!usedByOthers) {
//             compute(_backgroundDeleteMedia, media.path ?? '').catchError((_) {
//               MediaHandler.deleteMedia(media);
//             });
//           }
//         }
//       }

//       _allMessages.removeWhere((m) => selected.contains(m));
//       _updateState(messages: [..._allMessages], selectedMessages: []);
//     } catch (e) {
//       debugPrint('❌ Error deleting selected: $e');
//       Utils.showGlobalSnackBar('Failed to delete messages', Colors.red);
//     }
//   }

//   // =====================================================
//   // EDITING
//   // =====================================================

//   void startEditingTextMessage(Message message) {
//     cancelAudioRecording();
//     ref.read(overlayHandlerProvider).closeAllOverlays();
//     keyboardFocusNode.requestFocus();
//     keyboardController.text = message.text;
//     _updateState(
//       highlightedMessage: message,
//       isEditing: true,
//     );
//   }

//   void cancelEditing() {
//     keyboardController.clear();
//     keyboardFocusNode.unfocus();
//     _updateState(
//       isEditing: false,
//       highlightedMessage: null,
//       selectedMessages: [],
//     );
//   }

//   Future<void> editTextMessage(Message message, String newText) async {
//     if (message.isarId == 0 || newText.trim().isEmpty) return;

//     try {
//       await _isar.writeTxn(() async {
//         final managed = await _isar.messages.get(message.isarId);
//         if (managed != null) {
//           managed.text = newText.trim();
//           await _isar.messages.put(managed);
//         }
//       });

//       // Update in-memory list
//       final idx = _allMessages.indexWhere((m) => m.isarId == message.isarId);
//       if (idx != -1) {
//         final managedReload = await _isar.messages.get(message.isarId);
//         if (managedReload != null) {
//           await managedReload.media.load().catchError((_) {});
//           await managedReload.replyingTo.load().catchError((_) {});
//           _allMessages[idx] = managedReload;
//         }
//       }

//       _updateState(
//         messages: [..._allMessages],
//         isEditing: false,
//         highlightedMessage: null,
//         selectedMessages: [],
//       );
//     } catch (e) {
//       debugPrint('❌ Error editing message: $e');
//       Utils.showGlobalSnackBar('Failed to edit message', Colors.red);
//     }
//   }

//   // =====================================================
//   // RECORDING
//   // =====================================================

//   Future<void> startAudioRecording() async {
//     try {
//       await recorder.startRecording();
//       _updateState(isRecording: true, selectedMessages: []);
//     } catch (e) {
//       debugPrint('❌ Error starting recording: $e');
//       Utils.showGlobalSnackBar('Failed to start recording', Colors.red);
//     }
//   }

//   Future<void> cancelAudioRecording() async {
//     try {
//       ref.read(overlayHandlerProvider).hideRecordBar(instant: false);
//       await recorder.cancelRecording();
//       _updateState(isRecording: false);
//     } catch (e) {
//       debugPrint('❌ Error cancelling recording: $e');
//     }
//   }

//   Future<void> stopAudioRecording() async {
//     try {
//       final recordingPath = await recorder.stopRecording();
//       if (recordingPath == null) return;

//       final savedAudio = await MediaHandler.saveAudio(recordingPath);
//       if (savedAudio == null) return;

//       await _createMediaMessage(
//         media: savedAudio,
//         emoji: '🎙️',
//         description: 'Recording',
//       );
      
//       _updateState(isRecording: false);
//     } catch (e) {
//       debugPrint('❌ Error stopping recording: $e');
//       Utils.showGlobalSnackBar('Failed to save recording', Colors.red);
//     }
//   }

//   // =====================================================
//   // SEARCH
//   // =====================================================

//   void toggleSearch() {
//     final newSearching = !state.isSearching;
//     if (!newSearching) {
//       clearSearch();
//     } else {
//       searchController.clear();
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (searchFocusNode.canRequestFocus) searchFocusNode.requestFocus();
//       });
//     }
//     _updateState(isSearching: newSearching);
//   }

//   void clearSearch() {
//     searchController.clear();
//     _updateState(messages: [..._allMessages]);
//   }

//   void searchChats(String query) {
//     if (query.isEmpty) {
//       _updateState(messages: [..._allMessages]);
//       return;
//     }
    
//     final filtered = _allMessages
//         .where((m) => m.text.toLowerCase().contains(query.toLowerCase()))
//         .toList();
//     _updateState(messages: filtered);
//   }

//   void closeSearchAndKeyboard() {
//     if (state.isSearching) toggleSearch();
//     clearSearch();
//     keyboardFocusNode.unfocus();
//     hideEmojiPicker();
//   }

//   // =====================================================
//   // SELECTION & HIGHLIGHTING
//   // =====================================================

//   void selectMessage(Message message) {
//     state = state.selectMessage(message);
//   }

//   void unselectMessage(Message message) {
//     state = state.unselectMessage(message);
//   }

//   void unSelectAllMessages() {
//     if (!state.isEditing) {
//       state = state.clearSelection();
//     }
//   }

//   void selectAllMessages() {
//     _updateState(selectedMessages: [...state.messages]);
//   }

//   void highlightMessageTemporarily(Message message) {
//     _updateState(highlightedMessage: message);
//     Future.delayed(const Duration(milliseconds: 700), () {
//       if (state.highlightedMessage?.isarId == message.isarId) {
//         _updateState(highlightedMessage: null);
//       }
//     });
//   }

//   // =====================================================
//   // SCROLL
//   // =====================================================

//   void scrollToBottom() {
//     if (!itemScrollController.isAttached || state.messages.isEmpty) return;

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
//   // HELPER METHODS (unchanged but with error handling)
//   // =====================================================

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
//       _allMessages.add(newMessage);
//       state = state.copyWith(messages: [..._allMessages]);
//     }
//   }



//   Future<Media?> _persistMedia(Media media) async {
//     try {
//       await _isar.writeTxn(() async {
//         await _isar.medias.put(media);
//       });
//       return await _isar.medias.get(media.isarId);
//     } catch (e) {
//       debugPrint('❌ Error persisting media: $e');
//       return null;
//     }
//   }

//   Future<Message?> _createAndAttachMessage({
//     required Message message,
//     Media? persistedMedia,
//     Message? replyingTo,
//   }) async {
//     if (_chat == null) return null;

//     try {
//       await _isar.writeTxn(() async {
//         if (replyingTo != null) {
//           message.replyingTo.value = replyingTo;
//         }

//         await _isar.messages.put(message);

//         if (persistedMedia != null) {
//           message.media.value = persistedMedia;
//           await message.media.save();
//         }

//         Chat? managedChat = await _isar.chats.get(_chat!.isarID);
//         if (managedChat == null) {
//           await _isar.chats.put(_chat!);
//           managedChat = await _isar.chats.get(_chat!.isarID);
//         }

//         if (managedChat != null) {
//           await managedChat.messages.load();
//           managedChat.messages.add(message);
//           await managedChat.messages.save();
//           await _isar.chats.put(managedChat);
//           _chat = managedChat;
//         }

//         if (replyingTo != null) {
//           await message.replyingTo.save();
//         }
//       });

//       return message;
//     } catch (e) {
//       debugPrint('❌ Error creating message: $e');
//       return null;
//     }
//   }

//   Future<Media?> _deleteMessageManaged(Message message) async {
//     Media? mediaRef;
//     try {
//       await _isar.writeTxn(() async {
//         final managedMsg = await _isar.messages.get(message.isarId);
//         if (managedMsg != null) {
//           await managedMsg.media.load().catchError((_) {});
//           mediaRef = managedMsg.media.value;
//           await _isar.messages.delete(managedMsg.isarId);
//         }

//         if (_chat != null) {
//           final managedChat = await _isar.chats.get(_chat!.isarID);
//           if (managedChat != null) {
//             await managedChat.messages.load();
//             managedChat.messages.removeWhere((m) => m.isarId == message.isarId);
//             await managedChat.messages.save();
//             await _isar.chats.put(managedChat);
//             _chat = managedChat;
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint('❌ Error deleting message managed: $e');
//     }

//     return mediaRef;
//   }

//   Future<bool> _isMediaUsedByOthers(String? mediaPath, {int? excludingMessageIsarId}) async {
//     if (mediaPath == null) return false;
    
//     try {
//       final msgs = await _isar.messages.where().findAll();
//       for (final m in msgs) {
//         await m.media.load().catchError((_) {});
//       }
//       return msgs.hasDuplicateMediaPathByPath(
//         mediaPath,
//         excludingIsarId: excludingMessageIsarId,
//       );
//     } catch (e) {
//       debugPrint('❌ Error checking media usage: $e');
//       return false;
//     }
//   }

//   static Future<bool> _backgroundDeleteMedia(String path) async {
//     try {
//       if (path.isEmpty) return false;
//       final file = File(path);
//       if (await file.exists()) {
//         await file.delete();
//       }
//       return true;
//     } catch (e) {
//       debugPrint('❌ Error deleting media file: $e');
//       return false;
//     }
//   }

//   Future<void> deleteInitMessage() async {
//     if (_chat == null || state.messages.isEmpty) return;

//     const initID = "0000";
//     const initText = "This is a new chat. Start typing to create your first note.";

//     final firstMessage = state.messages.first;
//     if (firstMessage.id == initID &&
//         firstMessage.text == initText &&
//         !firstMessage.isSender &&
//         state.messages.length == 1) {
//       await deleteMessage(firstMessage);
//     }
//   }

//   // =====================================================
//   // UI HELPERS
//   // =====================================================

//   void toggleSender(Message message) async {
//     message.isSender = !message.isSender;
//     await updateMessage(message);
//   }

//   Future<void> setAnchorMessage(Message message, BuildContext context) async {
//     final overlayHandler = ref.read(overlayHandlerProvider);
//     _updateState(anchorMessage: message);
    
//     if (!keyboardFocusNode.hasFocus) {
//       keyboardFocusNode.requestFocus();
//     }

//     await overlayHandler.closeAttachmentBoard();
//     overlayHandler.showReplyAnchor(context);
//   }

//   void clearAnchorMessage() {
//     _updateState(anchorMessage: null);
//     keyboardFocusNode.unfocus();
//   }

//   void toggleEmojiPicker() {
//     if (state.showEmojis) {
//       _updateState(showEmojis: false);
//       keyboardFocusNode.requestFocus();
//     } else {
//       if (keyboardFocusNode.hasFocus) keyboardFocusNode.unfocus();
//       Future.delayed(const Duration(milliseconds: 100), () {
//         _updateState(showEmojis: true);
//       });
//     }
//   }

//   void hideEmojiPicker() {
//     if (state.showEmojis) _updateState(showEmojis: false);
//   }

//   void closeKeyboard() {
//     keyboardFocusNode.unfocus();
//     hideEmojiPicker();
//   }

//   void stopSearching() {
//     _updateState(isSearching: false);
//   }

//   // =====================================================
//   // CHAT MANAGEMENT
//   // =====================================================

//   Future<void> clearChat() async {
//     if (_chat == null) return;
    
//     try {
//       await _isar.writeTxn(() async {
//         await _chat!.messages.filter().deleteAll();
//         await _chat!.messages.save();
//         await _isar.chats.put(_chat!);
//       });
      
//       _allMessages = [];
//       state = ChatState();
//     } catch (e) {
//       debugPrint('❌ Error clearing chat: $e');
//       Utils.showGlobalSnackBar('Failed to clear chat', Colors.red);
//     }
//   }

//   Future<void> removeChatIfEmpty() async {
//     if (_chat == null) return;
    
//     try {
//       final managedChat = await _isar.chats.get(_chat!.isarID);
//       if (managedChat == null) return;
      
//       await managedChat.messages.load();

//       if (managedChat.messages.isEmpty) {
//         ref.read(chatListProvider.notifier).removeChat(managedChat);
//         return;
//       }

//       const initText = "This is a new chat. Start typing to create your first note.";
//       const initID = "0000";

//       final isInit = managedChat.messages.length == 1 &&
//           managedChat.messages.first.text == initText &&
//           managedChat.messages.first.id == initID;

//       if (isInit) {
//         ref.read(chatListProvider.notifier).removeChat(managedChat);
//       }
//     } catch (e) {
//       debugPrint('❌ Error checking empty chat: $e');
//     }
//   }

//   // =====================================================
//   // CONTEXT MENU ACTIONS
//   // =====================================================

//   void handleMessageMenuAction(String action, Message message, BuildContext? context) async {
//     switch (action) {
//       case 'deleteMessage':
//         await deleteMessage(message);
//       case 'edit':
//         startEditingTextMessage(message);
//       case 'reply':
//         unSelectAllMessages();
//         ref.read(overlayHandlerProvider).showReplyAnchor(
//           context ?? navigatorKey.currentContext!,
//         );
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           setAnchorMessage(message, context!);
//         });
//       case 'forward':
//         unSelectAllMessages();
//         Navigator.push(
//           navigatorKey.currentContext!,
//           CupertinoPageRoute(builder: (_) => ChatForwardScreen(message: message)),
//         );
//       case 'copy':
//         if (message.isImage) {
//           Utils.copyImageFromPath(message.media.value!.path);
//         } else {
//           Utils.copyTextToClipboard(message.text);
//         }
//         unSelectAllMessages();
//       case 'toggleSender':
//         toggleSender(message);
//         unSelectAllMessages();
//       case 'share':
//         await Utils.shareToApps(XFile(message.media.value!.path!));
//         unSelectAllMessages();
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
