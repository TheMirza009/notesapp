import 'package:isar/isar.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

part 'media_model.g.dart'; // Isar command

@collection
class Media {
  Id isarId = Isar.autoIncrement; // Isar internal ID

  late String name;
  String? path; // file path (nullable for remote links)
  late String extension;

  @enumerated
  late Mediatype type;

  @Backlink(to: 'media')
  final IsarLinks<Chat> chats = IsarLinks<Chat>();

  @Backlink(to: 'media')
  final IsarLinks<Message> messagesBacklink = IsarLinks<Message>();

  
  Media();

  /// Factory for text-only placeholder
  factory Media.text() {
    final media = Media();
    media.name = "";
    media.extension = "txt";
    media.type = Mediatype.text;
    media.path = null;
    return media;
  }

  /// Factory from a file path
  factory Media.fromFilePath(String filePath) {
    final media = Media();
    final segments = filePath.split('/');
    media.name = segments.isNotEmpty ? segments.last : filePath;
    media.path = filePath;
    final ext = media.name.split('.').last.toLowerCase();
    media.extension = ext;
    media.type = _detectType(ext, null);
    return media;
  }

  /// Factory from a URL link
  factory Media.fromLink(String url) {
    final media = Media();
    final uri = Uri.parse(url);
    media.name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
    media.path = url; // store URL as path for Isar
    media.extension = media.name.contains('.') ? media.name.split('.').last.toLowerCase() : '';
    media.type = Mediatype.link;
    return media;
  }

  static Mediatype _detectType(String ext, String? mimeType) {
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) return Mediatype.image;
    if (['mp4', 'mov', 'mkv', 'avi'].contains(ext)) return Mediatype.video;
    if (['mp3', 'wav', 'aac', 'ogg', 'flac'].contains(ext)) return Mediatype.audio;
    if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(ext)) return Mediatype.document;
    return Mediatype.unknown;
  }

  @override
  String toString() => 'Media(name: $name, type: $type, ext: $extension, path: ${path ?? "remote"})';
}
