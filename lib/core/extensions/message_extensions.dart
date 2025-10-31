import 'package:notesapp/core/extensions/string_extensions.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';

extension MessageX on Message {
  bool get isImage {
    return media.value?.type == Mediatype.image;
  }

  bool get isDocument {
    return media.value?.type == Mediatype.document;
  }

  bool get isAudio {
    return media.value?.type == Mediatype.audio;
  }
  
  bool get isThread {
    return media.value?.type == Mediatype.thread;
  }

  String get getMessageDisplayText {
    final bool isPhoto = media.value?.type == Mediatype.image && (text.isEmpty);
    final bool isVideo = media.value?.type == Mediatype.video && (text.isEmpty);
    final bool isDocument = media.value?.type == Mediatype.document && (text.isEmpty);
    final bool isThread = media.value?.type == Mediatype.thread && (text.isEmpty);
    
    if (isPhoto) return "📷 Photo";
    if (isVideo) return "📽️ Video";
    if (isDocument) return "📄 Document";
    if (isThread) return "🧵 ${text.formatThread()}";
    return text ?? "No notes to show";
  }
}
