import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/lucide.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:svg_flutter/svg.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_outline.dart';
 // widget

 // widget

Widget buildOptionTile({required Widget icon, required String text}) { // Iconify(Ph.user_bold, color: ThemeConstants.iconColorNeutral)
  return Row(
    spacing: 10,
    children: [Padding(
      padding: const EdgeInsets.all(3.0),
      child: icon,
    ), Text(text, style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16),)],
    );
}

Widget clearIcon() {
  return Transform.scale(
    scale: 1.245,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.string(IconPaths.stopRounded, color: ThemeConstants.iconColorNeutral),
        Icon(Icons.clear_rounded, size: 12, color: ThemeConstants.iconColorNeutral,),
      ],
    ),
  );
}

Transform scaledVector() {
  return Transform.scale(
  scale: 0.9,
  child: SvgPicture.string(IconPaths.clearChatString, color: ThemeConstants.iconColorNeutral,));
}

/// HomeScreenOptions
 List<PopupMenuItem<String>> homeScreenOptions = [
  PopupMenuItem<String>(value: 'profile', child: buildOptionTile(icon: SvgPicture.string(IconPaths.userHUGE, color: ThemeConstants.iconColorNeutral,),  text: "Profile")),
  PopupMenuItem<String>(value: 'settings', child: buildOptionTile(icon: SvgPicture.string(IconPaths.setting1, color: ThemeConstants.iconColorNeutral,), text: 'Settings')),
  PopupMenuItem<String>(value: 'deleteAll', child: buildOptionTile(icon: SvgPicture.string(IconPaths.trash1, color: ThemeConstants.iconColorNeutral,), text: "Delete All")),
];

/// Chat Screen options
List<PopupMenuItem<String>> chatScreenOptions = [
  PopupMenuItem<String>(value: 'chatInfo', child: buildOptionTile(icon: SvgPicture.string(IconPaths.infoSquare, color: ThemeConstants.iconColorNeutral,), text: "Chat info")),
  PopupMenuItem<String>(value: 'chatMedia', child: buildOptionTile(icon: SvgPicture.string(IconPaths.mediaGallery, color: ThemeConstants.iconColorNeutral,), text: "Chat info")),
  PopupMenuItem<String>(value: 'search', child: buildOptionTile(icon: SvgPicture.string(IconPaths.messageSearch, color: ThemeConstants.iconColorNeutral,), text: "Search")),
  PopupMenuItem<String>(value: 'clearChat', child: buildOptionTile(icon: clearIcon(), text: "Clear Chat")),
];

/// Message Hold Options
 List<PopupMenuItem<String>> messageHoldOptions = [
  PopupMenuItem<String>(value: 'reply', child: buildOptionTile(icon: SvgPicture.string(IconPaths.messageReply, color: ThemeConstants.iconColorNeutral,),  text: "Reply")),
  PopupMenuItem<String>(value: 'deleteMessage', child: buildOptionTile(icon: SvgPicture.string(IconPaths.trash1, color: ThemeConstants.iconColorNeutral,),  text: "Delete")),
];

