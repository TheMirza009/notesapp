import 'package:notesapp/core/extensions/string_extensions.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

extension MessageX on Message {
  /// True when this message carries multiple media (an album).
  bool get isAlbum => mediaList.length > 1;

  /// All media for this message: the album list when present, otherwise the
  /// single linked media (legacy/single-media messages), otherwise empty.
  List<Media> get allMedia {
    if (mediaList.isNotEmpty) return mediaList.toList();
    final single = media.value;
    return single != null ? [single] : [];
  }

  bool get isImage {
    return media.value?.type == Mediatype.image;
  }

  bool get isAudio {
    return media.value?.type == Mediatype.audio;
  }

  bool get isVideo {
    return media.value?.type == Mediatype.video;
  }
  
  bool get isDocument {
    return media.value?.type == Mediatype.document;
  }

  bool get isThread {
    return media.value?.type == Mediatype.thread;
  }

  String get getMessageDisplayText {
    if (isAlbum) return "📷 ${allMedia.length} Photos";
    final bool isPhoto = media.value?.type == Mediatype.image; // && (text.isEmpty);
    final bool isVideo = media.value?.type == Mediatype.video; // && (text.isEmpty);
    final bool isDocument = media.value?.type == Mediatype.document; // && (text.isEmpty);
    final bool isThread = media.value?.type == Mediatype.thread; // && (text.isEmpty);
    final bool isLink = text?.contains(RegExp(r'§([^§]+)§')) ?? false;
    
    if (isPhoto) return "📷 Photo";
    if (isVideo) return "📽️ Video";
    if (isDocument) return "📄 Document";
    if (isThread) return "🧵 ${text.getThreadLength()} Threads";
    if (isLink) return (text ?? '').unwrappedLink;
    
    return text ?? "No notes to show";
  }
}
