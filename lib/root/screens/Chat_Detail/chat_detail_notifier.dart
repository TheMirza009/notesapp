import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';

class ChatDetailState {
  final Chat? chat;
  final List<Media> photos;
  final List<Media> documents;

  const ChatDetailState({this.chat, this.photos = const [], this.documents = const []});

  ChatDetailState copyWith({Chat? chat, List<Media>? photos, List<Media>? documents}) {
    return ChatDetailState(
      chat: chat ?? this.chat,
      photos: photos ?? this.photos,
      documents: documents ?? this.documents,
    );
  }

  factory ChatDetailState.initial() => const ChatDetailState();
}

class ChatDetailNotifier extends Notifier<ChatDetailState> {
  final Isar isar = IsarDatabase.isar;
  bool imageOpened = false;
  @override
  ChatDetailState build() {
    final selectedChat = ref.watch(chatListProvider).selectedChat;
    Future.microtask(() => getMedia());
    return ChatDetailState(chat: selectedChat, photos: []);
  }

  Future<void> getMedia() async {
    final chat = ref.read(chatListProvider).selectedChat;
    if (chat == null) return;

    // Reload the chat from Isar to guarantee it's fully managed
    final freshChat = await IsarDatabase.isar.chats.get(chat.isarID);
    if (freshChat == null) return;

    // Load messages + their media
    await freshChat.messages.load();
    await Future.wait(
      freshChat.messages.map((m) async {
        await m.media.load();
      }),
    );

    final photoMessages = freshChat.messages.where((m) => m.media.value?.type == Mediatype.image).toList();
    final documentMessages = freshChat.messages.where((m) => m.media.value?.type == Mediatype.document).toList();
    final photos = photoMessages.map((m) => m.media.value!).toList();
    final documents = documentMessages.map((m) => m.media.value!).toList();

    // Update state with managed chat and loaded photos
    state = state.copyWith(chat: freshChat, photos: photos, documents: documents);
  }

  Future<void> saveAndUpdateChatPhoto(Media media) async {
    if (state.chat == null) {
      debugPrint("⚠️ saveAndUpdateChatPhoto: No chat in state");
      return;
    }

    // Check if media already exists in Isar
    final existingMedia =
        await isar.medias.filter().pathEqualTo(media.path).findFirst();
    final mediaToUse = existingMedia ?? media;

    // Save media to Isar if new
    if (existingMedia == null) {
      await isar.writeTxn(() async {
        await isar.medias.put(mediaToUse);
      });
      debugPrint("💾 Media saved to Isar: ${mediaToUse.path}");
    } else {
      debugPrint("📂 Media already exists in Isar: ${mediaToUse.path}");
    }

    // Fetch managed chat from Isar
    final managedChat = await isar.chats.get(state.chat!.isarID);
    if (managedChat == null) {
      debugPrint("❌ saveAndUpdateChatPhoto: Chat not found in Isar");
      return;
    }

    // Update chat photo path
    await isar.writeTxn(() async {
      managedChat.chatPhotoPath = mediaToUse.path;
      await isar.chats.put(managedChat);
    });

    // Notify list provider & update local state
    ref.read(chatListProvider.notifier).refreshChat(managedChat.isarID);
    state = state.copyWith(chat: managedChat);

    debugPrint("🎉 Chat photo updated for ${managedChat.title}");
  }

  Future<void> updateChatPhoto() async {
    final pickedMedia = await MediaHandler.pickImage(isProfilePicture: true);
    if (pickedMedia == null || state.chat == null) return;

    // Check if this media already exists in DB by path
    final existingMedia = await isar.medias.filter().pathEqualTo(pickedMedia.path).findFirst();
    final mediaToUse = existingMedia ?? pickedMedia;

    // Persist only if it's new
    if (existingMedia == null) {
      await isar.writeTxn(() async {
        await isar.medias.put(mediaToUse);
      });
    }

    // Always re-fetch the managed chat from Isar
    final managedChat = await isar.chats.get(state.chat!.isarID);
    if (managedChat == null) return;

    // Update chat with new photo path
    await isar.writeTxn(() async {
      managedChat.chatPhotoPath = mediaToUse.path;
      await isar.chats.put(managedChat);
    });

    // Update state and provider
    ref.read(chatListProvider.notifier).refreshChat(managedChat.isarID);
    state = state.copyWith(chat: managedChat);
  }


  Future<void> updateTitle(String newTitle) async {
    final chat = ref.read(chatListProvider).selectedChat;
    if (chat == null) return;

    await IsarDatabase.isar.writeTxn(() async {
      chat.title = newTitle;
      await IsarDatabase.isar.chats.put(chat); // update managed chat
    });

    // update provider state with the same managed object (not a copy)
    ref.read(chatListProvider.notifier).refreshChat(chat.isarID);
    state = state.copyWith(chat: chat);
  }
  
  void openImage() {
    imageOpened = !imageOpened;
    state = state.copyWith();
  }
}
