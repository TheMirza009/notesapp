import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';

part 'chat_model.g.dart'; // ISAR generated file command

@collection
class Chat {
  Id id = Isar.autoIncrement; // Isar internal ID

  @Index(unique: true)
  late String uuid; // UUID for cloud/export

  String? title;
  late String preview;
  DateTime date = DateTime.now();
  String? chatPhotoPath;

  IsarLinks<Message> messages = IsarLinks<Message>();
  IsarLinks<Media> media = IsarLinks<Media>();

  // Default constructor
  Chat() {
    uuid = const Uuid().v7(); // Generate a UUID automatically
  }

  // copyWith fixed
  Chat copyWith({
    String? title,
    String? preview,
    DateTime? date,
    String? chatPhotoPath,
    List<Message>? messages,
    List<Media>? media,
  }) {
    final newChat = Chat()
      ..id = id
      ..uuid = uuid
      ..title = title ?? this.title
      ..preview = preview ?? this.preview
      ..date = date ?? this.date
      ..chatPhotoPath = chatPhotoPath ?? this.chatPhotoPath;

    if (messages != null) {
      newChat.messages.addAll(messages);
    } else {
      newChat.messages.addAll(this.messages.toList());
    }

    if (media != null) {
      newChat.media.addAll(media);
    } else {
      newChat.media.addAll(this.media.toList());
    }

    return newChat;
  }

  // Factory for empty chat
  factory Chat.emptyChat() {
    final firstMessage = Message()
      ..text = "This is a new chat. Start typing to create your first note."
      ..isSender = false
      ..time = DateTime.now();

    final chat = Chat()
      ..uuid = const Uuid().v7()
      ..preview = firstMessage.text
      ..date = DateTime.now();

    chat.messages.add(firstMessage);
    return chat;
  }
}
