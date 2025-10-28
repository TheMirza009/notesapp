import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
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

    return _computeLayoutInfo(message, prevMessage, nextMessage);
  }

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
  }) layoutInfoById(int isarId) {
    final index = indexWhere((m) => m.isarId == isarId);
    if (index == -1) {
      // fallback: return empty paddings so UI won’t crash
      return (
        message: Message(), // 👈 you may need a safe `Message.empty()` factory
        prevMessage: null,
        nextMessage: null,
        showDateChip: false,
        nextStartsNewDay: false,
        prevSameSender: false,
        nextSameSender: false,
        topPadding: 0,
        bottomPadding: 0,
      );
    }

    final message = this[index];
    final prevMessage = index > 0 ? this[index - 1] : null;
    final nextMessage = index < length - 1 ? this[index + 1] : null;

    return _computeLayoutInfo(message, prevMessage, nextMessage);
  }

  // 🔒 Shared private helper
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
  }) _computeLayoutInfo(Message message, Message? prevMessage, Message? nextMessage) {
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

    final bool prevSameSender = prevMessage?.isSender == message.isSender;
    final bool nextSameSender = nextMessage?.isSender == message.isSender;

    final double topPadding =
        prevMessage == null || !prevSameSender ? 8 : (showDateChip ? 8 : 1);
    final double bottomPadding =
        nextMessage == null || !nextSameSender ? 8 : (nextStartsNewDay ? 8 : 1);

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

extension MediaChecks on List<Message> {
  bool hasDuplicateMediaPath(Message target) {
    final targetPath = target.media.value?.path;
    if (targetPath == null || targetPath.isEmpty) return false;

    int count = 0;

    for (final msg in this) {
      final path = msg.media.value?.path;
      if (path == null || path.isEmpty) continue;

      if (path == targetPath) {
        count++;
        if (count > 1) return true; // early exit for performance
      }
    }

    return false;
  }

  bool hasDuplicateMediaPathByPath(
    String? targetPath, {
    int? excludingIsarId,
  }) {
    if (targetPath == null || targetPath.isEmpty) return false;

    int count = 0;

    for (final msg in this) {
      // Skip excluded message (to avoid counting the same message twice)
      if (excludingIsarId != null && msg.isarId == excludingIsarId) continue;

      final path = msg.media.value?.path;
      if (path == null || path.isEmpty) continue;

      if (path == targetPath) {
        count++;
        if (count > 0) return true; // ✅ only need to find 1 other match
      }
    }

    return false;
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

  List<Media> get imageMedias =>
      where((m) => m.isImage && m.media.value?.path != null)
          .map((m) => m.media.value!)
          .toList();
}

extension ThreadExtensions on List<Message> {
  /// 🔍 Get the last thread message in the list (most efficient)
  Message? getLastThread() {
    for (int i = length - 1; i >= 0; i--) {
      if (this[i].isThread) {
        return this[i];
      }
    }
    return null;
  }
  
  /// 🔍 Get all thread messages
  List<Message> get threads => where((message) => message.isThread).toList();
  
  /// 🔍 Check if list contains any thread messages
  bool get hasThreads => any((message) => message.isThread);
  
  /// 🔍 Get thread messages count
  int get threadCount => where((message) => message.isThread).length;
  
  /// 🔍 Remove the last thread message
  List<Message> removeLastThread() {
    final lastThread = getLastThread();
    if (lastThread != null) {
      return where((message) => message != lastThread).toList();
    }
    return List<Message>.from(this);
  }
}

