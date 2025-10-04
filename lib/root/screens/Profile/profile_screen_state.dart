import 'dart:io';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/widgets/custom_icon_dialogue.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/user_provider.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/user_model.dart';
import 'package:notesapp/root/screens/Settings/settings_screen.dart';
import 'package:share_plus/share_plus.dart';
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
  
Future<void> pickNewProfilePhoto() async {
  final pickedMedia = await MediaHandler.pickImage(isProfilePicture: true);
  if (pickedMedia == null) {
    print("❌ No media selected");
    return;
  }

  print("📷 Picked media: ${pickedMedia.path}");

  final currentUser = ref.read(userController);
  print("💳 Current User: ${currentUser.toString()}");
  if (currentUser == null) return;

  // Check if this media already exists in DB by path
  final existingMedia = await IsarDatabase.isar.medias
      .filter()
      .pathEqualTo(pickedMedia.path)
      .findFirst();
  final mediaToUse = existingMedia ?? pickedMedia;

  // Persist only if it's new
  if (existingMedia == null) {
    await IsarDatabase.isar.writeTxn(() async {
      await IsarDatabase.isar.medias.put(mediaToUse);
    });
  }

  // Always re-fetch the managed User from Isar
  final managedUser = await IsarDatabase.isar.users.get(currentUser.isarID);
  print("🗄️ DB says user.photo = ${managedUser?.profilePhotoPath}");

  if (managedUser == null) return;

  // Update user with new profile photo
  await IsarDatabase.isar.writeTxn(() async {
    managedUser.profilePhotoPath = mediaToUse.path;
    await IsarDatabase.isar.users.put(managedUser);
  });

  // Update state in provider
  await ref.read(userController.notifier).updateUser(managedUser);

  // Precache image
  _precacheProfileImage(mediaToUse.path);

  // Close the sheet/dialog
  if (context.mounted) {
    Navigator.pop(context);
  } else {
    final navCtx = navigatorKey.currentContext;
    if (navCtx != null) Navigator.pop(navCtx);
  }
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

  /// Menu callbacks
  Future<void> navigateToSettings() async {
    Navigator.push(context, CupertinoPageRoute(builder: (_) => SettingsScreen()));
  }

  Future<void> refer() async {
    await Share.share("Download NotesApp please :D");
  }

  Future<void> contactUs() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'themirza009@outlook.com',
    query: Uri.encodeFull('subject=Greetings&body=Good Day, Mirza AbdulMoeed'),
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    showCupertinoDialog(
      context: navigatorKey.currentContext!,
      builder: (_) => CustomAlertDialog(
        title: "Error",
        content: "Failed to open email app.",
        iconColor: Colors.redAccent,
        iconData: Mdi.error,
        iconSize: 25,
      ),
    );
  }
  }
}
