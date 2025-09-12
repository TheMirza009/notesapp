// import 'package:isar/isar.dart';
// import 'package:notesapp/root/data/models/chat_model.dart';
// import 'package:notesapp/root/data/models/media_model.dart';
// import 'package:notesapp/root/data/models/message_model.dart';
// import 'package:path_provider/path_provider.dart';

// class IsarKit {
//   static Isar? _isar;

//   /// Initialize Isar
//   static Future<void> init() async {
//     if (_isar != null && _isar!.isOpen) return;
//     final dir = await getApplicationDocumentsDirectory();
//     _isar = await Isar.open(
//       [ChatSchema, MessageSchema, MediaSchema],
//       directory: dir.path,
//     );
//   }

//   static Isar get isar {
//     if (_isar == null) throw Exception("Isar not initialized. Call IsarKit.init()");
//     return _isar!;
//   }

//   // -------------------------
//   // 🔹 CHAT METHODS
//   // -------------------------

//   static Future<void> saveChat(Chat chat) async {
//     await isar.writeTxn(() async {
//       await isar.chats.put(chat);
//       await chat.messages.save();
//       await chat.media.save();
//     });
//   }

//   static Future<List<Chat>> loadChats() async {
//     return await isar.chats.where().findAll();
//   }

//   static Future<Chat?> getChat(Id id) async {
//     return await isar.chats.get(id);
//   }

//   static Future<void> deleteChat(Id id) async {
//     await isar.writeTxn(() async {
//       await isar.chats.delete(id);
//     });
//   }

//   static Future<void> clearAll() async {
//     await isar.writeTxn(() async {
//       await isar.clear();
//     });
//   }

//   // -------------------------
//   // 🔹 MESSAGE METHODS
//   // -------------------------

//   static Future<void> addMessageToChat(Chat chat, Message message) async {
//     await isar.writeTxn(() async {
//       chat.messages.add(message);
//       await isar.messages.put(message);
//       await chat.messages.save();
//       await isar.chats.put(chat);
//     });
//   }

//   static Future<void> removeMessage(Chat chat, Message message) async {
//     await isar.writeTxn(() async {
//       chat.messages.remove(message);
//       await chat.messages.save();
//       await isar.messages.delete(message.id);
//     });
//   }

//   static Future<List<Message>> getMessages(Chat chat) async {
//     await chat.messages.load();
//     return chat.messages.toList();
//   }

//   // -------------------------
//   // 🔹 MEDIA METHODS
//   // -------------------------

//   static Future<void> addMediaToChat(Chat chat, Media media) async {
//     await isar.writeTxn(() async {
//       chat.media.add(media);
//       await isar.media.put(media);
//       await chat.media.save();
//       await isar.chats.put(chat);
//     });
//   }

//   static Future<void> removeMedia(Chat chat, Media media) async {
//     await isar.writeTxn(() async {
//       chat.media.remove(media);
//       await chat.media.save();
//       await isar.media.delete(media.id);
//     });
//   }

//   static Future<List<Media>> getMedia(Chat chat) async {
//     await chat.media.load();
//     return chat.media.toList();
//   }
// }
