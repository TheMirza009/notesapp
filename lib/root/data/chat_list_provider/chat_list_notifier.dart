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
import 'package:notesapp/root/presentation/screens/Settings/notifier/settings_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/chat_screen.dart';
import 'package:notesapp/root/presentation/screens/Homescreen/homescreen.dart';

class ChatListState {
  // final List<Folder> folders;
  final List<Chat> chats;
  final Chat? selectedChat;
  final bool isLoading;
  final Map<Chat, List<Message>> searchResults; // Add this
  final Message? messageToHighlight;

  const ChatListState({
    // this.folders = const [],
    this.chats = const [],
    this.selectedChat,
    this.isLoading = false,
    this.searchResults = const {}, // Add this
    this.messageToHighlight,
  });

  ChatListState copyWith({
  List<Chat>? chats,
  Object? selectedChat = _unset,
  bool? isLoading,
  Map<Chat, List<Message>>? searchResults,
  Object? messageToHighlight = _unset,
}) {
  return ChatListState(
    chats: chats ?? this.chats,
    selectedChat: identical(selectedChat, _unset)
        ? this.selectedChat
        : selectedChat as Chat?,
    isLoading: isLoading ?? this.isLoading,
    searchResults: searchResults ?? this.searchResults,
    messageToHighlight: identical(messageToHighlight, _unset)
        ? this.messageToHighlight
        : messageToHighlight as Message?,
  );
}
}

const _unset = Object();

/// The provider
final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  final initialFilter = ref.read(settingsController)?.chatListFilter ?? ChatlistFilter.oldestCreated;
  final notifier = ChatListNotifier(initialFilter);
  
  // Listen for filter changes in settings and apply them to the notifier
  ref.listen(settingsController.select((s) => s?.chatListFilterIndex), (prev, next) {
    if (next != null) {
      notifier.applyFilter(ChatlistFilter.values[next]);
    }
  });

  return notifier;
});


/// Notifier that controls a list of chats stored in Isar
class ChatListNotifier extends StateNotifier<ChatListState> {
  List<Chat> _allChats = [];// master list, source of truth
  ChatlistFilter _currentFilter = ChatlistFilter.oldestCreated; // default
  final Map<int, bool> isDeleting = {};
  ChatListNotifier(ChatlistFilter initialFilter) : super(const ChatListState()) {
    _currentFilter = initialFilter;
    loadChats();
  }

  /// Load all chats from DB
  Future<void> loadChats() async {
    state = state.copyWith(isLoading: true);
    final loadedChats = await IsarDatabase.loadAllChats();  // loadAllFolders()
    // final loadedChats = await IsarDatabase.loadAllFolders()();  
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
  applyFilter(_currentFilter);
}

  /// Create + persist + add to state
  Future<Chat> addChat() async {
    final savedChat = await IsarDatabase.addNewChat();
    _allChats = [..._allChats, savedChat];
    state = state.copyWith(chats: [...state.chats, savedChat]);
    applyFilter(_currentFilter);
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
    applyFilter(_currentFilter);
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
    applyFilter(_currentFilter);
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
    applyFilter(_currentFilter);
    state = state.copyWith(searchResults: {}, messageToHighlight: null);
  }

  /// Select chat
  void selectChat(Chat chat) {
    state = state.copyWith(selectedChat: chat);
  }

  /// clear selectedChat
  void clearSelectedChat() {
  debugPrint("clearSelectedChat called — before: ${state.selectedChat?.messages.last.text}");
  state = state.copyWith(selectedChat: null);
  debugPrint("clearSelectedChat done — after: ${state.selectedChat?.messages.last.text}");
}

  /// Change selected chat title
  void changeSelectedChatTitle(String newTitle) {
    if (state.selectedChat == null) return;
    final updatedChat = state.selectedChat!.copyWith(title: newTitle);
    final updatedChats = state.chats
        .map((c) => c.isarID == updatedChat.isarID ? updatedChat : c)
        .toList();

    state = state.copyWith(chats: updatedChats, selectedChat: updatedChat);
    applyFilter(_currentFilter);
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


  /// Temporarily remove chat from UI only
  void tempRemoveChat(Chat chat) {
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
  void restoreTempChat(Chat chat) {
    if (!_allChats.any((c) => c.isarID == chat.isarID)) {
      _allChats.add(chat);
    }
    applyFilter(_currentFilter);
  }

  void handleChatHoldOptions(String value, Chat chat) {
    switch (value) {
      case 'pin':
        chat.isPinned ? unpinChat(chat) : pinChat(chat);
        break;
      case 'delete':
        // Delegate to Use Case from UI instead
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
