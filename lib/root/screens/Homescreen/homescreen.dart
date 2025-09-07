import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/carbon.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/dummy_data/dummy_chats.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_tile.dart';
import 'package:notesapp/root/widgets/clickable_circle.dart';
import 'package:notesapp/root/widgets/custom_context_menu.dart';
import 'package:notesapp/root/screens/chat_screen/chat_screen.dart';
import 'package:notesapp/root/widgets/custom_icon_button.dart';
import 'package:svg_flutter/svg.dart';

class Homescreen extends ConsumerWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Declarations
    Size screensize = MediaQuery.sizeOf(context);
    final List<Chat> chatlist = ref.watch(chatListProvider);
    final chatNotifier = ref.read(chatListProvider.notifier);

    return Scaffold(
      floatingActionButton: CustomIconButton(
        splashColor: const Color.fromARGB(14, 96, 125, 139),
        onPressed: () {
          Chat newChat = Chat.emptyChat();
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => ChatScreen(chat: newChat)),
          );
            chatNotifier.addChat(newChat);
        },
        icon:  Image.asset(IconPaths.addNoteLight, scale: 10,),
      ),
      appBar: AppBar(
        // backgroundColor: ThemeConstants.hometoolbarLight,
        elevation: 0,
        backgroundColor: ThemeConstants.hometoolbarLight,
        shadowColor: Colors.transparent,
        toolbarHeight: 75,
        title: const Text("NotesApp", style: TextStyle(fontSize: 22)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: circularAvatar(),
        ),
        actions: [
          CustomContextMenu(
            icon: const Icon(Icons.more_vert),
            menuItems: dummyOptions,
            onSelected: (value) {
              switch(value) {
                case "profile" : print("Profile");
                case "settings" : print("Settings");
                case "deleteAll" : chatNotifier.clearChats();
              }
            },
          ),
        ],
      ),
      body: Container(
        height: screensize.height,
        width: screensize.width,
        padding: EdgeInsets.only(top: 12),
        decoration: BoxDecoration(gradient: Gradients.lightBackground),
        child: 
        chatlist.isEmpty
        ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: SvgPicture.asset(IconPaths.nothing, color: Colors.blueGrey,),
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
                time: "17:51",
                onDismissed: (_) => chatNotifier.removeChat(chat),
                onTap: () {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => ChatScreen(chat: chat)),
                    );
                },
              ),
            );
          },
          separatorBuilder: (context, index) => Divider(
                color: ThemeConstants.homeDividerLight,
                thickness: 1,
                indent: ThemeConstants.screenWidth * (1 - 0.93),
              ),
        ),
      ),
    );
  }
}

Widget buildContextMenuArea({
  required Widget child,
  required List<Widget> menuItems,
}) {
  return ContextMenuArea(
    child: Padding(padding: const EdgeInsets.all(8.0), child: child),
    builder: (context) => menuItems,
  );
}

Widget circularAvatar() => CustomIconButton(
  size: 40,
  backgroundColor: Colors.transparent,
  splashColor: const Color.fromARGB(144, 164, 182, 191),
  icon: ClipRRect(
    borderRadius: BorderRadiusGeometry.circular(100),
    child: Transform.scale(
      scale: 1.2,
      child: Iconify(
        Carbon.user_avatar_filled_alt,
        color: ThemeConstants.iconLight,
        size: 40,
      ),
    ),
  ),
  onPressed: () {
    // Handle tap
  },
);
