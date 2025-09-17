import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/models/chat_model.dart';


/// The provider
final chatListProvider = StateNotifierProvider<ChatListNotifier, List<Chat>>((ref) {
  return ChatListNotifier();
});


/// Notifier that controls a list of chats stored in Isar
class ChatListNotifier extends StateNotifier<List<Chat>> {
  List<Chat> _allChats = []; // master list, source of truth
  Chat? selectedChat;

  ChatListNotifier() : super([]) {
    loadChats();
  }

  /// Load all chats from DB
  Future<void> loadChats() async {
    final loadedChats = await IsarDatabase.loadAllChats();
    _allChats = loadedChats; // keep master copy
    state = loadedChats;     // visible copy
    print("Chats loaded: $loadedChats");
  }

  /// Create + persist + add to state
  Future<Chat> addChat() async {
    final savedChat = await IsarDatabase.addNewChat();
    _allChats = [..._allChats, savedChat];
    state = [...state, savedChat];
    return savedChat; // for immediate navigation
  }

  Future<void> removeChat(Chat chat) async {
    await IsarDatabase.isar.writeTxn(() async {
      await IsarDatabase.isar.chats.delete(chat.isarID);
    });
    _allChats = _allChats.where((c) => c.isarID != chat.isarID).toList();
    state = state.where((c) => c.isarID != chat.isarID).toList();
  }

  Future<void> clearChats() async {
    await IsarDatabase.clearRepo();
    _allChats = [];
    state = [];
  }

  Future<void> updateChat(Chat updatedChat) async {
    await IsarDatabase.saveChat(updatedChat);
    _allChats = _allChats.map((c) => c.isarID == updatedChat.isarID ? updatedChat : c).toList();
    state = state.map((c) => c.isarID == updatedChat.isarID ? updatedChat : c).toList();
  }

   Chat getChatByID(String uuid) {
    return _allChats.firstWhere((chat) => chat.uuid == uuid);
  }

  /// Search chats by title
  void searchChats(String query) {
    if (query.isEmpty) {
      clearSearch(); // reset to full list
      return;
    }
    final lowercaseQuery = query.toLowerCase();
    state = _allChats
        .where((chat) => (chat.title ?? "").toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Clear search field and restore full list
  void clearSearch() {
    state = _allChats;
  }

  void selectChat(Chat chat) {
    selectedChat = chat;
    state = state;
    print(selectedChat!.title);
  }

  void changeSelectedChatTitle(String newTitle) {
    if (selectedChat == null) return;
    selectedChat = selectedChat!.copyWith(title: newTitle);
    state = state;
    print("new Title: ${selectedChat!.title}");
  }
}