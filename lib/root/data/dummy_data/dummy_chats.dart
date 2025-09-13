import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

final List<Chat> dummyChats = [
  Chat()
    ..title = "Work Project"
    ..preview = "Don't forget the deadline tomorrow!"
    ..date = DateTime(2025, 4, 9, 14, 30)
    ..chatPhotoPath = null
    ..messages.addAll([
      Message()
        ..text = "Don't forget the deadline tomorrow!"
        ..time = DateTime(2025, 4, 9, 14, 30)
        ..isSender = false
        ..isSelected = false,
      Message()
        ..text = "Sure, I'll send it by EOD."
        ..time = DateTime(2025, 4, 9, 15, 10)
        ..isSender = true
        ..isSelected = false,
    ]),
  Chat()
    ..title = "Family Group"
    ..preview = "Dinner at 8 PM tonight?"
    ..date = DateTime(2024, 4, 8, 18, 0)
    ..chatPhotoPath = null
    ..messages.addAll([
      Message()
        ..text = "Dinner at 8 PM tonight?"
        ..time = DateTime(2024, 4, 8, 18, 0)
        ..isSender = false
        ..isSelected = false,
      Message()
        ..text = "Sounds good! I'll be there."
        ..time = DateTime(2025, 4, 8, 18, 15)
        ..isSender = true
        ..isSelected = false,
    ]),
  Chat()
    ..title = "Travel Plans"
    ..preview = "We need to finalize the itinerary."
    ..date = DateTime(2025, 4, 7, 10, 45)
    ..chatPhotoPath = null
    ..messages.addAll([
      Message()
        ..text = "We need to finalize the itinerary."
        ..time = DateTime(2025, 4, 7, 10, 45)
        ..isSender = false
        ..isSelected = false,
      Message()
        ..text = "I'll send you the draft itinerary tonight."
        ..time = DateTime(2025, 4, 7, 11, 30)
        ..isSender = true
        ..isSelected = false,
    ]),
];
