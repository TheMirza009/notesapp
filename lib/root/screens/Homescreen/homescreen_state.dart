import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/controllers/user_provider.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/chatlist_filter.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Chat_screen/chat_screen.dart';
import 'package:notesapp/root/screens/Load_test/screens/slide_screen_test.dart';
import 'package:notesapp/root/screens/Settings/settings_screen.dart';
import 'package:notesapp/root/widgets/custom_icon_button.dart';
import 'package:notesapp/root/widgets/custom_icon_dialogue.dart';
import 'homescreen.dart';

abstract class HomeScreenBaseState extends ConsumerState<Homescreen> {
  final FocusNode searchFocusNode = FocusNode(canRequestFocus: false);
  final TextEditingController searchController = TextEditingController();
  bool isSliding = false;
  ChatlistFilter filter = ChatlistFilter.oldestCreated;
  DateTime? lastBackPress;

  @override
  void initState() {
    super.initState();
    ref.read(userController.notifier).loadUser();
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
        break;
      case "settings":
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const SettingsScreen()),
        );
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
      onPressed: () => setState(() => isSliding = true),
    );
  }

}