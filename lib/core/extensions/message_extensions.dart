import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';

extension MessageX on Message {
  bool get isImage {
    return media.value?.type == Mediatype.image;
  }
}
