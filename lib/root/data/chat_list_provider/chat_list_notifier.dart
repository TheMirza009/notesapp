import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

/// Notifier that controls a list of chats stored in Isar
class ChatListNotifier extends StateNotifier<List<Chat>> {
  ChatListNotifier() : super([]) {
    _loadChats();
  }

  Future<void> _loadChats() async {
    final loadedChats = await IsarDatabase.loadAllChats();
    state = loadedChats;
  }

  /// Create + persist + add to state
  Future<Chat> addChat() async {
    final savedChat = await IsarDatabase.addNewChat();
    state = [...state, savedChat]; // update provider state
    return savedChat; // for immediate navigation
  }

  Future<void> removeChat(Chat chat) async {
    await IsarDatabase.isar.writeTxn(() async {
      await IsarDatabase.isar.chats.delete(chat.isarID);
    });
    state = state.where((c) => c.isarID != chat.isarID).toList();
  }

  Future<void> clearChats() async {
    await IsarDatabase.clearRepo();
    state = [];
  }

  Future<void> updateChat(Chat updatedChat) async {
    await IsarDatabase.saveChat(updatedChat);
    state = state.map((c) => c.isarID == updatedChat.isarID ? updatedChat : c).toList();
  }

  Chat getChatByID(String uuid) {
    return state.firstWhere((chat) => chat.uuid == uuid);
  }
}


/// The provider
final chatListProvider = StateNotifierProvider<ChatListNotifier, List<Chat>>((ref) {
  return ChatListNotifier();
});
