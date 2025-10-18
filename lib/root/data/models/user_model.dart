
import 'package:isar_community/isar.dart';
part 'user_model.g.dart';

@collection
class User {
  Id isarID = 0;

  late String name;
  String? profilePhotoPath;

  User() {
    name = "Name";
    profilePhotoPath = null;
  }

  User copyWith({
    String? name,
    String? profilePhotoPath,
  }) {
    final newUser = User()
    ..name = name ?? this.name
    ..profilePhotoPath = profilePhotoPath ?? this.profilePhotoPath;

    return newUser;
  }
}

