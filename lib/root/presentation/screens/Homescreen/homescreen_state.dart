import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/controllers/user_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/windows_utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/chatlist_filter.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/chat_screen.dart';
import 'package:notesapp/root/presentation/screens/Settings/settings_screen.dart';
import 'package:notesapp/root/presentation/widgets/custom_icon_button.dart';
import 'package:notesapp/root/presentation/widgets/custom_icon_dialogue.dart';
import 'package:notesapp/core/controllers/tutorial/tutorial_service.dart';
import 'package:notesapp/root/domain/usecases/delete_chat_usecase.dart';
import 'homescreen.dart';

abstract class HomeScreenBaseState extends ConsumerState<Homescreen> {
  final FocusNode searchFocusNode = FocusNode(canRequestFocus: false);
  final TextEditingController searchController = TextEditingController();
  bool tutorialActive = false;
  bool isSliding = false;
  ChatlistFilter filter = ChatlistFilter.oldestCreated;
  DateTime? lastBackPress;
  
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async { // Note the async here
    ref.read(userController.notifier).loadUser();
    ref.read(chatListProvider.notifier).applyFilter(filter);

    // 1. Check if the tutorial SHOULD show
    bool needsTutorial = await TutorialService.shouldShow(TutorialKey.homeScreen);

    if (!needsTutorial) {
      // If no tutorial is needed, ensure the flag is false and exit early
      if (mounted) setState(() => tutorialActive = false);
      return;
    }

    // 2. Only lock the UI if we are actually going to show it
    if (mounted) setState(() => tutorialActive = true);

    // Safety unlock (5s fallback)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && tutorialActive) {
        setState(() => tutorialActive = false);
        TutorialService.dismiss();
      }
    });

    // Show the tutorial
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      TutorialService.showHomeScreenHelp(
        onDismissed: () {
          if (mounted) setState(() => tutorialActive = false);
        },
      );
    });

    _checkPendingDeletions();
  });
}

  Future<void> _checkPendingDeletions() async {
    final useCase = ref.read(deleteChatUseCaseProvider);
    final count = await useCase.getAndClearPendingDeletions();
    if (count > 0 && mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
            title: "Chats Restored",
            content: "Deleted chats were restored due to the app closing unexpectedly.",
            iconData: Mdi.restore,
          );
        },
      );
    }
  }


  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void clearSearch() {
    searchController.clear();
    searchFocusNode.unfocus();
    ref.read(chatListProvider.notifier).clearSearch();
  }

  Future<void> navigateToChatScreen(Chat chat) async {
  // 1. Select chat immediately (lightweight)
  ref.read(chatListProvider.notifier).selectChat(chat);
  
  // 2. Navigate FIRST (don't wait for data)
  if (mounted) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const ChatScreen()),
    );
  }
  
  // 3. Load data in background (optional - ChatScreen will handle it)
  chat.messages.load().then((_) {  // This happens AFTER navigation starts
    Future.wait(chat.messages.map((m) => m.media.load()));
  });
}

  Future<void> createNewChat() async {
    if (tutorialActive) return;
    final newChat = await ref.read(chatListProvider.notifier).addChat();
    await newChat.messages.load();
    ref.read(chatListProvider.notifier).selectChat(newChat);
    await newChat.messages.load();
    ref.read(isNewChat.notifier).state = true;
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void handleContextMenuAction(String value) {
    final chatNotifier = ref.read(chatListProvider.notifier);

    switch (value) {
      case "profile":
        setState(() => isSliding = true);
        WindowsUtils.setTitleBarColorDirect(context.isLight ? Gradients.silverSunlight2 : Gradients.shadowBlue);
        break;
      case "settings":
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const SettingsScreen()),
        );
        WindowsUtils.setTitleBarColorDirect(context.isLight ? Gradients.silverSunlight2 : Gradients.shadowBlue);
        break;
      case "deleteAll":
        showCupertinoDialog(
          context: context,
          builder: (_) => CustomAlertDialog(
            title: "Delete all notes",
            content: "Are you sure you want to delete all notes?",
            iconColor: Colors.redAccent,
            iconData: Mdi.delete_empty_outline,
            iconSize: 25,
            option: TextButton(
              onPressed: () {
                Navigator.pop(context);
                chatNotifier.clearChats();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        );
        break;
    }
  }

  void handleChatFilter(String value) {

  }

  Widget circularAvatar(bool isLight) {
    final String? path = ref.watch(userController)?.profilePhotoPath;

    return CustomIconButton(
      size: 40,
      backgroundColor: Colors.transparent,
      splashColor: const Color.fromARGB(144, 164, 182, 191),
      icon: ClipOval(
        child: SizedBox(
          width: 40,
          height: 40,
          child: Transform.scale(
            scale: 1,
            child: path != null
                ? Image.file(File(path), fit: BoxFit.cover)
                : Image.asset(isLight ? IconPaths.avatarLight : IconPaths.avatarDark, fit: BoxFit.cover),
          ),
        ),
      ),
      onPressed: () {
        setState(() => isSliding = true);
        WindowsUtils.setTitleBarColorDirect(context.isLight ? Gradients.silverSunlight2 : Gradients.shadowBlue);
      },
    );
  }

}