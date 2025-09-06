import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';

class ChatTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool showDivider;
  final Widget? chatIcon;
  final VoidCallback? onTap; // Nullable onTap function

  // Constructor
  const ChatTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.showDivider = true,
    this.chatIcon,
    this.onTap, // onTap parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap the entire content with InkWell for tap detection
        InkWell(
          onTap: onTap, // Executes onTap if provided
          child: Container(
            width: ThemeConstants.screenWidth,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                // Leading Icon
                chatIcon ?? DocumentIcon(), // Custom DocumentIcon widget as leading
                
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
                              width: ThemeConstants.screenWidth * 0.6, // Adjust width for title
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: ThemeConstants.textLight,
                                  overflow: TextOverflow.ellipsis, // Truncate if necessary
                                ),
                              ),
                            ),
                            // Time Text
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                            subtitle,
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
