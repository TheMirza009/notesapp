
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/core/extensions/string_extensions.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/enums/bubble_color.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/content/thread_message/thread_message_view.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/ripple_well.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/swipable.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/message_content_builder.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/reply_wrapper.dart';
import 'package:notesapp/root/widgets/glass_container.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isSelecting;
  final VoidCallback? onTapWhileSelecting;
  final Widget? dismissBackground;
  final void Function()? onSwipe;
  final void Function()? onTap;
  final void Function()? onReplyTap;
  final void Function(Offset)? onLongPress;
  final BorderRadius? rippleBorderRadius;
  final Color? rippleColor;
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
  final BubbleStyle style;
  final BubbleColor? bubbleColor;
  final bool? isHighlighted;
  final bool? isSelected;
  final Function()? onThreadCleared;

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
    this.onThreadCleared,
    this.rippleBorderRadius,
    this.rippleColor,
    this.blurX = 25,
    this.blurY = 25,
    this.borderRadius = 15,
    this.borderWidth = 1.0,
    this.borderColor = const Color.fromARGB(100, 255, 255, 255),
    this.backgroundColor,
    this.bubbleColor = BubbleColor.seed,
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

class _MessageBubbleState extends State<MessageBubble>
    with AutomaticKeepAliveClientMixin {
  
  // Cache color scheme - recompute only when style/color changes
  _BubbleColors? _cachedColors;
  BubbleStyle? _lastStyle;
  BubbleColor? _lastBubbleColor;
  Brightness? _lastBrightness;
  bool? _lastIsSender; // Add this line

  @override
  bool get wantKeepAlive {
    // Safe access with null checks - computed every time but that's fine for a getter
    final mediaValue = widget.message.media.value;
    if (mediaValue == null) return false;
    
    final type = mediaValue.type;
    return type == Mediatype.image ||
        type == Mediatype.audio ||
        type == Mediatype.text;
  }

  // Computed properties (no late initialization needed)
  bool get _isSender => widget.message.isSender;
  
  bool get _hasReply => widget.message.replyingTo.value != null;
  
  EdgeInsets get _bubblePadding {
    if (widget.message.isImage) {
      return const EdgeInsets.symmetric(horizontal: 5, vertical: 5);
    } else if (widget.message.isDocument) {
      return const EdgeInsets.all(4);
    } else {
      return const EdgeInsets.symmetric(horizontal: 15, vertical: 10);
    }
  }

  _BubbleColors _getColors(BuildContext context) {
  final currentBrightness = Theme.of(context).brightness;
  final currentStyle = widget.style;
  final currentBubbleColor = widget.bubbleColor ?? BubbleColor.seed;
  final currentIsSender = _isSender; // Add this line

  // Return cached colors if nothing changed
  if (_cachedColors != null &&
      _lastStyle == currentStyle &&
      _lastBubbleColor == currentBubbleColor &&
      _lastBrightness == currentBrightness &&
      _lastIsSender == currentIsSender) { // Add this check
    return _cachedColors!;
  }

  // Recompute and cache
  final scheme = Utils.getBubbleColorScheme(
    context,
    style: currentStyle,
    color: currentBubbleColor,
  );

  _lastStyle = currentStyle;
  _lastBubbleColor = currentBubbleColor;
  _lastBrightness = currentBrightness;
  _lastIsSender = currentIsSender; // Cache this too
  
  _cachedColors = _BubbleColors(
    baseColor: currentIsSender ? scheme.senderBubble : scheme.receiverBubble,
    highlightedColor: currentIsSender ? scheme.highlightedSender : scheme.highlightedReceiver,
    replyBg: scheme.replyBackground,
  );

  return _cachedColors!;
}
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final colors = _getColors(context);
    final isHighlighted = widget.isHighlighted ?? false;
    final isSelected = widget.isSelected ?? false;

    if (widget.message.media.value?.type == Mediatype.thread) {
      return Swipeable(
        isSender: _isSender,
        isSelecting: widget.isSelecting,
        onSwiped: widget.onSwipe,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutQuint,
          alignment: _isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: Stack(
            children: [
              ThreadMessageView(
                tileColor: colors.baseColor,
                highlightedColor: colors.highlightedColor,
                isHighlighted: isHighlighted,
                message: widget.message,
                strings: widget.message.text.safeDecode(),
                padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: widget.topPadding ?? 5,
                bottom: widget.bottomPadding ?? 5,
              ),
                onTap: widget.onTap!,
                onLongPress: widget.onLongPress,
                onClearPressed: (index) {
                  widget.onThreadCleared?.call(); // Fixed: properly invoke the callback
                },
              ),
              if (widget.isSelecting)
            _SelectionOverlay(
              isSelected: isSelected,
              onTap: widget.onTapWhileSelecting,
            ),
            ],
          ),
        ),
      );
    } else 
    {
      return Swipeable(
      isSender: _isSender,
      isSelecting: widget.isSelecting,
      onSwiped: widget.onSwipe,
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuint,
            alignment: _isSender ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutQuint,
              padding: EdgeInsets.only(
                left: _isSender ? 45.0 : 8,
                right: _isSender ? 8 : 45,
                top: widget.topPadding ?? 5,
                bottom: widget.bottomPadding ?? 5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: _isSender
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (_hasReply)
                    _ReplySection(
                      message: widget.message,
                      replyBg: colors.replyBg,
                      isLight: context.isLight,
                      onReplyTap: widget.onReplyTap,
                    ),
                  _BubbleContent(
                    style: widget.style,
                    message: widget.message,
                    colors: colors,
                    isHighlighted: isHighlighted,
                    bubblePadding: _bubblePadding,
                    borderRadius: widget.borderRadius,
                    rippleBorderRadius: widget.rippleBorderRadius,
                    rippleColor: widget.rippleColor,
                    isSelecting: widget.isSelecting,
                    onTapWhileSelecting: widget.onTapWhileSelecting,
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    blurX: widget.blurX,
                    blurY: widget.blurY,
                    borderWidth: widget.borderWidth,
                    borderColor: widget.borderColor,
                    backgroundColor: widget.backgroundColor,
                    width: widget.width,
                    height: widget.height,
                    isLight: context.isLight,
                  ),
                ],
              ),
            ),
          ),
          if (widget.isSelecting)
            _SelectionOverlay(
              isSelected: isSelected,
              onTap: widget.onTapWhileSelecting,
            ),
        ],
      ),
    );
    }
  }
}

// Immutable color holder for caching
class _BubbleColors {
  final Color baseColor;
  final Color highlightedColor;
  final Color replyBg;

  const _BubbleColors({
    required this.baseColor,
    required this.highlightedColor,
    required this.replyBg,
  });
}

// Separate widget to prevent unnecessary rebuilds
class _ReplySection extends StatelessWidget {
  final Message message;
  final Color replyBg;
  final bool isLight;
  final VoidCallback? onReplyTap;

  const _ReplySection({
    required this.message,
    required this.replyBg,
    required this.isLight,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return ReplyWrapper(
      replyMessage: message.replyingTo.value!,
      backgroundColor: replyBg,
      iconColor: isLight ? ThemeConstants.textLight : ThemeConstants.textDark,
      onTap: onReplyTap ?? () {
        debugPrint("Reply tapped");
        final media = message.replyingTo.value!.media.value;
        if (media != null) {
          debugPrint("Media path: ${media.path}");
        }
      },
    );
  }
}

// Separate widget for bubble content to enable const optimization
class _BubbleContent extends StatelessWidget {
  final BubbleStyle style;
  final Message message;
  final _BubbleColors colors;
  final bool isHighlighted;
  final EdgeInsets bubblePadding;
  final double borderRadius;
  final BorderRadius? rippleBorderRadius;
  final Color? rippleColor;
  final bool isSelecting;
  final VoidCallback? onTapWhileSelecting;
  final VoidCallback? onTap;
  final void Function(Offset)? onLongPress;
  final double blurX;
  final double blurY;
  final double borderWidth;
  final Color borderColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final bool isLight;

  const _BubbleContent({
    required this.style,
    required this.message,
    required this.colors,
    required this.isHighlighted,
    required this.bubblePadding,
    required this.borderRadius,
    required this.rippleBorderRadius,
    required this.rippleColor,
    required this.isSelecting,
    required this.onTapWhileSelecting,
    required this.onTap,
    required this.onLongPress,
    required this.blurX,
    required this.blurY,
    required this.borderWidth,
    required this.borderColor,
    required this.backgroundColor,
    required this.width,
    required this.height,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      BubbleStyle.glass => _GlassBubble(
          message: message,
          colors: colors,
          bubblePadding: bubblePadding,
          borderRadius: borderRadius,
          rippleBorderRadius: rippleBorderRadius,
          rippleColor: rippleColor,
          isSelecting: isSelecting,
          onTapWhileSelecting: onTapWhileSelecting,
          onTap: onTap,
          onLongPress: onLongPress,
          blurX: blurX,
          blurY: blurY,
          borderWidth: borderWidth,
          borderColor: borderColor,
          backgroundColor: backgroundColor,
          width: width,
          height: height,
        ),
      BubbleStyle.opaque => _OpaqueBubble(
          message: message,
          colors: colors,
          isHighlighted: isHighlighted,
          bubblePadding: bubblePadding,
          borderRadius: borderRadius,
          rippleBorderRadius: rippleBorderRadius,
          isSelecting: isSelecting,
          onTapWhileSelecting: onTapWhileSelecting,
          onTap: onTap,
          onLongPress: onLongPress,
          isLight: isLight,
        ),
    };
  }
}

class _OpaqueBubble extends StatelessWidget {
  final Message message;
  final _BubbleColors colors;
  final bool isHighlighted;
  final EdgeInsets bubblePadding;
  final double borderRadius;
  final BorderRadius? rippleBorderRadius;
  final bool isSelecting;
  final VoidCallback? onTapWhileSelecting;
  final VoidCallback? onTap;
  final void Function(Offset)? onLongPress;
  final bool isLight;

  const _OpaqueBubble({
    required this.message,
    required this.colors,
    required this.isHighlighted,
    required this.bubblePadding,
    required this.borderRadius,
    required this.rippleBorderRadius,
    required this.isSelecting,
    required this.onTapWhileSelecting,
    required this.onTap,
    required this.onLongPress,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = colors.baseColor;
    final highlightColor = colors.highlightedColor;
    return RippleWell(
      animated: true,
      borderRadius: rippleBorderRadius ??  BorderRadius.circular(message.isImage ? 5 : borderRadius),
      materialColor: baseColor,
      onTap: isSelecting ? onTapWhileSelecting : onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: isHighlighted ? highlightColor : Colors.transparent, //baseColor, // baseColor,
          boxShadow: [
            BoxShadow(
              color: isHighlighted ? Colors.white.withValues(alpha: isLight ? 0.9 : 0.3) : Colors.transparent,
              blurRadius: isHighlighted ? 16 : 0,
              spreadRadius: isHighlighted ? 2 : 0,
            ),
          ],
        ),
        child: Padding(
          padding: bubblePadding,
          child: MessageContentBuilder(message: message),
        ),
      ),
    );
  }
}

class _GlassBubble extends StatelessWidget {
  final Message message;
  final _BubbleColors colors;
  final EdgeInsets bubblePadding;
  final double borderRadius;
  final BorderRadius? rippleBorderRadius;
  final Color? rippleColor;
  final bool isSelecting;
  final VoidCallback? onTapWhileSelecting;
  final VoidCallback? onTap;
  final void Function(Offset)? onLongPress;
  final double blurX;
  final double blurY;
  final double borderWidth;
  final Color borderColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;

  const _GlassBubble({
    required this.message,
    required this.colors,
    required this.bubblePadding,
    required this.borderRadius,
    required this.rippleBorderRadius,
    required this.rippleColor,
    required this.isSelecting,
    required this.onTapWhileSelecting,
    required this.onTap,
    required this.onLongPress,
    required this.blurX,
    required this.blurY,
    required this.borderWidth,
    required this.borderColor,
    required this.backgroundColor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: backgroundColor ?? colors.baseColor,
        padding: bubblePadding,
        width: width,
        height: height,
        child: MessageContentBuilder(message: message),
      ),
    );
  }
}

class _SelectionOverlay extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const _SelectionOverlay({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
      ),
    );
  }
}