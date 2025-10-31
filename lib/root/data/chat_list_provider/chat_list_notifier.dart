import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:isar_community/isar.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/extensions/chat_extensions.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/data/enums/chatlist_filter.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/chat_screen.dart';
import 'package:notesapp/root/screens/Homescreen/homescreen.dart';

class ChatListState {
  final List<Chat> chats;
  final Chat? selectedChat;
  final bool isLoading;
  final Map<Chat, List<Message>> searchResults; // Add this
  final Message? messageToHighlight;

  const ChatListState({
    this.chats = const [],
    this.selectedChat,
    this.isLoading = false,
    this.searchResults = const {}, // Add this
    this.messageToHighlight,
  });

  ChatListState copyWith({
    List<Chat>? chats,
    Chat? selectedChat,
    bool? isLoading,
    Map<Chat, List<Message>>? searchResults, // Add this
    Message? messageToHighlight,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
      selectedChat: selectedChat ?? this.selectedChat,
      isLoading: isLoading ?? this.isLoading,
      searchResults: searchResults ?? this.searchResults, // Add this
      messageToHighlight: messageToHighlight ?? this.messageToHighlight,
    );
  }
}

/// The provider
final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  return ChatListNotifier();
});


/// Notifier that controls a list of chats stored in Isar
class ChatListNotifier extends StateNotifier<ChatListState> {
  List<Chat> _allChats = [];// master list, source of truth
  ChatlistFilter _currentFilter = ChatlistFilter.oldestCreated; // default
  ChatListNotifier() : super(const ChatListState()) {
    loadChats();
  }

  /// Load all chats from DB
  Future<void> loadChats() async {
    state = state.copyWith(isLoading: true);
    final loadedChats = await IsarDatabase.loadAllChats();
    _allChats = loadedChats;
    applyFilter(_currentFilter);
    // state = state.copyWith(chats: loadedChats, isLoading: false);
    state = state.copyWith(isLoading: false);
  }

  Future<void> refreshChat(int isarId) async {
  final fresh = await IsarDatabase.isar.chats.get(isarId);
  if (fresh == null) return;

  await fresh.messages.load();
  _allChats = _allChats.map((c) => c.isarID == isarId ? fresh : c).toList();
  final updatedChats = state.chats.map((c) => c.isarID == isarId ? fresh : c).toList();
  final newSelected = state.selectedChat?.isarID == isarId ? fresh : state.selectedChat;

  state = state.copyWith(chats: updatedChats, selectedChat: newSelected);
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
      chats: _allChats.where((chat) => (chat.title ?? "").toLowerCase().contains(lowercaseQuery)).toList(),
    );
  }
  
  Future<Map<Chat, List<Message>>> searchMessages(String query) async {
  if (query.trim().isEmpty) {
    clearSearch();
    return {};
  }

  state = state.copyWith(isLoading: true);

  try {
    final isar = IsarDatabase.isar;
    final lowercaseQuery = query.toLowerCase();

    // ✅ Run title and message searches in parallel
    final results = await Future.wait([
      // Title search (fast - in-memory)
      Future.value(
        _allChats.where((chat) => 
          (chat.title ?? "").toLowerCase().contains(lowercaseQuery)
        ).toList(),
      ),
      
      // Message search (slower - database query)
      isar.messages
          .filter()
          .textContains(query, caseSensitive: false)
          .findAll(),
    ]);

    final titleMatchedChats = results[0] as List<Chat>;
    final matchedMessages = results[1] as List<Message>;

    // Step 2: Group messages by chat ID
    final Map<Id, List<Message>> chatMessageMap = {};
    final Set<Id> messageMatchedChatIds = {};

    await Future.wait(
      matchedMessages.map((msg) async {
        final chat = await msg.chat.value;
        if (chat == null) return;

        messageMatchedChatIds.add(chat.isarID);
        (chatMessageMap[chat.isarID] ??= []).add(msg);
      }),
    );

    // Step 3: Separate title-only and message-only matches
    final Set<Id> titleMatchedIds = titleMatchedChats.map((c) => c.isarID).toSet();
    
    final titleOnlyChats = titleMatchedChats
        .where((chat) => !messageMatchedChatIds.contains(chat.isarID))
        .toList();
    
    final titleAndMessageChats = titleMatchedChats
        .where((chat) => messageMatchedChatIds.contains(chat.isarID))
        .toList();
    
    final messageOnlyChats = _allChats
        .where((chat) => 
            messageMatchedChatIds.contains(chat.isarID) && 
            !titleMatchedIds.contains(chat.isarID))
        .toList();

    // Step 4: Combine in proper order
    // 1. Title-only matches (no messages to show)
    // 2. Title + message matches (show messages)
    // 3. Message-only matches (show messages)
    final combinedChats = [
      ...titleOnlyChats,
      ...titleAndMessageChats,
      ...messageOnlyChats,
    ];

    // Step 5: Create results map
    final resultsMap = {
      for (final chat in combinedChats)
        chat: chatMessageMap[chat.isarID] ?? [],
    };

    // Step 6: Update state
    state = state.copyWith(
      chats: combinedChats,
      isLoading: false,
      searchResults: resultsMap,
    );

    return resultsMap;
  } catch (error) {
    state = state.copyWith(isLoading: false);
    rethrow;
  }
}

  /// Reset to full list
  void clearSearch() {
    state = state.copyWith(chats: _allChats, searchResults: {}, messageToHighlight: null);
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

  void setHighlightedMessage(Message message) {
    state = state.copyWith(messageToHighlight: message);
  }

  void clearHighlight() {
    state = state.copyWith(messageToHighlight: null);
  }

  Future<void> navigateAndHighlight(
  BuildContext context,
  Message message,
  Chat chat,
) async {
  if (message.isarId == 0) return;

  // Set the message to highlight and select chat
  setHighlightedMessage(message);
  selectChat(chat);

  // Navigate - the ChatScreen will handle the rest
  await Navigator.push(
    context,
    CupertinoPageRoute(builder: (_) => const ChatScreen()),
  );

  clearHighlight();
}
Future<void> pinChat(Chat chat) async {
  final updatedChat = chat.copyWith(isPinned: true);
  await updateChat(updatedChat);
  applyFilter(_currentFilter); // ✅ Re-apply filter to maintain order
}

/// Unpin a chat
Future<void> unpinChat(Chat chat) async {
  final updatedChat = chat.copyWith(isPinned: false);
  await updateChat(updatedChat);
  applyFilter(_currentFilter); // ✅ Re-apply filter to maintain order
}

/// Toggle pin status
Future<void> togglePinChat(Chat chat) async {
  final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
  await updateChat(updatedChat);
  applyFilter(_currentFilter); // ✅ Re-apply filter to maintain order
}
  
// Track pending deletions properly
  final Map<int, _PendingDelete> _pendingDeletes = {};
  final Map<int, bool> isDeleting = {};


  /// Main delete method with undo support
  Future<void> deleteChatWithUndo(Chat chat) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      // Fallback: delete immediately if no context
      await removeChat(chat);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    // Create pending delete entry BEFORE any state changes
    final pendingDelete = _PendingDelete(chat);
    _pendingDeletes[chat.isarID] = pendingDelete;
    isDeleting[chat.isarID] = true;

    // Remove from UI (not DB)
    _tempRemoveChat(chat);

    // Show Snackbar
    final scaffold = ScaffoldMessenger.of(ctx);
    scaffold.hideCurrentSnackBar();

    final snackBar = SnackBar(
      padding: const EdgeInsets.all(12),
      backgroundColor: ctx.isLight 
        ? ThemeConstants.homeSubtitleLight 
        : ThemeConstants.darkAppbar,
      content: Text(
        "Chat deleted",
        style: TextStyle(
          fontFamily: "Poppins",
          color: ctx.isLight 
            ? ThemeConstants.textLight 
            : ThemeConstants.textDark2,
        ),
      ),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: "Undo",
        textColor: ThemeConstants.sinisterSeedHighlight,
        onPressed: () => _restoreChat(chat.isarID),
      ),
    );

    scaffold.showSnackBar(snackBar);
// Wait for snackbar duration
    await Future.delayed(const Duration(seconds: 4, milliseconds: 100));

    // Check if still pending (not restored)
    final pending = _pendingDeletes[chat.isarID];
    if (pending != null && !pending.isRestored && !pending.isCommitted) {
      await _commitDelete(chat.isarID);
    }
  }

  /// Temporarily remove chat from UI only
  void _tempRemoveChat(Chat chat) {
    // Remove from master list
    _allChats = _allChats.where((c) => c.isarID != chat.isarID).toList();

    // Remove from current view
    final updatedChats = state.chats.where((c) => c.isarID != chat.isarID).toList();
    
    // Clear selection if this chat was selected
    final newSelectedChat = state.selectedChat?.isarID == chat.isarID 
      ? null 
      : state.selectedChat;

    state = state.copyWith(
      chats: updatedChats,
      selectedChat: newSelectedChat,
    );
  }

  /// Restore a chat from pending deletion
  void _restoreChat(int chatId) {
    final pending = _pendingDeletes[chatId];
    if (pending == null) {
      debugPrint("⚠️ Cannot restore chat $chatId - not found in pending deletes");
      return;
    }

    // Check if already restored or committed
    if (pending.isRestored) {
      debugPrint("⚠️ Chat $chatId already restored");
      return;
    }

    if (pending.isCommitted) {
      debugPrint("⚠️ Chat $chatId already committed to deletion");
      return;
    }

    // Mark as restored FIRST to prevent race condition
    pending.isRestored = true;
    isDeleting.remove(chatId);

    final chat = pending.chat;

    // Add back to master list if not present
    if (!_allChats.any((c) => c.isarID == chatId)) {
      _allChats.add(chat);
      debugPrint("✅ Restored chat $chatId to master list");
    } else {
      debugPrint("⚠️ Chat $chatId already in master list");
    }

    // Re-apply current filter to restore proper ordering
    applyFilter(_currentFilter);

    // Clean up after a delay to ensure state is updated
    Future.delayed(const Duration(milliseconds: 500), () {
      _pendingDeletes.remove(chatId);
    });
  }

  /// Commit the deletion to database
  Future<void> _commitDelete(int chatId) async {
    final pending = _pendingDeletes[chatId];
    if (pending == null) {
      debugPrint("⚠️ Cannot commit delete for chat $chatId - not found");
      return;
    }

    // Check if already restored
    if (pending.isRestored) {
      debugPrint("⚠️ Chat $chatId was restored, skipping deletion");
      _pendingDeletes.remove(chatId);
      return;
    }

    // Mark as committed to prevent restore after this point
    pending.isCommitted = true;

    try {
      // Delete from database
      await IsarDatabase.isar.writeTxn(() async {
        await IsarDatabase.isar.chats.delete(chatId);
      });
      
      debugPrint("✅ Committed deletion of chat $chatId");
    } catch (e) {
      // If deletion fails, restore the chat
      debugPrint("❌ Failed to delete chat $chatId: $e");
      pending.isCommitted = false;
      _restoreChat(chatId);
      return;
    } finally {
      // Clean up tracking maps
      isDeleting.remove(chatId);
    }

    // Ensure it's removed from state (should already be gone)
    _allChats = _allChats.where((c) => c.isarID != chatId).toList();
    
    final updatedChats = state.chats.where((c) => c.isarID != chatId).toList();
    final newSelectedChat = state.selectedChat?.isarID == chatId 
      ? null 
      : state.selectedChat;

    state = state.copyWith(
      chats: updatedChats,
      selectedChat: newSelectedChat,
    );

    // Final cleanup
    _pendingDeletes.remove(chatId);
  }

  /// Public method to restore - called from Homescreen if needed
  void restoreTempChat(Chat chat) {
    _restoreChat(chat.isarID);
  }

  /// Check if chat is currently pending deletion
  bool isChatPendingDelete(int chatId) {
    final pending = _pendingDeletes[chatId];
    return pending != null && !pending.isRestored && !pending.isCommitted;
  }

  /// Cancel all pending deletions (e.g., on app close)
  void cancelAllPendingDeletes() {
    final pendingIds = _pendingDeletes.keys.toList();
    for (final id in pendingIds) {
      _restoreChat(id);
    }
  }

  void handleChatHoldOptions(String value, Chat chat) {
    switch (value) {
      case 'pin':
        chat.isPinned ? unpinChat(chat) : pinChat(chat);
        break;
      case 'delete':
        // removeChat(chat);
        // _deleteChatWithFade
        break;
      default:
    }
  }

  /// Sort chats based on the current filter
  void applyFilter(ChatlistFilter filter) {
    _currentFilter = filter;

    List<Chat> sortedChats = List.from(_allChats);

    // First, separate pinned and unpinned
    final pinnedChats = sortedChats.where((chat) => chat.isPinned).toList();
    final unpinnedChats = sortedChats.where((chat) => !chat.isPinned).toList();

    // Sort only the unpinned chats
    switch (filter) {
      case ChatlistFilter.alphabetical:
        unpinnedChats.sort(
          (a, b) => (a.title ?? "").toLowerCase().compareTo(
            (b.title ?? "").toLowerCase(),
          ),
        );
        break;
      case ChatlistFilter.newestCreated:
        unpinnedChats.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ChatlistFilter.oldestCreated:
        unpinnedChats.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ChatlistFilter.newestModified:
        unpinnedChats.sort(
          (a, b) => b.loadLastMessageTime().compareTo(a.loadLastMessageTime()),
        );
        break;
      case ChatlistFilter.oldestModified:
        unpinnedChats.sort(
          (a, b) => a.loadLastMessageTime().compareTo(b.loadLastMessageTime()),
        );
        break;
    }

    // Combine: pinned first, then sorted unpinned
    final combinedChats = [...pinnedChats, ...unpinnedChats];
    state = state.copyWith(chats: combinedChats);
  }
}


class _PendingDelete {
  final Chat chat;
  bool isRestored;
  bool isCommitted;

  _PendingDelete(this.chat)
      : isRestored = false,
      isCommitted = false;
}