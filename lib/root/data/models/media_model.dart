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

  /// New field to store width / height ratio
  double? aspectRatio;

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

  @override
  String toString() => 'Media(name: $name, type: $type, ext: $extension, path: ${path ?? "remote"}, aspectRatio: $aspectRatio)';
}
