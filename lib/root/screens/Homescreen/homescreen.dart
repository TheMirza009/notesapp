import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/dummy_data/dummy_chats.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_tile.dart';
import 'package:notesapp/root/widgets/clickable_circle.dart';
import 'package:notesapp/root/widgets/custom_context_menu.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen.dart';

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  

  @override
  Widget build(BuildContext context) {

    var testData = [
    ListTile(
      leading: Icon(Icons.account_circle, size: 50),
      title: Text(
        "Note 1",
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      subtitle: Text("And as we move closer towards the..."),
      trailing: Text(
        "${DateTime.now().hour.toString()} : ${DateTime.now().minute.toString()}",
      ),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen()),
          ),
    ),
    Divider(),
    ChatTile(
      title: "Grid Computing",
      subtitle: "Grid Computing is a form of parallel computing....",
      time: "17:01",
      showDivider: true,
      onTap: () {
        print("NOTE");
      },
    ),
  ];

    return Scaffold(
      floatingActionButton: IconButton.filled(
        onPressed: () {},
        icon: Icon(Icons.add, size: 40),
      ),
      appBar: AppBar(
        elevation: 10,
        toolbarHeight: 70,
        title: const Text("NotesApp", style: TextStyle(fontSize: 22)),
        leading: Container(
          color: Colors.transparent, // Ensure no background color
          child: ClickableCircle(
            splashColor: Colors.grey.withOpacity(0.2), // Optional: Splash color
            onTap: () {},
            onLongPress: () {},
            child: Icon(
              Icons.account_circle,
              size: 40.0, // Adjust size as needed)
            ),
          ),
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
        decoration: BoxDecoration(gradient: ThemeConstants.lightBackground),
        child: ListView(
          children:
              dummyChats.map((chat) => ChatTile(
                      title: chat.title,
                      subtitle: chat.preview,
                      time: "17:51",
                      onTap:() => Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (_) => ChatScreen(chat: chat,)),
                          ),
                    ),
                  )
                  .toList(),
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
