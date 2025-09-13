// import 'package:notesapp/root/data/models/chat_model.dart';
// import 'package:notesapp/root/data/models/media_model.dart';
// import 'package:notesapp/root/data/models/message_model.dart';

// /// Extension for ChatList with custom methods
// extension ChatListX on List<Chat> {
//   Chat getChatByID(String id) => firstWhere(
//     (c) => c.id == id, orElse: () => Chat.emptyChat());
// }

// /// returns a Message by given time
// extension MessageListX on List<Message> {
//   Message? getMessageByTime(DateTime time) {
//     try {
//       return firstWhere((message) => message.time == time);
//     } catch (_) {
//       return null;
//     }
//   }

//   /// returns a Message matching the given text
//   Message? getMessageByText(String text) {
//     try {
//       return firstWhere((message) => message.text == text);
//     } catch (_) {
//       return null;
//     }
//   }

//   // returns a Message matching the given ID
//   Message? getMessageById(String id) {
//     try {
//       return firstWhere((message) => message.id == id);
//     } catch (_) {
//       return null;
//     }
//   }

//   /// Returns a list where message by given ID is removed
//   List<Message> removeMessageById(String id) {
//     return where((message) => message.id != id).toList();
//   }

//   /// Returns a list where the message with the given text is removed
//   List<Message> removeMessageWithText(String text) {
//     return where((message) => message.text != text).toList();
//   }

//   /// Replace a message with a new version (by id)
//   List<Message> updateMessageById(String id, Message Function(Message) update) {
//     return map((message) => message.id == id ? update(message) : message).toList();
//   }

//   /// Convenience: toggle sender directly
//   List<Message> toggleSenderById(String id) {
//     return updateMessageById(id, (message) => message.copyWith(isSender: !message.isSender));
//   }

//   List<Message> selectMessageByID(String id) {
//     return updateMessageById(id, (message) => message.copyWith(isSelected: true));
//   }

//   List<Message> unselectMessageByID(String id) {
//     return updateMessageById(id, (message) => message.copyWith(isSelected: false));
//   }

//   List<Message> updateSelectedMessages(Message Function(Message) update) {
//     return map(
//       (message) => message.isSelected ? update(message) : message).toList();
//   }

//    /// Returns true if every message is selected (and list is not empty).
//   bool get allSelected => isNotEmpty && every((m) => m.isSelected);

//   /// Returns true if every message is unselected (and list is not empty).
//   bool get allUnselected => isNotEmpty && every((m) => !m.isSelected);

//   /// (Optional) Returns true if *some* messages are selected but not all.
//   bool get partiallySelected => any((m) => m.isSelected) && !allSelected;

//   /// method to get number of selected messages
//   int get selectedCount => where((m) => m.isSelected).length;

//   // List<Message> unselectMessageByID(String id) {
//   //   return updateMessageById(id, (message) => message.copyWith(isSelected: !message.isSelected));
//   // }

//   /// Delete all *Selected* messages
//   List<Message> deleteSelectedMessages() {
//     return where((message) => message.isSelected == false).toList();
//   }

//   List<Message> selectAllMessages() {
//     return map((message) => message.copyWith(isSelected: true)).toList();
//   }

//   List<Message> unselectAll() {
//     return map((message) => message.copyWith(isSelected: false)).toList();
//   }

//  /// Replace a message with a new one (by id)
//   List<Message> replaceMessage(Message newMessage) {
//     return map((m) => m.id == newMessage.id ? newMessage : m).toList();
//   }


//   /// Update only the text of a message
//   List<Message> updateTextById(String id, String newText) {
//     return updateMessageById(id, (m) => m.copyWith(text: newText));
//   }

//   /// Update message content
//   List<Message> updateMediaById(String id, Media? newMediaContent) {
//     return updateMessageById(id, (message) => message.copyWith(media: newMediaContent));
//   }
// }