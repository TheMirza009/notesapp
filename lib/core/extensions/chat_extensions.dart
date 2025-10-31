import 'package:isar_community/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/extensions/string_extensions.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

extension ChatX on Chat {
  String loadLastMessageTextFormatted() {
    const String noMessages = "No notes added yet.";
    
    try {
      final lastMessage = IsarDatabase.isar.messages
          .filter()
          .chat((q) => q.isarIDEqualTo(isarID))
          .sortByTimeDesc()
          .findFirstSync();
      
      if (lastMessage == null) return noMessages;
      
      return getMessageDisplayText(lastMessage, noMessages);
    } catch (_) {
      return noMessages;
    }
  }

  String getMessageDisplayText(Message message, String fallbackText) {
    final bool isPhoto = message.media.value?.type == Mediatype.image && (message.text.isEmpty);
    final bool isVideo = message.media.value?.type == Mediatype.video && (message.text.isEmpty);
    final bool isDocument = message.media.value?.type == Mediatype.document && (message.text.isEmpty);
    final bool isThread = message.media.value?.type == Mediatype.thread && (message.text.isEmpty);
    
    if (isPhoto) return "📷 Photo";
    if (isVideo) return "📽️ Video";
    if (isDocument) return "📄 Document";
    if (isThread) return "🧵 ${message.text.formatThread()}";
    return message.text ?? fallbackText;
  }

  // Your existing methods...
  String loadLastMessage() {
    return IsarDatabase.isar.messages
        .filter()
        .chat((q) => q.isarIDEqualTo(isarID))
        .sortByTimeDesc()
        .findFirstSync()!
        .text;
  }

  Message loadLastMessageFull() {
    return IsarDatabase.isar.messages
        .filter()
        .chat((q) => q.isarIDEqualTo(isarID))
        .sortByTimeDesc()
        .findFirstSync()!;
  }

  DateTime loadLastMessageTime() {
    return IsarDatabase.isar.messages
        .filter()
        .chat((q) => q.isarIDEqualTo(isarID))
        .sortByTimeDesc()
        .findFirstSync()!
        .time;
  }
}