import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/time_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/ripple_well.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:typeset/typeset.dart';

/// ---------------------------------------------------------------------------
/// THREAD MESSAGE VIEW — beautifully connected stacked message bubbles
/// ---------------------------------------------------------------------------
/// 
/// Usage example:
/// ```dart
/// ThreadMessageView(
///   strings: [
///     "Hello world!",
///     "This is a thread-style message bubble.",
///     "The last one shows the timestamp 🕒"
///   ],
/// )
/// ```
///
/// Required:
/// - [strings] — list of messages (each becomes one bubble)
///
/// Optional styling:
/// - Automatically sizes width based on longest message.
/// - Handles dynamic text width.
/// - Shows tether lines and circle “ridges” between bubbles.
/// ---------------------------------------------------------------------------
class ThreadMessageView extends StatelessWidget {
  final Message message;
  final List<String> strings;

  final void Function() onTap;
  final void Function(Offset offset)? onLongPress;
  final void Function(int index)? onClearPressed;

  final double edgePadding;

  const ThreadMessageView({
    super.key,
    required this.message,
    required this.strings,
    required this.onTap,
    this.onLongPress,
    this.onClearPressed,
    this.edgePadding = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    if (strings.isEmpty) return const SizedBox.shrink();

    final textStyle = DefaultTextStyle.of(context).style;
    final isSender = message.isSender;

    // Measure text widths (same as before)
    double maxTextWidth = 0;
    for (final s in strings) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > maxTextWidth) maxTextWidth = tp.width;
    }

    final testPainter = TextPainter(
      text: TextSpan(text: "M" * 10, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final minTextWidth = testPainter.width;

    final totalWidth =
        (maxTextWidth < minTextWidth ? minTextWidth : maxTextWidth) +
            edgePadding;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft ,
      child: Padding(
        padding: EdgeInsets.only(
          left: isSender ? 45.0 : 8,
          right: isSender ? 8 : 45,
          // left: 8,
          // right: 8,
          top: 12,
          bottom: 12,
        ),
        child: SizedBox(
          width: totalWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(strings.length, (index) {
              final text = strings[index];
              final isFirst = index == 0;
              final isLast = index == strings.length - 1;
            
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Stack(
                  alignment: Alignment.topLeft,
                  clipBehavior: Clip.none,
                  children: [
                    Stack(
                      alignment: Alignment.bottomLeft,
                      clipBehavior: Clip.none,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            return ThreadTile(
                              text: text,
                              showTime: isLast,
                              showNumber: true,
                              current: (index + 1).toString(),
                              total: strings.length.toString(),
                              onTap: () {
                                debugPrint("IS SENDer: $isSender");
                                if (onTap != null) {
                                  onTap;
                                } else {
                                  ref
                                      .read(
                                        themeNotifierProvider.notifier,
                                      )
                                      .toggleTheme();
                                }
                              },
                              onLongPress: (offset) {
                                if (onLongPress != null) {
                                  onLongPress!(offset);
                                } else {
                                  CustomContextMenu.showMenuAt(
                                    context,
                                    position: offset,
                                    menuItems: messageHoldOptions(
                                      isMedia: false,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                        if (strings.length == 1) const Ridge(),
                        if (!isLast) const Thether(),
                      ],
                    ),
                    if (!isFirst) const Thether(top: true),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// !isSender
//                                           ? const Offset(0.4, 0)
//                                           : const Offset(-0.4, 0),


class ThreadClearButton extends StatelessWidget {
  /// Whether the clear button should be visible.
  final bool isClearVisible;

  /// The index of the thread tile this button belongs to.
  final int index;

  /// Callback fired when the clear (X) button is pressed.
  final ValueChanged<int>? onClearPressed;

  /// Whether the message is from the sender (controls slide direction).
  final bool isSender;

  const ThreadClearButton({
    super.key,
    required this.isClearVisible,
    required this.index,
    required this.isSender,
    this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Define slide direction based on sender
    final beginOffset = isSender
        ? const Offset(0.4, 0.0) // slide in from right
        : const Offset(-0.4, 0.0); // slide in from left

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        // Controls slide direction
        final slideTween = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        );

        // Controls rotation (-90° → 0°)
        final rotationTween = Tween<double>(
          begin: -math.pi / 2,
          end: 0,
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final rotation = rotationTween.transform(animation.value);
                return Transform.rotate(
                  angle: rotation,
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: child,
            ),
          ),
        );
      },
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      child: isClearVisible
          ? IconButton(
              key: ValueKey("clear_$index"),
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white70,
              ),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              onPressed: () => onClearPressed?.call(index),
            )
          : const SizedBox.shrink(),
    );
  }
}


/// ---------------------------------------------------------------------------
/// INDIVIDUAL MESSAGE TILE
/// ---------------------------------------------------------------------------
class ThreadTile extends StatelessWidget {
  final String text;
  final bool? showTime;
  final bool? showNumber;
  final String? current;
  final String? total;

  // Styling options
  final Color? messageBubbleColor;
  final Color? highlightedColor;
  final bool? isHighlighted;

  // VoidCallbacks
  final VoidCallback? onTap;
  final void Function(Offset offset)? onLongPress;


  const ThreadTile({
    super.key,
    required this.text,
    this.showTime = false,
    this.showNumber = false,
    this.current,
    this.total,
    this.messageBubbleColor,
    this.highlightedColor,
    this.isHighlighted,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        RippleWell(
          animated: true,
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          materialColor: messageBubbleColor ?? (context.isLight ? ThemeConstants.senderBlue : ThemeConstants.senderBlueDark),
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 10, top: 10, right: 12, left: 25),
          child: AnimatedContainer(duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: (isHighlighted ?? false) ? highlightedColor : messageBubbleColor,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(
                (isHighlighted ?? false) ? (context.isLight ? 0.9 : 0.3) : 0.0,
              ),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: TypeSet(
                          text,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          softWrap: true,
                        ),
                      ),
                      if (showNumber ?? false)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Transform.translate(
                            offset: const Offset(0, -3),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "$current/$total",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showTime == true)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        DateTime.now().to12HourString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// TETHER & RIDGE ELEMENTS (visual connectors between bubbles)
/// ---------------------------------------------------------------------------
const EdgeInsets threadPadding = EdgeInsets.only(left: 5, top: 3, bottom: 3);

class Ridge extends StatelessWidget {
  const Ridge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: threadPadding,
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.3),
      ),
    );
  }
}

class Thether extends StatelessWidget {
  final bool? top;
  const Thether({super.key, this.top = false});

  @override
  Widget build(BuildContext context) {
    const double threadLength = 20;
    return Stack(
      alignment: top == true ? Alignment.topCenter : Alignment.bottomCenter,
      children: [
        const Ridge(),
        Transform.translate(
          offset:
              Offset(0, top == true ? -threadLength + 7 : threadLength - 7),
          child: Container(
            margin: threadPadding,
            height: threadLength,
            width: 3.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ],
    );
  }
}


// class BubbleTile extends StatelessWidget {
//   final Color messageBubbleColor;
//   final EdgeInsets bubblePadding;
//   final bool isHighlighted;
//   final Color highlightedColor;
//   final VoidCallback onTap;
//   final void Function(Offset offset) onLongPress;
//   final String text;
//   const BubbleTile({
//     super.key,
//     required this.messageBubbleColor,
//     required this.bubblePadding,
//     required this.isHighlighted,
//     required this.highlightedColor,
//     required this.onTap,
//     required this.onLongPress,
//     required this.text,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return RippleWell(
//       borderRadius: BorderRadius.circular(15),
//       materialColor: messageBubbleColor,
//       onTap: onTap,
//       onLongPress: onLongPress,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           color: isHighlighted ? highlightedColor : messageBubbleColor,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.white.withOpacity(
//                 isHighlighted ? (context.isLight ? 0.9 : 0.3) : 0.0,
//               ),
//               blurRadius: 16,
//               spreadRadius: 2,
//             ),
//           ],
//         ),
//         child: Padding(padding: bubblePadding, child: Text(text)),
//       ),
//     );
//   }
// }

// Widget opaqueBubble({
//   required Color messageBubbleColor,
//   required EdgeInsets bubblePadding,
//   required bool isHighlighted,
//   required Color highlightedColor,
//   required VoidCallback onTap,
//   required void Function(Offset offset) onLongPress,
//   required BuildContext context,
//   required String text,
// }) {
//   return RippleWell(
//     borderRadius: BorderRadius.circular(15),
//     materialColor: messageBubbleColor,
//     onTap: onTap,
//     onLongPress: onLongPress,
//     child: AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(15),
//         color: isHighlighted ? highlightedColor : messageBubbleColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.white.withOpacity(
//               isHighlighted ? (context.isLight ? 0.9 : 0.3) : 0.0,
//             ),
//             blurRadius: 16,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Padding(padding: bubblePadding, child: Text(text)),
//     ),
//   );
// }
