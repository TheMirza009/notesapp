import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/models/user_model.dart';

class UserController extends StateNotifier<User?> {
  UserController() : super(null) {
    loadUser();
  }

  Future<void> loadUser() async {
    state = await IsarDatabase.loadUserData();
  }

  Future<void> updateUser(User updated) async {
    await IsarDatabase.isar.writeTxn(() async {
      await IsarDatabase.isar.users.put(updated);
    });
    state = updated;
  }
}

final userController = StateNotifierProvider<UserController, User?>((ref) => UserController());
