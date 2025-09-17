import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
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
  @override
  ChatDetailState build() {
    final selectedChat = ref.watch(chatListProvider).selectedChat;
    return ChatDetailState(chat: selectedChat, photos: []);
  }

  Future<void> getPhotos() async {
    final chat = ref.read(chatListProvider).selectedChat;
    if (chat == null) return;

    await chat.messages.load();
    final photoMessages =
        chat.messages.where((m) => m.media.value?.type == Mediatype.image).toList();

    final photos = photoMessages.map((m) => m.media.value!).toList();
    state = state.copyWith(photos: photos, chat: chat);
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

}