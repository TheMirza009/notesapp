import 'package:isar_community/isar.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:uuid/uuid.dart';

@collection
class Folder {
  Id isarID = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  String? name;
  DateTime date = DateTime.now();
  int sortOrder = 0;

  IsarLinks<Chat> chats = IsarLinks<Chat>();

  Folder() {
    uuid = const Uuid().v7();
  }
}