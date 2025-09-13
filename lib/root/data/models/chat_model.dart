import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'message_model.dart';
import 'media_model.dart';

part 'chat_model.g.dart';

@collection
class Chat {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  String? title;
  late String preview;
  DateTime date = DateTime.now();
  String? chatPhotoPath;

  IsarLinks<Message> messages = IsarLinks<Message>();

  Chat() {
    uuid = const Uuid().v7();
    preview = "";
  }

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

    return newChat;
  }

  factory Chat.emptyChat() {
    final chat = Chat();
    final firstMessage = Message()
      ..text = "This is a new chat. Start typing to create your first note."
      ..isSender = false
      ..isSelected = false
      ..time = DateTime.now();

    chat.messages.add(firstMessage);
    chat.preview = firstMessage.text;
    chat.date = firstMessage.time;
    return chat;
  }
}
