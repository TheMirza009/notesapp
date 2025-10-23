import 'dart:typed_data';
import 'package:isar_community/isar.dart';
import 'message_model.dart';
import '../enums/media_type.dart';

part 'media_model.g.dart';

@collection
class Media {
  Id isarId = Isar.autoIncrement;

  late String name;
  String? path;
  late String extension;

  @enumerated
  late Mediatype type;

  /// Nullable Metadata
  int? fileSize;        // ALL TYPES
  double? aspectRatio;  // Image + Video
  String? blurHash;     // Image + Video
  String? duration;     // Audio + Video

  @Backlink(to: 'media')
  final IsarLinks<Message> messagesBacklink = IsarLinks<Message>();

  Media();

  factory Media.text() {
    final media = Media();
    media.name = "";
    media.extension = "txt";
    media.type = Mediatype.text;
    media.path = null;
    return media;
  }

  factory Media.fromFilePath(String filePath) {
    final media = Media();
    final segments = filePath.split('/');
    media.name = segments.isNotEmpty ? segments.last : filePath;
    media.path = filePath;
    final ext = media.name.split('.').last.toLowerCase();
    media.extension = ext;
    media.type = _detectType(ext);
    return media;
  }

  factory Media.fromLink(String url) {
    final media = Media();
    final uri = Uri.parse(url);
    media.name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
    media.path = url;
    media.extension = media.name.contains('.') ? media.name.split('.').last.toLowerCase() : '';
    media.type = Mediatype.link;
    return media;
  }

  factory Media.fromImageBytes(Uint8List bytes) {
    final media = Media();
    media.name = "pasted_${DateTime.now().millisecondsSinceEpoch}.png";
    media.extension = "png";
    media.type = Mediatype.image;
    media.path = null;

    return media;
  }

  static Mediatype _detectType(String ext) {
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) return Mediatype.image;
    if (['mp4', 'mov', 'mkv', 'avi'].contains(ext)) return Mediatype.video;
    if (['mp3', 'wav', 'aac', 'ogg', 'flac', 'opus', 'm4a', 'amr', 'wma'].contains(ext)) return Mediatype.audio;
    if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) return Mediatype.document;
    return Mediatype.unknown;
  }

  /// ✅ Check if media has complete metadata for its type
  bool get hasCompleteMetadata {
    switch (type) {
      case Mediatype.image:
        return aspectRatio != null && blurHash != null && fileSize != null;
      case Mediatype.video:
        return aspectRatio != null && duration != null && fileSize != null;
      case Mediatype.audio:
        return duration != null && fileSize != null;
      case Mediatype.document:
        return fileSize != null;
      case Mediatype.text:
      case Mediatype.link:
      case Mediatype.unknown:
        return true; // These types don't require additional metadata
      case Mediatype.contact:
        // TODO: Handle this case.
        throw UnimplementedError();
      case Mediatype.location:
        // TODO: Handle this case.
        throw UnimplementedError();
      case Mediatype.chart:
        // TODO: Handle this case.
        throw UnimplementedError();
      case Mediatype.thread:
        // TODO: Handle this case.
        throw UnimplementedError();
      case Mediatype.scan:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

/// ✅ Copy with updated metadata
  Media copyWith({
    String? name,
    String? path,
    String? extension,
    Mediatype? type,
    int? fileSize,
    double? aspectRatio,
    String? blurHash,
    String? duration,
  }) {
    final media = Media()
      ..name = name ?? this.name
      ..path = path ?? this.path
      ..extension = extension ?? this.extension
      ..type = type ?? this.type
      ..fileSize = fileSize ?? this.fileSize
      ..aspectRatio = aspectRatio ?? this.aspectRatio
      ..blurHash = blurHash ?? this.blurHash
      ..duration = duration ?? this.duration;
    
    return media;
  }

  /// ✅ Update metadata from another media object
  void updateMetadata(Media other) {
    fileSize = other.fileSize ?? fileSize;
    aspectRatio = other.aspectRatio ?? aspectRatio;
    blurHash = other.blurHash ?? blurHash;
    duration = other.duration ?? duration;
  }

   /// ✅ Get display-friendly file size
  String get fileSizeDisplay {
    if (fileSize == null) return 'Unknown size';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = fileSize!.toDouble();
    int unitIndex = 0;
    
    while (size > 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  @override
  String toString() => 'Media('
      'name: $name, '
      'type: $type, '
      'ext: $extension, '
      'path: ${path ?? "remote"}, '
      'size: $fileSizeDisplay, '
      'aspectRatio: $aspectRatio'
      ')';

  /// ✅ Equality check (useful for comparisons)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Media &&
          runtimeType == other.runtimeType &&
          isarId == other.isarId &&
          path == other.path;

  @override
  int get hashCode => isarId.hashCode ^ path.hashCode;
}