import 'package:flutter/material.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:uuid/uuid.dart';

class Message {
  final String? id;
  final String text;
  final DateTime time;
  final Mediatype type;
  final bool isSender;
  final Media? _content;

   static final Uuid _uuid = Uuid();

  // Constructor
  Message({
    String? id,
    required this.text,
    required this.time,
    this.type = Mediatype.text,
    this.isSender = true,
    Media? content,
  })  : id = id ?? _uuid.v7(),
        _content = (type == Mediatype.text) ? null : content;

  Media? get content => type == Mediatype.text ? null : _content; /// Content is null for text messages 

  Message copyWith({
    String? id,
    String? text,
    DateTime? time,
    Mediatype? type,
    bool? isSender,
    Media? content,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      time: time ?? this.time,
      type: type ?? this.type,
      isSender: isSender ?? this.isSender,
      content: content ?? (type == Mediatype.text ? null : _content),
    );
  }
}
