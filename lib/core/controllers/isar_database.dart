import 'package:isar_community/isar.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/data/models/settings_model.dart';
import 'package:notesapp/root/data/models/user_model.dart';
import 'package:path_provider/path_provider.dart';

class IsarDatabase {
  static Isar? _isar;

  /// Initialize Isar
  static Future<void> init() async {
    if (_isar != null && _isar!.isOpen) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ChatSchema, MessageSchema, MediaSchema, UserSchema, SettingsSchema],
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

  static Future<User?> loadUserData() async {
    return await isar.users.where().findFirst();
  }

  static Future<User?> loadSettings() async {
    return await isar.users.where().findFirst();
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

static Future<Chat> addNewChat() async {
  late Chat savedChat;

  await isar.writeTxn(() async {
    // 1️⃣ Create chat
    final newChat = Chat()
      ..title = "New Note"
      ..date = DateTime.now()
      ..messages = IsarLinks<Message>();

    // 2️⃣ Create and persist init message (so it gets a real Isar ID)
    final newMessage = Message()
      ..id = "0000"
      ..text = "This is a new chat. Start typing to create your first note."
      ..isSender = false
      ..time = DateTime.now();

    await isar.messages.put(newMessage);      // assign isarId
    await isar.chats.put(newChat);            // 3️⃣ Persist chat
    newChat.messages.add(newMessage);         // 4️⃣ Link init message safely
    await newChat.messages.save();            // Save the linked message to chat
    newChat.preview = newMessage.text;        // 5️⃣ Update preview and date
    newChat.date = newMessage.time;
    await isar.chats.put(newChat);
    savedChat = (await isar.chats.get(newChat.isarID))!; // 6️⃣ Re-fetch the fully managed chat and preload links
    await savedChat.messages.load();
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
