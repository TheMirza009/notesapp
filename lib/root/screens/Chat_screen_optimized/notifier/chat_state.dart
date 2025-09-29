import 'package:notesapp/root/data/models/message_model.dart';

class ChatState {
  final List<Message> messages;

  // Flags
  final bool isSearching;
  final bool showEmojis;
  final bool isLoading;
  final Message? anchorMessage;

  // Optimized message subsets
  final Message? highlightedMessage;        // Only one highlighted at a time
  final List<Message> selectedMessages;     // Can have multiple

  /// Derived flag: true if any message is selected
  bool get isSelecting => selectedMessages.isNotEmpty;

  ChatState({
    this.messages = const [],
    this.isSearching = false,
    this.showEmojis = false,
    this.isLoading = false,
    this.anchorMessage,
    this.highlightedMessage,
    this.selectedMessages = const [],
  });

  /// CopyWith for immutability
  ChatState copyWith({
    List<Message>? messages,
    bool? isSearching,
    bool? showEmojis,
    bool? isLoading,
    Message? anchorMessage,
    Message? highlightedMessage,
    List<Message>? selectedMessages,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSearching: isSearching ?? this.isSearching,
      showEmojis: showEmojis ?? this.showEmojis,
      isLoading: isLoading ?? this.isLoading,
      anchorMessage: anchorMessage,
      highlightedMessage: highlightedMessage,
      selectedMessages: selectedMessages ?? this.selectedMessages,
    );
  }

  /// Add a new message
  ChatState addMessage(Message message) {
    return copyWith(messages: [...messages, message]);
  }

  /// Remove a message safely
  ChatState removeMessage(String id) {
    final updatedMessages = messages.where((m) => m.isarId != id).toList();
    final updatedSelected = selectedMessages.where((m) => m.isarId != id).toList();
    final updatedHighlighted = highlightedMessage?.isarId == id ? null : highlightedMessage;

    return copyWith(
      messages: updatedMessages,
      selectedMessages: updatedSelected,
      highlightedMessage: updatedHighlighted,
    );
  }

  /// Highlight a message
  ChatState highlightMessage(Message? message) {
    return copyWith(highlightedMessage: message);
  }

  /// Select a message
  ChatState selectMessage(Message message) {
  if (selectedMessages.any((m) => m.isarId == message.isarId)) return this;
  return copyWith(selectedMessages: [...selectedMessages, message]);
}

  /// Unselect a message
  ChatState unselectMessage(Message message) {
    return copyWith(
      selectedMessages: selectedMessages.where((m) => m.isarId != message.isarId).toList(),
    );
  }

  /// Clear all selections
  ChatState clearSelection() {
    // final cleared = messages.map((m) => m..isSelected = false).toList();
    return copyWith(selectedMessages: []);
  }


  /// Clear highlight
  ChatState clearHighlight() {
    return copyWith(highlightedMessage: null);
  }

  /// Check if a message is selected
  bool isSelected(Message message) => selectedMessages.contains(message);

  /// Check if a message is highlighted
  bool isHighlighted(Message message) => highlightedMessage?.isarId == message.isarId;
}
