import 'package:isar/isar.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Load_test/isar_test.dart/note_item.dart';
import 'package:path_provider/path_provider.dart';

class IsarDatabase {
  static Isar? _isar;

  /// Initialize Isar
  static Future<void> init() async {
    if (_isar != null && _isar!.isOpen) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ChatSchema, MessageSchema, MediaSchema],
      directory: dir.path,
      name: 'chat_repo',
    );
  }

  /// Accessor
  static Isar get isar {
    if (_isar == null) throw Exception("Isar not initialized. Call IsarKit.init()");
    return _isar!;
  }

  /// Load all chats
  static Future<List<Chat>> loadAllChats() async {
    return await isar.chats.where().findAll();
  }

  /// Load first N messages for a chat
  static Future<List<Message>> loadInitialMessages(Id chatId, {int limit = 50}) async {
    return await isar.messages
        .filter()
        .chat((q) => q.isarIDEqualTo(chatId))
        .sortByTimeDesc()
        .limit(limit)
        .findAll();
  }

  /// Lazy-load older messages
  static Future<List<Message>> loadOlderMessages(Id chatId, DateTime before, {int limit = 50}) async {
    return await isar.messages
        .filter()
        .chat((q) => q.isarIDEqualTo(chatId))
        .timeLessThan(before)
        .sortByTimeDesc()
        .limit(limit)
        .findAll();
  }

static Future<Chat> addNewChat(Chat newChat, Message newMessage) async {
  late Chat savedChat;

  await isar.writeTxn(() async {
    // Save both objects
    await isar.chats.put(newChat);
    await isar.messages.put(newMessage);

    // Re-fetch managed chat
    savedChat = await isar.chats.get(newChat.isarID) ?? newChat;

    // Link message to chat
    savedChat.messages.add(newMessage);
    await savedChat.messages.save();

    // ALSO: Link chat to message
    newMessage.chat.value = savedChat;
    await isar.messages.put(newMessage);

    // Update preview/date
    savedChat.preview = newMessage.text;
    savedChat.date = newMessage.time;
    await isar.chats.put(savedChat);
  });

  return savedChat;
}




  /// Save or update a chat
  static Future<void> saveChat(Chat chat) async {
    await isar.writeTxn(() async {
      await isar.chats.put(chat);
    });
  }

  /// Save or update a message
  static Future<void> saveMessage(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.put(message);
    });
  }

  /// Save or update media
  static Future<void> saveMedia(Media media) async {
    await isar.writeTxn(() async {
      await isar.medias.put(media);
    });
  }

  static Future<void> clearRepo() async {
    if (_isar == null || !_isar!.isOpen) {
      throw Exception("Isar instance 'chat_repo' is not initialized.");
    }

    isar.writeTxn(() async {
      await isar.chats.clear();
      await isar.messages.clear();
      await isar.medias.clear();
    });
  }
}
