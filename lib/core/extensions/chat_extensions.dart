import 'package:isar_community/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

extension ChatX on Chat {
  String get lastMessageText {
    const String noMessages = "No notes added yet.";
    if (messages.isEmpty) return noMessages;
    final Message lastMessage = messages.last;
    final bool isPhoto = lastMessage.media.value?.type == Mediatype.image && (lastMessage.text.isEmpty ?? true);
    final bool isVideo = lastMessage.media.value?.type == Mediatype.video && (lastMessage.text.isEmpty ?? true);
    final bool isDocument = lastMessage.media.value?.type == Mediatype.document && (lastMessage.text.isEmpty ?? true);
    if (isPhoto) return "📷 Photo";
    if (isVideo) return "📽️ Video";
    if (isDocument) return "📄 Document";
    return lastMessage.text ?? noMessages;
  }

  String loadLastMessage() {
    return IsarDatabase.isar.messages
        .filter()
        .chat((q) => q.isarIDEqualTo(isarID)) // assuming chat has isarID
        .sortByTimeDesc() // requires time indexed
        .findFirstSync()!
        .text;
  }

  DateTime loadLastMessageTime() {
    return IsarDatabase.isar.messages
        .filter()
        .chat((q) => q.isarIDEqualTo(isarID)) // assuming chat has isarID
        .sortByTimeDesc() // requires time indexed
        .findFirstSync()!
        .time;
  }
}
