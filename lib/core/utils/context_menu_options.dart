import 'package:flutter/material.dart';
import 'package:svg_flutter/svg.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/lucide.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:iconify_flutter/icons/heroicons_outline.dart';

import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';

/// Helper: build option row tile
Widget buildOptionTile({
  required Widget icon,
  required String text,
}) {
  return Row(
    spacing: 10,
    children: [
      Padding(
        padding: const EdgeInsets.all(3.0),
        child: icon,
      ),
      Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
      ),
    ],
  );
}

/// Helper: SVG icon with default theme color
Widget vectorBuild(String svgPath, {double? scale, Color? color}) {
  Widget svg = SvgPicture.string(
    svgPath,
    color: color ?? ThemeConstants.iconColorNeutral,
  );

  if (scale != null) {
    return Transform.scale(scale: scale, child: svg);
  }
  return svg;
}

/// Clear icon (special case with overlay)
Widget clearIcon() {
  return Transform.scale(
    scale: 1.245,
    child: Stack(
      alignment: Alignment.center,
      children: [
        vectorBuild(IconPaths.stopRounded),
        Icon(
          Icons.clear_rounded,
          size: 12,
          color: ThemeConstants.iconColorNeutral,
        ),
      ],
    ),
  );
}

/// Options: Home Screen
List<PopupMenuItem<String>> get homeScreenOptions => [
  PopupMenuItem(
    value: 'profile',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.userHUGE),
      text: "Profile",
    ),
  ),
  PopupMenuItem(
    value: 'settings',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.setting1),
      text: "Settings",
    ),
  ),
  PopupMenuItem(
    value: 'deleteAll',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.trash1),
      text: "Delete All",
    ),
  ),
];

/// Options: Chat Screen
List<PopupMenuItem<String>> get chatScreenOptions => [
  PopupMenuItem(
    value: 'chatInfo',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.infoSquare),
      text: "Chat info",
    ),
  ),
  PopupMenuItem(
    value: 'chatMedia',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.mediaGallery),
      text: "Chat media",
    ),
  ),
  PopupMenuItem(
    value: 'search',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.messageSearch),
      text: "Search",
    ),
  ),
  PopupMenuItem(
    value: 'clearChat',
    child: buildOptionTile(
      icon: clearIcon(),
      text: "Clear Chat",
    ),
  ),
];

/// Options: Message Hold
List<PopupMenuItem<String>> messageHoldOptions({bool isImage = false})  => [
  if (isImage) PopupMenuItem(
    value: 'toggleSender',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.switchSender2),
      text: "Toggle Sender",
    ),
  ),
  PopupMenuItem(
    value: 'reply',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.messageReply),
      text: "Reply",
    ),
  ),
  PopupMenuItem(
    value: 'copy',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.copy),
      text: "Copy",
    ),
  ),
  if (isImage) PopupMenuItem(
    value: 'share',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.shareIcon2),
      text: "Share",
    ),
  ),
  PopupMenuItem(
    value: 'deleteMessage',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.trash1),
      text: "Delete",
    ),
  ),
];
