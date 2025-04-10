import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';

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
      backgroundColor: ThemeConstants.toolbarLight,
      elevation: 1.0,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context); // Placeholder
        },
        icon: Icon(Icons.arrow_back, color: ThemeConstants.iconLight),
      ),
      title: InkWell(
        onTap: onTitleTap,
        child: Transform.translate(
          offset: Offset(-15, 0),
          child: SizedBox(
            width: double.maxFinite,
            child: Row(
              children: [
                Icon(
                  Icons.account_circle,
                  size: 50.0, // Icon size inside the circle
                ),
                SizedBox(width: ThemeConstants.screenWidth * 0.015,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ThemeConstants.screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textLight,
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
