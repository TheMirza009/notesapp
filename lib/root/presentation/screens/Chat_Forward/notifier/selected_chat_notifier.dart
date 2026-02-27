import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/chat_state_notifier.dart';

final forwardingController =
    NotifierProvider<ForwardNotifier, Set<String>>(() {
      return ForwardNotifier();
    });

class ForwardNotifier extends Notifier<Set<String>> {

  /// Search fields
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  bool isSearching = false;

  @override
  Set<String> build() => {};

  // --- Search control ---
  void toggleSearch([bool? value]) {
    isSearching = value ?? !isSearching;
    if (!isSearching) clearSearch();
    ref.notifyListeners(); // notify UI rebuild
  }

  void clearSearch() {
    searchController.clear();
    searchFocusNode.unfocus();
    ref.read(chatListProvider.notifier).clearSearch();
  }

  void searchChats(String query) {
    ref.read(chatListProvider.notifier).searchChats(query);
  }

  /// Selection control ///
  

  void toggleSelect(String chatId) {
    final newState = Set<String>.from(state);
    if (!newState.remove(chatId)) newState.add(chatId);
    state = newState;
  }

  void selectAll(List<Chat> chats) => state = chats.map((e) => e.uuid).toSet();
  void clear() => state = {};

  bool allSelected(List<Chat> chats) =>
      chats.isNotEmpty && state.length == chats.length;
  bool isSelected(String chatId) => state.contains(chatId);

  Future<void> forwardMessageToSelected(Message message) async {
    final chatList = ref.read(chatListProvider);
    final chatStateNotifier = ref.read(chatStateController.notifier);

    // Get selected chats
    final targetChats = chatList.chats.where((chat) => state.contains(chat.uuid)).toList();

    if (targetChats.isEmpty) return;

    for (final chat in targetChats) {
      await chatStateNotifier.forwardMessage(
        original: message,
        targetChat: chat,
      );
    }

    clear(); // reset selection after forwarding
    Navigator.pop(navigatorKey.currentContext!);
  }
}
