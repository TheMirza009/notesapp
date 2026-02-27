import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/models/chat_model.dart';

void showChatInfoSheet(BuildContext context, Chat chat) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.isLight
        ? ThemeConstants.attachmentLightBG
        : ThemeConstants.darkAppbar,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small handle at the top
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: context.isLight
                            ? const Color(0xFFB1BABC)
                            : const Color(0xFFA2C0CF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildChatInfoSection(context, chat),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}


  Widget _buildChatInfoSection(BuildContext context, Chat chat) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chat Info",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow("Created", TimeFormat.formatChatTime(chat.date)),
          const SizedBox(height: 5),
          _buildInfoRow("Notes", "${chat.messages.length} notes"),
          // Add more chat info as needed
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: ThemeConstants.subtitleLight,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

