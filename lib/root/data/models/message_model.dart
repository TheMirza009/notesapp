import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';
import 'media_model.dart';
import 'chat_model.dart';

part 'message_model.g.dart';

@collection
class Message {
  Id isarId = Isar.autoIncrement;

  late String id;
  late String text;
  late DateTime time;
  late bool isSender;

  IsarLink<Media> media = IsarLink<Media>();
  IsarLink<Message> replyingTo = IsarLink<Message>();

  @Backlink(to: 'messages')
  final IsarLink<Chat> chat = IsarLink<Chat>();

  Message() {
    id = const Uuid().v7();
    text = "";
    time = DateTime.now();
    isSender = true;
  }

  Message copyWith({
    String? id,
    String? text,
    DateTime? time,
    bool? isSender,
    Media? media,
    Message? replyingTo,
  }) {
    final newMessage = Message()
      ..id = id ?? this.id
      ..text = text ?? this.text
      ..time = time ?? this.time
      ..isSender = isSender ?? this.isSender;

    // Copy media link
    if (media != null) {
      newMessage.media.value = media;
    } else if (this.media.value != null) {
      newMessage.media.value = this.media.value;
    }

    // Copy replyingTo link
    if (replyingTo != null) {
      newMessage.replyingTo.value = replyingTo;
    } else if (this.replyingTo.value != null) {
      newMessage.replyingTo.value = this.replyingTo.value;
    }

    return newMessage;
  }

  @override
  String toString() =>
      'Message(id: $id, text: "$text", isSender: $isSender, time: $time, media: ${media.value}, replyingTo: ${replyingTo.value?.id})';
}
