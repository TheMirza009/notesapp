import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/user_provider.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/data/models/user_model.dart';
import 'profile_screen.dart';

/// Base state class that holds UI logic but delegates data to UserController
abstract class ProfileScreenBaseState extends ConsumerState<ProfileScreen> {
  late TextEditingController titleController;
  late FocusNode focusNode;
  bool isEditing = false;

    @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    titleController = TextEditingController();
    final user = ref.read(userController);
    if (user?.profilePhotoPath != null) {
    _precacheProfileImage(user!.profilePhotoPath);
    }
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  //   // Move ref.listen here (allowed in lifecycle after initState)
  //   ref.listen<User?>(userController, (prev, next) {
  //     if (next != null && next.name != titleController.text && !isEditing) {
  //       titleController.text = next.name;
  //     }
  //   });
  // }

  @override
  void dispose() {
    titleController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  /// Start editing the name field
  void startEditing() {
    setState(() => isEditing = true);
    Future.delayed(Duration.zero, () {
      focusNode.requestFocus();
      titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: titleController.text.length),
      );
    });
  }

  /// Finish editing and update user data
  void finishEditing() {
    final newText = titleController.text.trim();
    final user = ref.read(userController);
    if (user != null) {
      final updated = user.copyWith(name: newText);
      ref.read(userController.notifier).updateUser(updated);
    }
    setState(() => isEditing = false);
    focusNode.unfocus();
  }

  /// Pick and save a new profile photo
  void pickNewProfilePhoto() async {
    final croppedPhoto = await MediaHandler.pickImage(isProfilePicture: true);
    if (croppedPhoto == null) return;

    final user = ref.read(userController);
    if (user != null) {
      final updated = user.copyWith(profilePhotoPath: croppedPhoto.path);
      await ref.read(userController.notifier).updateUser(updated);
       _precacheProfileImage(croppedPhoto.path);
    }
    Navigator.pop(context.mounted ? context : navigatorKey.currentContext!);
  }

  void _precacheProfileImage(String? path) {
    if (path == null) return;

    // Wrap in try/catch in case file doesn't exist yet
    try {
      precacheImage(FileImage(File(path)), context);
    } catch (e) {
      debugPrint('Error precaching profile image: $e');
    }
  }


  void removeProfilePhoto() {
    final user = ref.read(userController);
    final removedUser = user!.copyWith(profilePhotoPath: null);
    ref.read(userController.notifier).updateUser(removedUser);
  }
}
