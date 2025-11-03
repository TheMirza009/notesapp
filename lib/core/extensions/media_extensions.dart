import 'package:flutter/foundation.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

extension MediaX on Media {
  DateTime? get messageTime {
    // backlinks always point to the messages containing this media
    return messagesBacklink.isNotEmpty ? messagesBacklink.first.time : null;
  }

  String get timeString {
    try {
      final msgs = (messagesBacklink..loadSync()).toList();
      if (msgs.isEmpty || msgs.first.time == null) {
        return "Unknown time";
      }
      return TimeFormat.formatChatTime(msgs.first.time);
    } catch (e) {
      debugPrint("Error reading time for media $name: $e");
      return "Unknown time";
    }
  }

  bool get isImage {
    return type == Mediatype.image;
  }

  bool get isVideo {
    return type == Mediatype.video;
  }

  bool get isDocument {
    return type == Mediatype.document;
  }

  bool get isAudio {
    return type == Mediatype.audio;
  }
}

extension MediaHelpers on List<Media> {
  /// Returns a list of Media items that have valid image paths
  List<Media> get validImages =>
      where((m) => m.type == Mediatype.image && m.path != null).toList();

  /// Returns the index of the Media that corresponds to the given Message
  int indexOfMediaIsarID(Message message) {
    final mediaId = message.media.value?.isarId;
    if (mediaId == null) return -1;
    return indexWhere((media) => media.isarId == mediaId);
  }
}

