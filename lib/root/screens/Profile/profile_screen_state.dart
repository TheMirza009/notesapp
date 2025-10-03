import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/models/user_model.dart';
import 'profile_screen.dart';

/// Base state class that holds all the logic and state
abstract class ProfileScreenBaseState extends ConsumerState<ProfileScreen> {
  late TextEditingController titleController;
  late FocusNode focusNode;
  bool isEditing = false;
  String name = "Name";

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    titleController = TextEditingController(text: name);
    loadUserData();
  }

  @override
  void dispose() {
    titleController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void loadUserData() async {
    final User? userData = await IsarDatabase.loadUserData();
    setState(() {
      name = userData?.name ?? "name";
      titleController.text = name;
    });
  }

  void saveUserData() async {
    final User currentUser = User()
    ..isarID = 0
    ..name = name;
    await IsarDatabase.isar.writeTxn(() async {
      await IsarDatabase.isar.users.put(currentUser);
    });
  }

  void startEditing() {
    isEditing = true;
    Future.delayed(Duration.zero, () {
      focusNode.requestFocus();
      titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: titleController.text.length),
      );
    });
  }

  void finishEditing() {
    final newText = titleController.text.trim();
    name = newText;
    isEditing = false;
    focusNode.unfocus();
    saveUserData();
  }
}
