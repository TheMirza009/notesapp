import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/root/data/enums/chatlist_filter.dart';
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
  Color? textColor,
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
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: textColor
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

/// Options: Chat Filter
List<PopupMenuItem<String>> get chatFilterOptions => [
  PopupMenuItem(
    value: ChatlistFilter.alphabetical.name,
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.sortAZ, scale: 1.3),
      text: "Alphabetical",
    ),
  ),
  PopupMenuItem(
    value: ChatlistFilter.newestCreated.name,
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.sortUP, scale: 1.3),
      text: "Newest created",
    ),
  ),
  PopupMenuItem(
    value: ChatlistFilter.oldestCreated.name,
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.sortDOWN, scale: 1.3),
      text: "Oldest created",
    ),
  ),
  PopupMenuItem(
    value: ChatlistFilter.newestModified.name,
    child: buildOptionTile(
      icon: SizedBox(width: 18, child: vectorBuild(IconPaths.sortNEW, scale: 1.3)),
      text: "Newest modified",
    ),
  ),
  PopupMenuItem(
    value: ChatlistFilter.oldestModified.name,
    child: buildOptionTile(
      icon: SizedBox(width: 18, child: vectorBuild(IconPaths.sortOLD, scale: 1.3)),
      text: "Oldest modified",
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

/// Options: Chat Screen
List<PopupMenuItem<String>> get galleryOptions => [
  PopupMenuItem(
    value: 'croppy',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.crop2),
      text: "Crop Image",
      textColor: ThemeConstants.textDark2
    ),
  ),
  PopupMenuItem(
    value: 'shareImage',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.shareIcon2),
      text: "Share Image",
      textColor: ThemeConstants.textDark2
    ),
  ),
  PopupMenuItem(
    value: 'forwardimage',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.forward2),
      text: "Forward Image",
      textColor: ThemeConstants.textDark2
    ),
  ),
  PopupMenuItem(
    value: 'setChatPhoto',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.mediaGallery),
      text: "Set as Chat Photo",
      textColor: ThemeConstants.textDark2
    ),
  ),
  PopupMenuItem(
    value: 'setProfilePhoto',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.messageSearch),
      text: "Set as Profile Photo",
      textColor: ThemeConstants.textDark2
    ),
  ),
  PopupMenuItem(
    value: 'deleteImage',
    child: buildOptionTile(
      icon: clearIcon(),
      text: "Delete from Chat",
      textColor: ThemeConstants.textDark2
    ),
  ),
];

/// Options: Message Hold
List<PopupMenuItem<String>> messageHoldOptions({bool isMedia = false})  => [
  if (isMedia) PopupMenuItem(
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
  if (!isMedia) PopupMenuItem(
    value: 'edit',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.editText),
      text: "Edit Text",
    ),
  ),
  PopupMenuItem(
    value: 'forward',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.forward3),
      text: "Forward",
    ),
  ),
  PopupMenuItem(
    value: 'copy',
    child: buildOptionTile(
      icon: vectorBuild(IconPaths.copy),
      text: "Copy",
    ),
  ),
  if (isMedia) PopupMenuItem(
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

/// Options: Theme options
List<PopupMenuItem<String>> get themeOptions => [
  PopupMenuItem(
    value: 'light',
    child: buildOptionTile(
      icon: Icon(Icons.light_mode_outlined),
      text: "Light Mode",
    ),
  ),
  PopupMenuItem(
    value: 'dark',
    child: buildOptionTile(
      icon: Icon(Icons.dark_mode_outlined),
      text: "Dark Mode",
    ),
  ),
  PopupMenuItem(
    value: 'systemDefault',
    child: buildOptionTile(
      icon: Icon(Icons.phone_android_outlined),
      text: "System Default",
    ),
  ),
];

/// Options: Theme options
List<PopupMenuItem<String>> get bubbleStyleOptions => [
  PopupMenuItem(
    value: 'opaque',
    child: buildOptionTile(
      icon: Icon(Icons.opacity),
      text: "Opaque Style",
    ),
  ),
  PopupMenuItem(
    value: 'glass',
    child: buildOptionTile(
      icon: Icon(CupertinoIcons.cube),
      text: "Glass Style",
    ),
  ),
];

