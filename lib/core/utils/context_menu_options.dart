import 'package:flutter/material.dart';

Widget buildOptionTile({required Widget icon, required String text}) {
  return Row(
    spacing: 10,
    children: [icon, Text(text)],
    );
}

/// HomeScreenOptions
const List<PopupMenuItem<String>> homeScreenOptions = [
  PopupMenuItem<String>(value: 'profile', child: Text('Profile')),
  PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
  PopupMenuItem<String>(value: 'deleteAll', child: Text('Delete All Chats')),
];

/// Chat Screen options
List<PopupMenuItem<String>> chatScreenOptions = [
  PopupMenuItem<String>(value: 'chatInfo', child: buildOptionTile(icon: Icon(Icons.info_outline_rounded), text: "Chat info")),
  PopupMenuItem<String>(value: 'chatMedia', child: buildOptionTile(icon: Icon(Icons.info_outline_rounded), text: "Chat info")),
  PopupMenuItem<String>(value: 'search', child: buildOptionTile(icon: Icon(Icons.info_outline_rounded), text: "Chat info")),
  PopupMenuItem<String>(value: 'clearChat', child: buildOptionTile(icon: Icon(Icons.info_outline_rounded), text: "Chat info")),
];
