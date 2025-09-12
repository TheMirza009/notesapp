import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/widgets/glass_container.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/ripple_menu.dart';
import 'package:svg_flutter/svg.dart';

class GlassBubble2 extends StatelessWidget {
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
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final double? topPadding;
  final double? bottomPadding;

  const GlassBubble2({
    super.key,
    required this.message,
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
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    this.width,
    this.height,
    this.topPadding = 5,
    this.bottomPadding = 5,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;

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
      
          // The bubble itself, aligned left or right
          Align(
            alignment: message.isSender ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: message.isSender ? 45.0 : 8,
                right: message.isSender ? 8 : 45,
                top: topPadding ?? 5,
                bottom: bottomPadding ?? 5,
              ),
              child: RippleWell(
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
                  backgroundColor:
                      backgroundColor ??
                      (message.isSender
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.15)),
                  padding: padding,
                  width: width,
                  height: height,
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(fontSize: 20),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            DateFormat.jm().format(message.time),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Full-width selection overlay
          if (isSelecting)
            Positioned.fill(
              // left: 0,
              // top: 0,
              // width: screenWidth,
              // height: double.maxFinite,
              child: GestureDetector(
                onTap: onTapWhileSelecting,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  color: message.isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
              context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark2,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }