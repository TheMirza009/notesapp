import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';

/// Dart-3 style recorded extension
extension MessageListLayout on List<Message> {
  ({
    Message message,
    Message? prevMessage,
    Message? nextMessage,
    bool showDateChip,
    bool nextStartsNewDay,
    bool prevSameSender,
    bool nextSameSender,
    double topPadding,
    double bottomPadding,
  }) layoutInfo(int index) {
    final message = this[index];
    final prevMessage = index > 0 ? this[index - 1] : null;
    final nextMessage = index < length - 1 ? this[index + 1] : null;

    // Show chip if this message starts a new day
    final bool showDateChip =
        prevMessage == null ||
        message.time.day != prevMessage.time.day ||
        message.time.month != prevMessage.time.month ||
        message.time.year != prevMessage.time.year;

    // Does the NEXT message start a new day?
    final bool nextStartsNewDay = nextMessage == null ||
        message.time.day != nextMessage.time.day ||
        message.time.month != nextMessage.time.month ||
        message.time.year != nextMessage.time.year;

    // bool flags
    final bool prevSameSender = prevMessage?.isSender == message.isSender;
    final bool nextSameSender = nextMessage?.isSender == message.isSender;

    // padding definitions
    final double topPadding = prevMessage == null || !prevSameSender ? 8 : (showDateChip ? 8 : 1);
    final double bottomPadding = nextMessage == null || !nextSameSender ? 8 : (nextStartsNewDay ? 8 : 1);

    // final returned class (the return method acts like a class | constructor skipped)
    return (
      message: message,
      prevMessage: prevMessage,
      nextMessage: nextMessage,
      showDateChip: showDateChip,
      nextStartsNewDay: nextStartsNewDay,
      prevSameSender: prevSameSender,
      nextSameSender: nextSameSender,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
    );
  }
}

extension BoolChecks on List<Message> {
  bool hasDuplicateMediaPath(Message target) {
    final targetPath = target.media.value?.path;
    if (targetPath == null) return false;

    // Collect all messages with the same path
    final matches = where((m) => m.media.value?.path == targetPath).toList();

    // true if more than 1 message shares this path
    return matches.length > 1;
  }
}

extension MessageGalleryExtensions on List<Message> {
  List<String> imagePaths() {
    return this
        .map((message) => message.media?.value) // get media value or null
        .where((media) => media?.type == Mediatype.image) // filter images
        .map((media) => media!.path!) // safe after filtering nulls
        .toList();
  }
}





