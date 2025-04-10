import 'dart:io';

/// Represents a media file with relevant metadata.
class Media {
  final String name;
  final File content;
  final String extension;

  const Media({
    required this.name,
    required this.content,
    required this.extension,
  });

  @override
  String toString() => 'Media(name: $name, extension: $extension, path: ${content.path})';
}

