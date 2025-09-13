import 'package:isar/isar.dart';

part 'note_item.g.dart';

@collection
class NoteItem {
  Id id = Isar.autoIncrement; // internal ID
  IsarLink<TextData> textdata = IsarLink<TextData>();
  late int iconCode; // store icon as its code point

  NoteItem();
}

@collection
class TextData {
  Id id = Isar.autoIncrement;
  late String title;
  late String subtitle;

  @Backlink(to: "textdata")
  IsarLink<NoteItem> noteitem = IsarLink<NoteItem>();

  TextData();
}