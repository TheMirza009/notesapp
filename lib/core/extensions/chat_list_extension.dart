import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

extension ChatListX on List<Chat> {
  Chat getChatByID(String id) => firstWhere(
    (c) => c.id == id, orElse: () => Chat.emptyChat());
}

extension MessageListX on List<Message> {
  Message? getMessageByTime(DateTime time) {
    return firstWhere((message) => message.time == time);
  }

  Message? getMessageByText(String text) {
    return firstWhere((message) => message.text == text);
  }
}