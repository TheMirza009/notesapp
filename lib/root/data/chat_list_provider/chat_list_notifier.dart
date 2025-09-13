import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/isar_kit.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/data/repository/chat_repository.dart';

/// Notifier that controls a list of chats stored in Isar
class ChatListNotifier extends StateNotifier<List<Chat>> {
  ChatListNotifier() : super([]) {
    _loadChats();
  }

  Future<void> _loadChats() async {
    state = await ChatRepository.loadAllChats();
  }

  Future<void> addChat(Chat chat) async {
    await ChatRepository.saveChat(chat);
    state = [...state, chat];
  }

  Future<void> removeChat(Chat chat) async {
    await IsarKit.isar.writeTxn(() async {
      await IsarKit.isar.chats.delete(chat.id);
    });
    state = state.where((c) => c.id != chat.id).toList();
  }

  Future<void> clearChats() async {
    await IsarKit.isar.writeTxn(() async {
      await IsarKit.isar.chats.clear();
      await IsarKit.isar.messages.clear();
      await IsarKit.isar.medias.clear();
    });
    state = [];
  }

  Future<void> updateChat(Chat updatedChat) async {
    await ChatRepository.saveChat(updatedChat);
    state = state.map((c) => c.id == updatedChat.id ? updatedChat : c).toList();
  }

  Chat getChatByID(String uuid) {
    return state.firstWhere((chat) => chat.uuid == uuid);
  }
}


/// The provider
final chatListProvider = StateNotifierProvider<ChatListNotifier, List<Chat>>((ref) {
  return ChatListNotifier();
});
