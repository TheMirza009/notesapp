import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';

const List<PopupMenuItem<String>> dummyOptions = [
  PopupMenuItem<String>(value: 'profile', child: Text('Profile')),
  PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
  PopupMenuItem<String>(value: 'deleteAll', child: Text('Delete All Chats')),
];

class CustomContextMenu extends StatelessWidget {
  final Icon icon;
  final List<PopupMenuEntry<String>> menuItems;
  /// Does not work without menuItems
  final void Function(String)? onSelected;

  const CustomContextMenu({
    super.key,
    required this.icon,
    this.menuItems = dummyOptions,
    this.onSelected, /// Does not work without menuItems
  });

  @override
  Widget build(BuildContext context) {
    const lightBG = Color.fromARGB(255, 228, 239, 240);
    const darkBG = Color.fromARGB( 255, 34, 52, 65, );
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: context.isLight ? lightBG : darkBG, // ThemeConstants.homeSearchbarLight
        icon: icon,
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => menuItems,
      ),
    );
  }
}
