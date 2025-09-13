import 'package:isar/isar.dart';
import 'package:notesapp/core/controllers/isar_kit.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';

class ChatRepository {
  
  static Future<void> saveChat(Chat chat) async {
    final isar = IsarKit.isar;

    // Copy out links BEFORE transaction to avoid lazy-loading inside txn
    final messagesSnapshot = chat.messages.toList();

    await isar.writeTxn(() async {
      await isar.chats.put(chat);

      for (var msg in messagesSnapshot) {
        await isar.messages.put(msg);

        if (msg.media.value != null) {
          await isar.medias.put(msg.media.value!);
          await msg.media.save();
        }
      }

      chat.messages
        ..clear()
        ..addAll(messagesSnapshot);
      await chat.messages.save();
    });
  }


  static Future<List<Message>> loadMessages(Id chatId, {int limit = 50}) async {
    return await IsarKit.isar.messages
        .filter()
        .chat((q) => q.idEqualTo(chatId))
        .sortByTimeDesc()
        .limit(limit)
        .findAll();
  }

  static Future<List<Chat>> loadAllChats() async {
    final chats = await IsarKit.isar.chats.where().findAll();

    for (var chat in chats) {
      final messages = await loadMessages(chat.id, limit: 50);
      chat.messages.clear();
      chat.messages.addAll(messages);
      await IsarKit.isar.writeTxn(() async {
        await chat.messages.save();
      });
    }

    return chats;
  }
}
