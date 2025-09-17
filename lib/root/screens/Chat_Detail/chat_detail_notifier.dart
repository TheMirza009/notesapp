import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_2.dart';

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

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  ChatDetailNotifier() : super(ChatDetailState.initial());

  void init(Chat chat) {
    state = state.copyWith(chat: chat);
    getPhotos();
  }

  Future<void> getPhotos() async {
    if (state.chat == null) return;

    await state.chat!.messages.load();
    final photoMessages = state.chat!.messages
        .where((m) => m.media.value?.type == Mediatype.image)
        .toList();

    final photos = photoMessages.map((m) => m.media.value!).toList();
    state = state.copyWith(photos: photos);
  }

  Future<void> updateTitle(String newTitle, WidgetRef ref) async {
    if (state.chat == null) return;

    final updatedChat = state.chat!.copyWith(title: newTitle);
    state = state.copyWith(chat: updatedChat);

    // await ref.read(chatListProvider.notifier).updateChat(updatedChat);
    await ref.read(chatScreenController.notifier).updateChatTitle(newTitle);
  }
}
