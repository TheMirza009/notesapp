import 'package:flutter/material.dart';
import 'package:notesapp/root/data/enums/bubble_color.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class ChatState {
  final List<Message> messages;

  // Flags
  final bool isSearching;
  final bool showEmojis;
  final bool isLoading;
  final bool isRecording;
  final bool isEditing;
  final bool isThreading;
  final Message? anchorMessage;
  final Message? cancelledThread;
  final Message? activeEditingThread;

  // Styling
  final BubbleColor? bubbleColor;

  // Optimized message subsets
  final Message? highlightedMessage;        // Only one highlighted at a time
  final List<Message> selectedMessages;     // Can have multiple
  final List<String> activeThreadStrings;     

  /// Derived flag: true if any message is selected
  bool get isSelecting => selectedMessages.isNotEmpty;

  ChatState({
    this.messages = const [],
    this.isSearching = false,
    this.isLoading = false,
    this.isRecording = false,
    this.isEditing= false,
    this.showEmojis = false,
    this.isThreading = false,
    this.bubbleColor = BubbleColor.seed,
    this.anchorMessage,
    this.highlightedMessage,
    this.cancelledThread,
    this.activeEditingThread,
    this.selectedMessages = const [],
    this.activeThreadStrings = const [],
  });

  /// CopyWith for immutability
  ChatState copyWith({
    List<Message>? messages,
    bool? isSearching,
    bool? showEmojis,
    bool? isLoading,
    bool? isRecording,
    bool? isEditing,
    bool? isThreading,
    BubbleColor? bubbleColor,
    Message? anchorMessage,
    Message? highlightedMessage,
    Message? cancelledThread,
    Message? activeEditingThread,
    List<Message>? selectedMessages,
    List<String>? activeThreadStrings,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSearching: isSearching ?? this.isSearching,
      showEmojis: showEmojis ?? this.showEmojis,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      isEditing: isEditing ?? this.isEditing,
      isThreading: isThreading ?? this.isThreading,
      bubbleColor: bubbleColor ?? this.bubbleColor,
      anchorMessage: anchorMessage,
      highlightedMessage: highlightedMessage,
      cancelledThread: cancelledThread,
      activeEditingThread: activeEditingThread ?? this.activeEditingThread,
      selectedMessages: selectedMessages ?? this.selectedMessages,
      activeThreadStrings: activeThreadStrings ?? this.activeThreadStrings,
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

  /// Add a thread to the active thread list
  ChatState startThreading(Message thread) {
    return copyWith(
      isThreading: true,
      activeThreadStrings: const ["_Start typing your first thread tile_"],
      activeEditingThread: thread,
      anchorMessage: anchorMessage,
    );
  }

  /// Add a thread to the active thread list
  ChatState addThread(String text) {
    return copyWith(activeThreadStrings: [...activeThreadStrings, text], anchorMessage: anchorMessage);
  }

  /// Clear threading state
  ChatState clearThreads() {
    return copyWith(activeThreadStrings: const [], isThreading: false);
  }

  /// Check if a message is selected
  bool isSelected(Message message) => selectedMessages.contains(message);

  /// Check if a message is highlighted
  bool isHighlighted(Message message) => highlightedMessage?.isarId == message.isarId;
}
