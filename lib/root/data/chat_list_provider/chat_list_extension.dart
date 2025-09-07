import 'package:notesapp/root/data/models/chat_model.dart';

extension ChatListX on List<Chat> {
  Chat getChatByID(String id) =>
      firstWhere((c) => c.id == id, orElse: () => Chat.emptyChat());
}
