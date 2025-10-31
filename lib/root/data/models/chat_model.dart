import 'package:isar_community/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:uuid/uuid.dart';
import 'message_model.dart';
import 'media_model.dart';

part 'chat_model.g.dart';

@collection
class Chat {
  Id isarID = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  String? title;
  late String preview;
  DateTime date = DateTime.now();
  String? chatPhotoPath;
  String? chatBackgroundPath;
  bool isPinned = false;

  // Enum field for bubble style, default to opaque
  @enumerated
  BubbleStyle bubbleStyle = BubbleStyle.opaque;

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
    IsarLinks<Message>? messages,
    List<Media>? media,
    BubbleStyle? bubbleStyle, // Add here
    bool? isPinned,
  }) {
    final newChat = Chat()
      ..isarID = isarID
      ..uuid = uuid
      ..title = title ?? this.title
      ..preview = preview ?? this.preview
      ..date = date ?? this.date
      ..isPinned = isPinned ?? this.isPinned
      ..chatPhotoPath = chatPhotoPath ?? this.chatPhotoPath
      ..bubbleStyle = bubbleStyle ?? this.bubbleStyle;

    if (messages != null) {
      newChat.messages.addAll(messages);
    } else {
      newChat.messages.addAll(this.messages.toList());
    }

    return newChat;
  }

  factory Chat.emptyChat() {
    final chat = Chat();

    final firstMessage =
        Message()
          ..text = "This is a new chat. Start typing to create your first note."
          ..isSender = false
          ..time = DateTime.now();

    chat.messages.add(firstMessage);
    chat.preview = firstMessage.text;
    chat.date = firstMessage.time;

    // Bubble style is already defaulted to opaque
    return chat;
  }
}
