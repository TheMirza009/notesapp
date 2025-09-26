import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_2.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_3.dart';

class ChatDetailState {
  final Chat? chat;
  final List<Media> photos;

  const ChatDetailState({this.chat, this.photos = const []});

  ChatDetailState copyWith({Chat? chat, List<Media>? photos}) {
    return ChatDetailState(
      chat: chat ?? this.chat,
      photos: photos ?? this.photos,
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
    Future.microtask(() => getPhotos());
    return ChatDetailState(chat: selectedChat, photos: []);
  }

  Future<void> getPhotos() async {
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

    final photoMessages =
        freshChat.messages
            .where((m) => m.media.value?.type == Mediatype.image)
            .toList();
    final photos = photoMessages.map((m) => m.media.value!).toList();

    // Update state with managed chat and loaded photos
    state = state.copyWith(chat: freshChat, photos: photos);
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
