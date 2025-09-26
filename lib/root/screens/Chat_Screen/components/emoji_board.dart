import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';

class EmojiBoard extends StatelessWidget {
  final bool showEmojis; // controlled by notifier
  final TextEditingController textController;
  final FocusNode? textFieldFocusNode; // optional, for advanced control
  final double keyboardHeight; // fallback default

  const EmojiBoard({
    super.key,
    required this.showEmojis,
    required this.textController,
    this.textFieldFocusNode,
    this.keyboardHeight = 250,
  });

  @override
  Widget build(BuildContext context) {
    Color barColor = context.isLight ? const Color(0xFFE0E7EC) : ThemeConstants.darkIconBorder;
    Color paletteColor = context.isLight ? ThemeConstants.hometoolbarLight : ThemeConstants.messageBarDark;
    Color highlightColor = context.isLight ? ThemeConstants.sacredSeed : const Color(0xFF0DD6EC);
    Color iconColor = context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark;

    return EmojiPicker(
      textEditingController: textController,
      config: Config(
        height: keyboardHeight,
        emojiViewConfig: EmojiViewConfig(
          backgroundColor: paletteColor,
          buttonMode: ButtonMode.CUPERTINO,
        ),
        skinToneConfig: SkinToneConfig(
          dialogBackgroundColor: paletteColor,
        ),
        searchViewConfig: SearchViewConfig(
          backgroundColor: paletteColor,
          buttonIconColor: ThemeConstants.iconColorNeutral,
        ),
        categoryViewConfig: CategoryViewConfig(
          backgroundColor: barColor,
          iconColor: ThemeConstants.iconColorNeutral,
          iconColorSelected: highlightColor,
          indicatorColor: highlightColor,
        ),
        bottomActionBarConfig: BottomActionBarConfig(
          backgroundColor: barColor,
          buttonColor: ThemeConstants.iconColorNeutral.withValues(alpha: 0.2),
          buttonIconColor: iconColor,
        ),
      ),
    );
  }
}
