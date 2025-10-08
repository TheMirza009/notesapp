import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

/// Extension for ChatList with custom methods
extension ChatListX on List<Chat> {
  Chat getChatByID(String id) => firstWhere(
        (c) => c.isarID.toString() == id,
        orElse: () => Chat.emptyChat(),
      );
}

/// Extension for List<Message>
extension MessageListX on List<Message> {
  Message? getMessageByTime(DateTime time) {
    try {
      return firstWhere((message) => message.time == time);
    } catch (_) {
      return null;
    }
  }

  Message? getMessageByText(String text) {
    try {
      return firstWhere((message) => message.text == text);
    } catch (_) {
      return null;
    }
  }

  Message? getMessageById(String id) {
    try {
      return firstWhere((message) => message.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Message> removeMessageById(String id) {
    return where((message) => message.id != id).toList();
  }

  List<Message> removeMessageWithText(String text) {
    return where((message) => message.text != text).toList();
  }

  List<Message> updateMessageById(String id, Message Function(Message) update) {
    return map((message) => message.id == id ? update(message) : message).toList();
  }

  List<Message> toggleSenderById(String id) {
    return updateMessageById(id, (message) => message.copyWith(isSender: !message.isSender));
  }

  // List<Message> selectMessageByID(String id) {
  //   return updateMessageById(id, (message) => message.copyWith(isSelected: true));
  // }

  // List<Message> unselectMessageByID(String id) {
  //   return updateMessageById(id, (message) => message.copyWith(isSelected: false));
  // }

  // List<Message> updateSelectedMessages(Message Function(Message) update) {
  //   return map((message) => message.isSelected ? update(message) : message).toList();
  // }

  // bool get allSelected => isNotEmpty && every((m) => m.isSelected);
  // bool get allUnselected => isNotEmpty && every((m) => !m.isSelected);
  // bool get partiallySelected => any((m) => m.isSelected) && !allSelected;
  // int get selectedCount => where((m) => m.isSelected).length;

  // List<Message> deleteSelectedMessages() {
  //   return where((message) => !message.isSelected).toList();
  // }

  // List<Message> selectAllMessages() {
  //   return map((message) => message.copyWith(isSelected: true)).toList();
  // }

  // List<Message> unselectAll() {
  //   return map((message) => message.copyWith(isSelected: false)).toList();
  // }

  List<Message> replaceMessage(Message newMessage) {
    return map((m) => m.id == newMessage.id ? newMessage : m).toList();
  }

  List<Message> updateTextById(String id, String newText) {
    return updateMessageById(id, (m) => m.copyWith(text: newText));
  }

  /// Updated for IsarLink<Media>
  List<Message> updateMediaById(String id, Media? newMediaContent) {
    return updateMessageById(
      id,
      (message) {
        final copy = message.copyWith();
        copy.media.value = newMediaContent;
        return copy;
      },
    );
  }
}
