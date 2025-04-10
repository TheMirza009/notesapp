import 'package:flutter/material.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class Chat {
  final String title;
  final String preview;
  final DateTime date;
  final photo;
  final List<Message> messages;
  final List<Media> media;

  const Chat({
    required this.title,
    required this.preview,
    required this.date,
    this.photo,
    this.messages = const [],
    this.media = const [],
  });

  static final emptyChat = Chat(
    title: "New Note",
    preview: "This is a new chat. Start typing to create your first note.",
    date: DateTime.now(),
    photo: null,
    messages:  [
      Message(
        text: "This is a new chat. Start typing to create your first note.",
        time: DateTime.now(),
        isSender: false,
        type: Mediatype.text,
      ),
    ]
  );
}
