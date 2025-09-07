import 'package:flutter/material.dart';

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
    Key? key,
    required this.icon,
    this.menuItems = dummyOptions,
    this.onSelected, /// Does not work without menuItems
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: icon,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => menuItems,
    );
  }
}
