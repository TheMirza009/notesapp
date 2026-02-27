import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
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
    var backgroundColor = context.isLight ? ThemeConstants.toolbarLight : ThemeConstants.messageBarDark;
    var textcolor = context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark2;
    var timeString = "Last edited ${TimeFormat.formatChatSubtitle(lastEdited)}";
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 1.0,
      titleSpacing: 0,
      toolbarHeight: 65,
      leading: leading ?? IconButton(
        onPressed: () {
          Navigator.pop(context); // Placeholder
        },
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: ThemeConstants.iconColorNeutral),
      ),
      title: InkWell(
        onTap: onTitleTap,
        child: Transform.translate(
          offset: Offset(-10, 0),
          child: SizedBox(
            width: double.maxFinite,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Row(
                key: ValueKey(isSelecting),
                children: [
                  chatPhotoPath == null
                      ? DocumentIcon(size: 40)
                      : Container(
                        height: 40,
                        width: 40,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: RepaintBoundary(
                          child: Image.file(
                            File(chatPhotoPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  // Icon(
                  //   Icons.account_circle,
                  //   size: 50.0, // Icon size inside the circle
                  // ),
                  SizedBox(width: ThemeConstants.screenWidth * 0.02,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: isSelecting! ? 23 : 22, // ThemeConstants.screenWidth * (isSelecting! ? 0.05 : 0.045),
                          fontWeight: FontWeight.w500,
                          color: textcolor,
                        ),
                      ),
                      if (!isSelecting!) Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5, // ThemeConstants.screenWidth * 0.03,
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
          onPressed: onSearchTap,
          icon: Icon(Icons.search), // color: ThemeConstants.iconLight),
        ),
        if (showActionsIcon!) CustomContextMenu(
          icon: Icon(Icons.more_vert), 
          menuItems: chatScreenOptions, 
          onSelected: (value) => onOptionsPressed!(value) ,
          )
      ],
    );
  }
}
