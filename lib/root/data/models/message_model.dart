import 'package:isar/isar.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:uuid/uuid.dart';

part 'message_model.g.dart'; // Isar command for file generation

@collection
class Message {

  // Internal Isar ID (auto-increment)
  Id isarId = Isar.autoIncrement;

  // UUID v7 for export/cloud
  late String id;
  late String text;
  late DateTime time;
  late bool isSender;
  late bool isSelected;
  IsarLink<Media> media = IsarLink<Media>();

  @Backlink(to: 'messages')
  final IsarLink<Chat> chat = IsarLink<Chat>(); // single link

  Message() {
    id = const Uuid().v7(); // Generate a UUID automatically
  }

  Message copyWith({
    String? id,
    String? text,
    DateTime? time,
    bool? isSender,
    bool? isSelected,
    Media? media,
  }) {
    final newMessage = Message()
      ..id = id ?? this.id
      ..text = text ?? this.text
      ..time = time ?? this.time
      ..isSender = isSender ?? this.isSender
      ..isSelected = isSelected ?? this.isSelected;

    if (media != null) {
      newMessage.media.value = media; // assign the value
    } else if (this.media.value != null) {
      newMessage.media.value = this.media.value; // copy existing value
    }

    return newMessage;
  }

  @override
  String toString() {
    return 'Message(id: $id, isSender: $isSender, time: $time, text: "$text", media: ${media.value})';
  }
}
