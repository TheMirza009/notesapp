import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/main.dart';
import 'package:notesapp/root/presentation/screens/Homescreen/components/chat_list/doc_icon.dart';
import 'package:notesapp/root/presentation/widgets/context_menus/custom_context_menu.dart';

class ChatAppBar extends StatelessWidget {
  final String title;
  final DateTime lastEdited;
  final VoidCallback onTitleTap;
  final Widget? leading;
  final bool? isSelecting;
  final bool? isEditing;
  final void Function(String value)? onOptionsPressed;
  final void Function()? onSearchTap;
  final List<Widget>? actions;
  final String? chatPhotoPath;
  final bool? showActionsIcon;

  const ChatAppBar({
    super.key, 
    required this.title,
    required this.lastEdited,
    required this.onTitleTap,
    required this.onSearchTap,
    this.leading,
    this.onOptionsPressed, 
    this.isSelecting = false,
    this.isEditing = false,
    this.actions,
    this.chatPhotoPath,
    this.showActionsIcon = true,
  });
@override
Widget build(BuildContext context) {
  final isDesktop = context.screenWidth >= 600;
  final isLight = context.isLight;

  final backgroundColor = isDesktop
      ? (isLight ? Gradients.silverGrey : Gradients.shadowBlue) // use as LinearGradient below
      : (isLight ? ThemeConstants.toolbarLight : ThemeConstants.messageBarDark);

  final dividerColor = isLight
      ? ThemeConstants.homeDividerLight
      : ThemeConstants.darkIconBorder;

  final textColor = isLight ? ThemeConstants.textLight : ThemeConstants.textDark2;
  final timeString = "Last edited ${TimeFormat.formatChatSubtitle(lastEdited)}";
  final toolbarHeight = isDesktop ? 60.0 : 65.0;

  return Container(
    decoration: BoxDecoration(
      color: isDesktop ? null : backgroundColor,
      border: isDesktop
          ? Border(bottom: BorderSide(color: dividerColor, width: 1))
          : null,
    ),
    child: AppBar(
      backgroundColor: Colors.transparent, // container handles color
      elevation: isDesktop ? 0 : 1.0,
      titleSpacing: 0,
      toolbarHeight: toolbarHeight,
      leading: leading ?? IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: ThemeConstants.iconColorNeutral),
      ),
      title: InkWell(
        onTap: onTitleTap,
        child: Transform.translate(
          offset: const Offset(-10, 0),
          child: SizedBox(
            width: double.maxFinite,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Row(
                key: ValueKey(isSelecting),
                children: [
                  // AVATAR
                  chatPhotoPath == null
                      ? DocumentIcon(size: isDesktop ? 30 : 40)
                      : Container(
                          height: isDesktop ? 30 : 40,
                          width: isDesktop ? 30 : 40,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: RepaintBoundary(
                            child: Image.file(File(chatPhotoPath!), fit: BoxFit.cover),
                          ),
                        ),
                  SizedBox(width: isDesktop ? 10 : ThemeConstants.screenWidth * 0.02),

                  // TITLE + SUBTITLE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: isDesktop ? 15 : (isSelecting! ? 23 : 22),
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      if (!isSelecting!)
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: isDesktop ? 11 : 13,
                            height: 1.5,
                            color: ThemeConstants.subtitleLight,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: actions ?? [
        IconButton(
          iconSize: isDesktop ? 18 : 24,
          onPressed: onSearchTap,
          icon: const Icon(Icons.search),
        ),
        if (showActionsIcon!)
          CustomContextMenu(
            icon: Icon(Icons.more_vert, size: isDesktop ? 18 : 24),
            menuItems: chatScreenOptions,
            onSelected: (value) => onOptionsPressed!(value),
          ),
        if (isDesktop) const SizedBox(width: 4),
      ],
    ),
  );
}
}
