import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';

class ChatTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool showDivider;
  final Widget? chatIcon;
  final Widget? trailing;
  final String? chatPhotoPath;
  final VoidCallback? onTap; // Nullable onTap function
  final VoidCallback? onLongPress;
  final  Function(DismissDirection)? onDismissed;
  final bool? isDismissible;

  // Constructor
  const ChatTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.showDivider = true,
    this.chatIcon,
    this.onTap, // onTap parameter
    this.onLongPress,
    this.onDismissed,
    this.chatPhotoPath,
    this.trailing,
    this.isDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    String deleteString = "Delete?";
    return Material(
      color: Colors.transparent,
      child: Dismissible(
        key: Key(DateTime.now().toString()),
        direction: (isDismissible ?? true) ? DismissDirection.endToStart : DismissDirection.none,
        onDismissed: onDismissed,
        background: Align(
          alignment: Alignment.centerRight,
          child: Icon(Icons.delete_outline_rounded, color: Colors.red)),
        secondaryBackground:Padding(
          padding: EdgeInsetsGeometry.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Text(deleteString),
                Icon(Icons.delete_outline_rounded, color: const Color.fromARGB(255, 255, 120, 120)),
              ],
            )),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap the entire content with InkWell for tap detection
            InkWell(
              onTap: onTap, // Executes onTap if provided
              onLongPress: onLongPress,
              child: Container(
                width: ThemeConstants.screenWidth,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  children: [
                    // Leading Icon
                    chatPhotoPath == null 
                    ? chatIcon ?? DocumentIcon() 
                    : Container(
                      height: 50,
                      width: 50,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Image.file(
                            File(chatPhotoPath!),
                            fit: BoxFit.cover,
                          ),
                    ), // Custom DocumentIcon widget as leading
                    
                    // Title and Time in a Row
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Title Text
                                SizedBox(
                                  width: ThemeConstants.screenWidth * ((trailing == null) ? 0.6 : 0.5), // Adjust width for title
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      overflow: TextOverflow.ellipsis, // Truncate if necessary
                                    ),
                                  ),
                                ),
                                // Time Text
                                if (trailing == null) Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeConstants.subtitleLight,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ThemeConstants.screenHeight * 0.002,),
                            // Subtitle Text
                            SizedBox(
                              width: ThemeConstants.screenWidth * 0.6, // Adjust width for subtitle
                              child: Text(
                                subtitle.replaceAll('\n', " "), // method to show a multi-line note as single line
                                maxLines: 1,
                                softWrap: false, // Prevent wrapping
                                overflow: TextOverflow.ellipsis, // Truncate if necessary
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ThemeConstants.subtitleLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
