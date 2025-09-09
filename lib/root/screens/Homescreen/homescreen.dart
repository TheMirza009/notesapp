import 'dart:io';

import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_tile.dart';
import 'package:notesapp/root/widgets/custom_context_menu.dart';
import 'package:notesapp/root/screens/chat_screen/chat_screen.dart';
import 'package:notesapp/root/widgets/custom_icon_button.dart';
import 'package:notesapp/root/widgets/custom_icon_dialogue.dart';
import 'package:svg_flutter/svg.dart';


class Homescreen extends ConsumerWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Declarations
    Size screensize = MediaQuery.sizeOf(context);
    final List<Chat> chatlist = ref.watch(chatListProvider);
    final chatNotifier = ref.read(chatListProvider.notifier);
    bool isLight = Theme.brightnessOf(context) == Brightness.light;
    LinearGradient backgroundGradient = isLight ? Gradients.lightBackground : Gradients.darkBackground;
    Color headerColor =  isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
    String addNotePath = isLight ? IconPaths.addNoteLight : IconPaths.addNoteDark;

    void handleContextMenuAction(value) {
      switch (value) {
        case "profile": print("Profile");
        case "settings": print("Settings");
        case "deleteAll":
          showCupertinoDialog(
            context: context,
            builder:
                (_) => CustomAlertDialog(
                  title: "Delete all notes",
                  content: "Are you sure you want to delete all notes?",
                  iconColor: Colors.redAccent,
                  iconData: (Mdi.delete_empty_outline), // (IconParkTwotone.delete_five), // Iconify(Fluent.delete_28_regular)
                  iconSize: 25,
                  option: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      chatNotifier.clearChats();
                    },
                    child: Text(
                      "Delete",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
          );
      }
    }

    Widget circularAvatar() => CustomIconButton(
      size: 40,
      backgroundColor: Colors.transparent,
      splashColor: const Color.fromARGB(144, 164, 182, 191),
      icon: ClipRRect(
        borderRadius: BorderRadiusGeometry.circular(100),
        child: Transform.scale(
          scale: 0.94,
          child: Image.asset(isLight ? IconPaths.avatarLight : IconPaths.avatarDark),
        ),
      ),
      onPressed: () {
        ref.read(themeNotifierProvider.notifier).toggleTheme();
      },
    );

    return Scaffold(
      floatingActionButton: CustomIconButton(
        size: 60,
        splashColor: const Color.fromARGB(14, 96, 125, 139),
        onPressed: () {
          Chat newChat = Chat.emptyChat();
          chatNotifier.addChat(newChat);
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => ChatScreen(chatId: newChat.id)),
          );
        },
        icon:  Image.asset(IconPaths.addNoteLight, scale: 10,), // addNotePath
      ),
      appBar: AppBar(
        // backgroundColor: ThemeConstants.hometoolbarLight,
        elevation: 0,
        backgroundColor: headerColor,
        shadowColor: Colors.transparent,
        toolbarHeight: 65,
        title: const Text("NotesApp", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: circularAvatar(),
        ),
        actions: [
          CustomContextMenu(
            icon: const Icon(Icons.more_vert),
            menuItems: dummyOptions,
            onSelected: (value) => handleContextMenuAction(value)
          ),
        ],
      ),
      body: Container(
        height: screensize.height,
        width: screensize.width,
        padding: EdgeInsets.only(top: 12),
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: 
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 8, right: 0),
              child: Row(
                spacing: Platform.isWindows ? 5 : 0,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 40,
                      ),
                      child: SearchBar(
                        autoFocus: false,
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12))),
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        shadowColor: WidgetStatePropertyAll(Colors.transparent),
                        backgroundColor: WidgetStatePropertyAll(headerColor),
                        leading: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.search, color: ThemeConstants.iconLight,),
                        ),
                        hintText: "Search in notes...",
                        hintStyle: WidgetStatePropertyAll(TextStyle(color: ThemeConstants.iconLight, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: IconButton(onPressed: () {}, icon: Icon(Icons.filter_list, color: ThemeConstants.iconLight,)))
                ],
              ),
            ),
            Expanded(
              child: chatlist.isEmpty
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: SvgPicture.asset(
                        IconPaths.nothing,
                        colorFilter: ColorFilter.mode(
                          Colors.blueGrey,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                itemCount: chatlist.length,
                itemBuilder: (context, index) {
                  final chat = chatlist[index];
                   return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: ChatTile(
                      title: chat.title!,
                      subtitle: chat.preview,
                      time: TimeFormat.formatChatTime(chat.date),
                      onDismissed: (_) => chatNotifier.removeChat(chat),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (_) => ChatScreen(chatId: chat.id)),
                          );
                      },
                    ),
                  );
                },
                separatorBuilder: (context, index) => Divider(
                  thickness: 1,
                  indent: ThemeConstants.screenWidth * (1 - 0.93),
                  color: isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkIconBorder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget buildContextMenuArea({
//   required Widget child,
//   required List<Widget> menuItems,
// }) {
//   return ContextMenuArea(
//     child: Padding(padding: const EdgeInsets.all(8.0), child: child),
//     builder: (context) {
//       return menuItems;
//       },
//   );
// }