import 'dart:ui';

import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';
import 'package:notesapp/root/screens/Homescreen/homescreen.dart';
import 'package:notesapp/root/widgets/custom_context_menu.dart';

class ChatAppBar extends StatelessWidget {
  final String title;
  final DateTime lastEdited;
  final VoidCallback onTitleTap;
  final void Function()? onOptionsPressed;

  const ChatAppBar({
    super.key, 
    required this.title,
    required this.lastEdited,
    required this.onTitleTap,
    this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    var backgroundColor = context.isLight ? ThemeConstants.toolbarLight : ThemeConstants.messageBarDark;
    var textcolor = context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark2;
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 1.0,
      titleSpacing: 0,
      toolbarHeight: 65,
      leading: IconButton(
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
            child: Row(
              children: [
                DocumentIcon(size: 40),
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
                        fontSize: ThemeConstants.screenWidth * 0.045,
                        fontWeight: FontWeight.w500,
                        color: textcolor,
                      ),
                    ),
                    Text(
                      "Last edited today at ${lastEdited.hour}:${lastEdited.minute}",
                      style: TextStyle(
                        fontSize: ThemeConstants.screenWidth * 0.03,
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
      actions: [
        IconButton(
          onPressed: () {
            print("Search tapped"); // Placeholder
          },
          icon: Icon(Icons.search), // color: ThemeConstants.iconLight),
        ),
        CustomContextMenu(icon: Icon(Icons.more_vert))
      ],
    );
  }
}
