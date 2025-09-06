import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/carbon.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/dummy_data/dummy_chats.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_tile.dart';
import 'package:notesapp/root/widgets/clickable_circle.dart';
import 'package:notesapp/root/widgets/custom_context_menu.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen.dart';
import 'package:notesapp/root/widgets/custom_icon_button.dart';

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  

  @override
  Widget build(BuildContext context) {

    Widget circularAvatar() => CustomIconButton(
            size: 30,
            backgroundColor: ThemeConstants.iconLight,
            icon: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(100),
              child: Transform.scale(
                scale: 1.2,
                child: Iconify(
                  Carbon.user_avatar_filled_alt,
                  color: ThemeConstants.circleIconLight,
                  size: 50,
                ),
              ),
            ),
            onPressed: () {
              // Handle tap
            },
          );

    

    return Scaffold(
      floatingActionButton: IconButton.filled(
        onPressed: () {},
        icon: Icon(Icons.add, size: 40),
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
            onSelected: (value) => print(value),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.only(top: 12),
        decoration: BoxDecoration(gradient: Gradients.lightBackground),
        child: ListView.separated(
          itemCount: dummyChats.length,
          itemBuilder: (context, index) {
            final chat = dummyChats[index];
            return Column(
              children: [
                ChatTile(
                  title: chat.title,
                  subtitle: chat.preview,
                  time: "17:51",
                  onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => ChatScreen(chat: chat)),
                      ),
                ),
              ],
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
