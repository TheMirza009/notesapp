import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';

class ChatAppBar extends StatelessWidget {
  final String title;
  final DateTime lastEdited;
  final VoidCallback onTitleTap;

  const ChatAppBar({
    required this.title,
    required this.lastEdited,
    required this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.isLight ? ThemeConstants.toolbarLight : ThemeConstants.darkAppbar,
      elevation: 1.0,
      titleSpacing: 0,
      toolbarHeight: 65,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context); // Placeholder
        },
        icon: Icon(Icons.arrow_back, color: ThemeConstants.iconLight),
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
                        fontWeight: FontWeight.w600,
                        color: context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark2,
                      ),
                    ),
                    Text(
                      "Last seen today at ${lastEdited.hour}:${lastEdited.minute}",
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
          icon: Icon(Icons.search, color: ThemeConstants.iconLight),
        ),
        IconButton(
          onPressed: () {
            print("More options tapped"); // Placeholder
          },
          icon: Icon(Icons.more_vert, color: ThemeConstants.iconLight),
        ),
      ],
    );
  }
}
