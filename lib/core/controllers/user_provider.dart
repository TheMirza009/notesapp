import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/models/user_model.dart';

class UserController extends StateNotifier<User?> {
  UserController() : super(null) {
    loadUser();
  }

  Future<void> loadUser() async {
    final existing = await IsarDatabase.isar.users.where().findFirst();
    if (existing != null) {
      state = existing;
    } else {
      // ✅ create a default user if none exists
      final defaultUser =
          User()
            ..name = "New User"
            ..profilePhotoPath = null;
      await IsarDatabase.isar.writeTxn(() async {
        await IsarDatabase.isar.users.put(defaultUser);
      });
      state = defaultUser;
    }
  }

  Future<void> updateUser(User updated) async {
    await IsarDatabase.isar.writeTxn(() async {
      await IsarDatabase.isar.users.put(
        updated,
      ); // ✅ put() already acts as upsert in Isar
    });

    // If no state yet, just set the whole user
    if (state == null) {
      state = updated;
    } else {
      // Merge with existing state
      state = state!.copyWith(
        name: updated.name,
        profilePhotoPath: updated.profilePhotoPath,
      );
    }
  }
}

final userController = StateNotifierProvider<UserController, User?>( (ref) => UserController(), );