import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';

class ChatTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool showDivider;
  final Widget? chatIcon;

  // Constructor
  const ChatTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.showDivider = true,
    this.chatIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading:
              chatIcon ??
              DocumentIcon(), // Custom DocumentIcon widget as leading
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: ThemeConstants.screenWidth / 1.6,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textLight,
                    overflow: TextOverflow.ellipsis
                  ),
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.homeSubtitleLight,
                ),
              ),
            ],
          ),
          subtitle: SizedBox(
            width: ThemeConstants.screenWidth * 0.01,
            child: Text(
              subtitle,
              softWrap: false,
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                color: ThemeConstants.homeSubtitleLight,
                
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: ThemeConstants.homeDividerLight, // Divider color
            thickness: 1, // Divider thickness
            indent:
                ThemeConstants.screenWidth *
                (1 - 0.9), // Divider aligned to right
          ),
      ],
    );
  }
}
