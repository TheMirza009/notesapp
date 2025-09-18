import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_content_builder.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/ripple_menu.dart';
import 'package:notesapp/root/widgets/glass_container.dart';
import 'package:svg_flutter/svg.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  /// Selection state
  final bool isSelecting;
  final VoidCallback? onTapWhileSelecting;

  /// Dismissible
  final Widget? dismissBackground;
  final void Function(DismissDirection)? onDismissed;

  /// RippleWell props
  final void Function()? onTap;
  final void Function(Offset)? onLongPress;
  final BorderRadius? rippleBorderRadius;
  final Color? rippleColor;

  /// GlassContainer props
  final double blurX;
  final double blurY;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double? topPadding;
  final double? bottomPadding;

  /// Style
  final BubbleStyle style;

  const MessageBubble({
    super.key,
    required this.message,
    this.style = BubbleStyle.opaque,
    this.isSelecting = false,
    this.onTapWhileSelecting,
    this.dismissBackground,
    this.onDismissed,
    this.onTap,
    this.onLongPress,
    this.rippleBorderRadius,
    this.rippleColor,
    this.blurX = 25,
    this.blurY = 25,
    this.borderRadius = 15,
    this.borderWidth = 1.0,
    this.borderColor = const Color.fromARGB(100, 255, 255, 255),
    this.backgroundColor,
    this.padding,
    this.width,
    this.height,
    this.topPadding = 5,
    this.bottomPadding = 5,
  });

  @override
  Widget build(BuildContext context) {
    final bubblePadding = _getDefaultPadding();
    final bubbleColor = _getBubbleColor(context);
    final glassColor = _getGlassColor();

    Widget styleBuilder(BubbleStyle style) {
      return switch (style) {
        BubbleStyle.glass => glassBubble(
          glassColor: glassColor,
          glassPadding: bubblePadding,
        ),
        BubbleStyle.opaque => opaqueBubble(
          messageBubbleColor: bubbleColor,
          bubblePadding: bubblePadding,
        ),
      };
    }

    return Dismissible(
      key: ValueKey(message.id),
      direction: message.isSender ? DismissDirection.endToStart : DismissDirection.startToEnd,
      dismissThresholds: const {
        DismissDirection.startToEnd: 1.0,
        DismissDirection.endToStart: 1.0,
      },
      confirmDismiss: (direction) async => false,
      movementDuration: Duration.zero,
      resizeDuration: null,
      background: dismissBackground ?? replyIconBackground(context, alignLeft: !message.isSender),
      onDismissed: onDismissed,
      child: Stack(
        children: [
          AnimatedAlign(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutQuint,
            alignment:  message.isSender ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedPadding(
              duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutQuint,
              padding: EdgeInsets.only(
                left: message.isSender ? 45.0 : 8,
                right: message.isSender ? 8 : 45,
                top: topPadding ?? 5,
                bottom: bottomPadding ?? 5,
              ),
              child: styleBuilder(style),
            ),
          ),

          // Full-width selection overlay
          if (isSelecting)
            Positioned.fill(
              child: GestureDetector(
                onTap: onTapWhileSelecting,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  color: message.isSelected
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------
  // Helpers
  // ------------------------

  EdgeInsets _getDefaultPadding() {
    return message.media.value?.type == Mediatype.image
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 15, vertical: 10);
  }

  Color _getBubbleColor(BuildContext context) {
    return message.isSender
        ? (context.isLight
            ? ThemeConstants.senderBlue
            : ThemeConstants.senderBlueDark)
        : (context.isLight
            ? ThemeConstants.hometoolbarLight3
            : ThemeConstants.darkIconBorder);
  }

  Color _getGlassColor() {
    return message.isSender
        ? Colors.blue.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.15);
  }

  // ------------------------
  // Bubble Variants
  // ------------------------
  Widget opaqueBubble({required Color messageBubbleColor, required EdgeInsets bubblePadding}) {
    return RippleWell(
      borderRadius: rippleBorderRadius ?? BorderRadius.circular(borderRadius),
      materialColor: messageBubbleColor,
      onTap: isSelecting ? onTapWhileSelecting : onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: bubblePadding,
        child: MessageContentBuilder(message: message),
      ),
    );
  }

  Widget glassBubble({required Color glassColor, required EdgeInsets glassPadding}) {
    return RippleWell(
      borderRadius: rippleBorderRadius ?? BorderRadius.circular(borderRadius),
      materialColor: rippleColor,
      onTap: isSelecting ? onTapWhileSelecting : onTap,
      onLongPress: onLongPress,
      child: GlassContainer(
        blurX: blurX,
        blurY: blurY,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
        borderColor: borderColor,
        backgroundColor: backgroundColor ?? glassColor,
        padding: glassPadding,
        width: width,
        height: height,
        child: MessageContentBuilder(message: message),
      ),
    );
  }
}

// ------------------------
// Reply Background
// ------------------------
Widget replyIconBackground(BuildContext context, {required bool alignLeft}) {
  return Container(
    alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.string(
          IconPaths.messageReply,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            context.isLight
                ? ThemeConstants.textLight
                : ThemeConstants.textDark2,
            BlendMode.srcIn,
          ),
        ),
      ),
    ),
  );
}
