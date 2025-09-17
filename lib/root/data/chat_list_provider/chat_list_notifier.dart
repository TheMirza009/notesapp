import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/models/chat_model.dart';

class ChatListState {
  final List<Chat> chats;
  final Chat? selectedChat;

  const ChatListState({this.chats = const [], this.selectedChat});

  ChatListState copyWith({List<Chat>? chats, Chat? selectedChat}) {
    return ChatListState(
      chats: chats ?? this.chats,
      selectedChat: selectedChat ?? this.selectedChat,
    );
  }
}



/// The provider
final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  return ChatListNotifier();
});


/// Notifier that controls a list of chats stored in Isar
class ChatListNotifier extends StateNotifier<ChatListState> {
  List<Chat> _allChats = []; // master list, source of truth

  ChatListNotifier() : super(const ChatListState()) {
    loadChats();
  }

  /// Load all chats from DB
  Future<void> loadChats() async {
    final loadedChats = await IsarDatabase.loadAllChats();
    _allChats = loadedChats;
    state = state.copyWith(chats: loadedChats);
  }

  /// Create + persist + add to state
  Future<Chat> addChat() async {
    final savedChat = await IsarDatabase.addNewChat();
    _allChats = [..._allChats, savedChat];
    state = state.copyWith(chats: [...state.chats, savedChat]);
    return savedChat;
  }

  /// Remove chat
  Future<void> removeChat(Chat chat) async {
    await IsarDatabase.isar.writeTxn(() async {
      await IsarDatabase.isar.chats.delete(chat.isarID);
    });

    _allChats = _allChats.where((c) => c.isarID != chat.isarID).toList();

    state = state.copyWith(
      chats: state.chats.where((c) => c.isarID != chat.isarID).toList(),
      selectedChat: state.selectedChat?.isarID == chat.isarID
          ? null
          : state.selectedChat,
    );
  }

  /// Clear all chats
  Future<void> clearChats() async {
    await IsarDatabase.clearRepo();
    _allChats = [];
    state = const ChatListState();
  }

  /// Update chat and keep state consistent
  Future<void> updateChat(Chat updatedChat) async {
    await IsarDatabase.saveChat(updatedChat);

    _allChats = _allChats
        .map((c) => c.isarID == updatedChat.isarID ? updatedChat : c)
        .toList();

    final updatedChats = state.chats
        .map((c) => c.isarID == updatedChat.isarID ? updatedChat : c)
        .toList();

    final newSelected = state.selectedChat?.isarID == updatedChat.isarID
        ? updatedChat
        : state.selectedChat;

    state = state.copyWith(chats: updatedChats, selectedChat: newSelected);
  }

  /// Search chats by title
  void searchChats(String query) {
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    final lowercaseQuery = query.toLowerCase();
    state = state.copyWith(
      chats: _allChats
          .where((chat) =>
              (chat.title ?? "").toLowerCase().contains(lowercaseQuery))
          .toList(),
    );
  }

  /// Reset to full list
  void clearSearch() {
    state = state.copyWith(chats: _allChats);
  }

  /// Select chat
  void selectChat(Chat chat) {
    state = state.copyWith(selectedChat: chat);
  }

  /// clear selectedChat
  void clearSelectedChat() {
  state = state.copyWith(selectedChat: null);
  }

  /// Change selected chat title
  void changeSelectedChatTitle(String newTitle) {
    if (state.selectedChat == null) return;
    final updatedChat = state.selectedChat!.copyWith(title: newTitle);
    final updatedChats = state.chats
        .map((c) => c.isarID == updatedChat.isarID ? updatedChat : c)
        .toList();

    state = state.copyWith(chats: updatedChats, selectedChat: updatedChat);
  }

  /// Get chat by ID
  Chat getChatByID(String uuid) {
    return _allChats.firstWhere((chat) => chat.uuid == uuid);
  }
}