import 'dart:io';
import 'package:croppy/croppy.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:isar_community/isar.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/widgets/custom_icon_dialogue.dart';
import 'package:notesapp/root/widgets/photo_view/croppyImage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final pickedMedia = await MediaHandler.pickImage(
      isProfilePicture: true,
      useCroppy: true,
    );
    if (pickedMedia == null) {
      debugPrint("❌ No media selected");
      return;
    }
    
    debugPrint("📷 Picked media: ${pickedMedia.path}");

    final currentUser = ref.read(userController);
    debugPrint("💳 Current User: ${currentUser.toString()}");
    if (currentUser == null) return;

    // Check if this media already exists in DB by path
    final existingMedia =
        await IsarDatabase.isar.medias
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
    debugPrint("🗄️ DB says user.photo = ${managedUser?.profilePhotoPath}");

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
    final String subject = Uri.encodeComponent('Greetings');
    final String body = Uri.encodeComponent('Good Day, Mirza AbdulMoeed');
    final Uri emailUri = Uri.parse(
      'mailto:themirza009@outlook.com?subject=$subject&body=$body',
    );


    try {
      // Try default mail app
      if (await canLaunchUrl(emailUri)) {
        final launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) return; // ✅ success, stop here
      }

      // Fallback to Outlook Web compose
      final fallback = Uri.parse(
        'https://outlook.live.com/mail/0/deeplink/compose'
        '?to=themirza009@outlook.com'
        '&subject=Greetings'
        '&body=Good%20Day%2C%20Mirza%20AbdulMoeed',
      );

      if (await canLaunchUrl(fallback)) {
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
        return;
      }

      // ❌ If neither method works, show dialog
      _showMailErrorDialog();
    } catch (e) {
      debugPrint('❌ contactUs error: $e');
      _showMailErrorDialog();
    }
  }

  void _showMailErrorDialog() {
    showCupertinoDialog(
      context: navigatorKey.currentContext!,
      builder:
          (_) => CustomAlertDialog(
            title: "Error",
            content: "Failed to open email app.",
            iconColor: Colors.redAccent,
            iconData: Mdi.error,
            iconSize: 25,
          ),
    );
  }


  
Widget nameBuilderSimple() {
  const Color darkPrimary = Color(0xFF81D3DF);
  return Padding(
    padding: const EdgeInsets.only(top: 8.0, bottom: 26),
    child: Center(
      child: Transform.translate(
        offset: Offset(22, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.screenWidth - 100),
              child: IntrinsicWidth(
                child: TextField(
                  focusNode: focusNode,
                  enableInteractiveSelection: isEditing,
                  controller: titleController,
                  autofocus: isEditing,
                  readOnly: !isEditing,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  onSubmitted: (value) => setState(() => finishEditing()),
                  style: const TextStyle(
                    fontSize: 21.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            IconButton(
              icon:
                  !isEditing
                      ? vectorBuild(
                        IconPaths.pencil,
                        color:
                            context.isDark
                                ? ThemeConstants.circleIconBackgroundLight
                                : ThemeConstants.darkIconbackground,
                      )
                      : vectorBuild(
                        IconPaths.tick,
                        scale: 1.2,
                        color:
                            context.isDark
                                ? darkPrimary
                                : ThemeConstants.sinisterSeed,
                      ),
              onPressed: () {
                if (isEditing) {
                  finishEditing();
                  setState(() {});
                } else {
                  startEditing();
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}


  
Widget nameBuilderBordered(){
  final dividerColor = navigatorKey.currentContext!.isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkIconBorder;
  return Container(
    margin: const EdgeInsets.all(30),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
    decoration: BoxDecoration(
      border: Border.all(width: 1.5, color: dividerColor),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5.0, right: 20),
          child: vectorBuild(IconPaths.userHUGE),
        ),
        Expanded(
          child: TextField(
            focusNode: focusNode,
            enableInteractiveSelection: isEditing,
            controller: titleController,
            autofocus: isEditing,
            readOnly: !isEditing,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
            ),
            style: const TextStyle(
              fontSize: 21.5,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit),
          onPressed: () {
            if (isEditing) {
              finishEditing();
              setState(() {});
            } else {
              startEditing();
              setState(() {});
            }
          },
        ),
      ],
    ),
  );
}
}



Future<void> saveNewProfilePhoto(WidgetRef ref, Media media) async {
    final pickedMedia = media;
    if (pickedMedia == null) {
      debugPrint("❌ No media selected");
      return;
    }

    debugPrint("📷 Picked media: ${pickedMedia.path}");

    final currentUser = ref.read(userController);
    debugPrint("💳 Current User: ${currentUser.toString()}");
    if (currentUser == null) return;

    // Check if this media already exists in DB by path
    final existingMedia =
        await IsarDatabase.isar.medias
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
    debugPrint("🗄️ DB says user.photo = ${managedUser?.profilePhotoPath}");

    if (managedUser == null) return;

    // Update user with new profile photo
    await IsarDatabase.isar.writeTxn(() async {
      managedUser.profilePhotoPath = mediaToUse.path;
      await IsarDatabase.isar.users.put(managedUser);
    });

    // Update state in provider
    await ref.read(userController.notifier).updateUser(managedUser);
  }

