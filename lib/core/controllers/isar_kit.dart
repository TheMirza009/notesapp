import 'package:isar/isar.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:path_provider/path_provider.dart';


class IsarKit {
  static Isar? _isar;

  /// Initialize Isar
  static Future<void> init() async {
    if (_isar != null && _isar!.isOpen) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ChatSchema, MessageSchema, MediaSchema],
      directory: dir.path,
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
        .chat((q) => q.idEqualTo(chatId))
        .sortByTimeDesc()
        .limit(limit)
        .findAll();
  }

  /// Lazy-load older messages
  static Future<List<Message>> loadOlderMessages(Id chatId, DateTime before, {int limit = 50}) async {
    return await isar.messages
        .filter()
        .chat((q) => q.idEqualTo(chatId))
        .timeLessThan(before)
        .sortByTimeDesc()
        .limit(limit)
        .findAll();
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
}
