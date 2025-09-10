import 'package:flutter/material.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class Chat {
  final String id;
  final String? title;
  final String preview;
  final DateTime date;
  final dynamic photo;
  final List<Message> messages;
  final List<Media> media;

 Chat({
    String? id,
    this.title = "New Note",
    required this.preview,
    required this.date,
    this.photo,
    this.messages = const [],
    this.media = const [],
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Chat copyWith({
  String? id,
  String? title,
  String? preview,
  DateTime? date,
  dynamic photo,
  List<Message>? messages,
  List<Media>? media,
}) {
  return Chat(
    id: id ?? this.id,
    title: title ?? this.title,
    preview: preview ?? this.preview,
    date: date ?? this.date,
    photo: photo ?? this.photo,
    messages: messages ?? List.from(this.messages),
    media: media ?? List.from(this.media),
  );
}


  factory Chat.emptyChat() {
    return Chat(
      title: "New Note",
      preview: "This is a new chat. Start typing to create your first note.",
      date: DateTime.now(),
      photo: null,
      messages: [
        Message(
          id: "0000",
          text: "This is a new chat. Start typing to create your first note.",
          time: DateTime.now(),
          isSender: false,
          type: Mediatype.text,
        ),
      ],
    );
  }
}
