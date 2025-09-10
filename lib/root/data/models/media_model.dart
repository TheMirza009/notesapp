import 'dart:io';
import 'package:mime/mime.dart';
import 'package:notesapp/root/data/enums/media_type.dart';

/// Represents a media file with relevant metadata.
class Media {
  final String name;       // File name or URL
  final File? content;     // Actual file (null for links)
  final String extension;  // File extension
  final Mediatype type;    // Media type (auto-detected)

  const Media._({
    required this.name,
    this.content,
    required this.extension,
    required this.type,
  });

  factory Media.text() {
    return const Media._(name: "", extension: "txt", type: Mediatype.text);
  }

  /// Factory: create Media from a file on disk
  factory Media.fromFile(File file) {
    final name = file.uri.pathSegments.last;
    final mimeType = lookupMimeType(file.path);
    final ext = file.path.split('.').last.toLowerCase();

    return Media._(
      name: name,
      content: file,
      extension: ext,
      type: _detectType(ext, mimeType),
    );
  }

  /// Factory: create Media from a link (URL)
  factory Media.fromLink(String url) {
    final uri = Uri.parse(url);
    final name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
    final ext = uri.path.contains('.') ? uri.path.split('.').last.toLowerCase() : '';

    return Media._(
      name: name,
      content: null,
      extension: ext,
      type: Mediatype.link,
    );
  }

  /// Detects type based on extension or MIME type
  static Mediatype _detectType(String ext, String? mimeType) {
    if (mimeType?.startsWith('image/') ?? false) return Mediatype.image;
    if (mimeType?.startsWith('video/') ?? false) return Mediatype.video;
    if (mimeType?.startsWith('audio/') ?? false) return Mediatype.audio;

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) return Mediatype.image;
    if (['mp4', 'mov', 'mkv', 'avi'].contains(ext)) return Mediatype.video;
    if (['mp3', 'wav', 'aac', 'ogg', 'flac'].contains(ext)) return Mediatype.audio;
    if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) {
      return Mediatype.document;
    }
    return Mediatype.unknown;
  }

  @override
  String toString() =>
      'Media(name: $name, type: $type, ext: $extension, path: ${content?.path ?? "remote"})';
}
