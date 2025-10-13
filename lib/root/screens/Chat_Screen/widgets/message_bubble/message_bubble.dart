
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/message_bubble/helpers/ripple_well.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/message_bubble/helpers/swipable.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/chat_screen_widgets/reply_wrapper.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/message_bubble/message_content_builder.dart';
import 'package:notesapp/root/widgets/glass_container.dart';

class MessageBubble extends StatefulWidget {
  final Message message;

  /// Selection state
  final bool isSelecting;
  final VoidCallback? onTapWhileSelecting;

  /// Dismissible
  final Widget? dismissBackground;
  final void Function()? onSwipe;

  /// RippleWell props
  final void Function()? onTap;
  final void Function()? onReplyTap;
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
  final bool? isHighlighted;
  final bool? isSelected; 

  const MessageBubble({
    super.key,
    required this.message,
    this.style = BubbleStyle.opaque,
    this.isSelecting = false,
    this.onTapWhileSelecting,
    this.dismissBackground,
    this.onSwipe,
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
    this.onReplyTap,
    this.isHighlighted = false,
    this.isSelected = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive  => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          isHighlighted: widget.isHighlighted ?? false,
        ),
      };
    }

    return Swipeable(
      isSender: widget.message.isSender,
      isSelecting: widget.isSelecting,
      onSwiped: widget.onSwipe,
      child: Stack(
        children: [
          AnimatedAlign(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutQuint,
            alignment:  widget.message.isSender ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedPadding(
              duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutQuint,
              padding: EdgeInsets.only(
                left: widget.message.isSender ? 45.0 : 8,
                right: widget.message.isSender ? 8 : 45,
                top: widget.topPadding ?? 5,
                bottom: widget.bottomPadding ?? 5,
              ),
              child: Column(
                crossAxisAlignment: widget.message.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (widget.message.replyingTo.value != null)
                    ReplyWrapper(
                      replyMessage: widget.message.replyingTo.value!,
                      backgroundColor: Colors.blueGrey.withOpacity(context.isLight ? 0.1 : 0.07),
                      iconColor: context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark,
                      onTap: widget.onReplyTap ?? () {
                        print("Reply tapped");
                        final media = widget.message.replyingTo.value!.media.value;
                        if (media != null) {
                          print("Media path: ${media.path}");
                        }
                      },
                    ),
                  styleBuilder(widget.style),
                ],
              ),
            ),
          ),

          // Full-width selection overlay
          if (widget.isSelecting)
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onTapWhileSelecting,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  color: widget.isSelected ?? false
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
  EdgeInsets _getDefaultPadding() {
    return widget.message.isImage
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
        : widget.message.isDocument ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 15, vertical: 10);
  }

  Color _getBubbleColor(BuildContext context) {
    return widget.message.isSender
        ? (context.isLight
            ? ThemeConstants.senderBlue
            : ThemeConstants.senderBlueDark)
        : (context.isLight
            ? ThemeConstants.hometoolbarLight3
            : ThemeConstants.darkIconBorder);
  }

  Color _getHighlightedBubbleColor(BuildContext context) {
    return widget.message.isSender
        ? (context.isLight
            ? const Color(0xFFF5FBFF)
            : const Color(0xFF5A9CC0))
        : (context.isLight
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF677F8D));
  }

  Color _getGlassColor() {
    return widget.message.isSender
        ? Colors.blue.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.15);
  }

  // ------------------------
  Widget opaqueBubble({
    required Color messageBubbleColor,
    required EdgeInsets bubblePadding,
    required bool isHighlighted,
  }) {
    return RippleWell(
          borderRadius: widget.rippleBorderRadius ?? BorderRadius.circular(widget.borderRadius),
          materialColor: messageBubbleColor,
          onTap: widget.isSelecting ? widget.onTapWhileSelecting : widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: isHighlighted ? _getHighlightedBubbleColor(context) : Colors.transparent,
              boxShadow: [
                 BoxShadow(
                  color: Colors.white.withOpacity(
                    isHighlighted ? (context.isLight ? 0.9 : 0.3) : 0.0,
                  ),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
              // border: Border.all( // width: isHighlighted ? 1.5 : 0, // color: isHighlighted ? Colors.white : Colors.transparent, // ),
            ),
            child: Padding(
        padding: bubblePadding,
        child: MessageContentBuilder(message: widget.message), // <— use cached child
          ),
        )
    );
  }

  Widget glassBubble({required Color glassColor, required EdgeInsets glassPadding}) {
    return RippleWell(
      borderRadius: widget.rippleBorderRadius ?? BorderRadius.circular(widget.borderRadius),
      materialColor: widget.rippleColor,
      onTap: widget.isSelecting ? widget.onTapWhileSelecting : widget.onTap,
      onLongPress: widget.onLongPress,
      child: GlassContainer(
        blurX: widget.blurX,
        blurY: widget.blurY,
        borderRadius: widget.borderRadius,
        borderWidth: widget.borderWidth,
        borderColor: widget.borderColor,
        backgroundColor: widget.backgroundColor ?? glassColor,
        padding: glassPadding,
        width: widget.width,
        height: widget.height,
        child: MessageContentBuilder(message: widget.message),
      ),
    );
  }
}

