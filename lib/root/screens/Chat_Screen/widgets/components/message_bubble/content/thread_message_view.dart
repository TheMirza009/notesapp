import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/time_extensions.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/ripple_well.dart';
import 'package:typeset/typeset.dart';

class ThreadMessageView extends StatelessWidget {
  const ThreadMessageView({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = ["NOTHING", "EVER", "HAPPENS"];

    // Use the real text style that will be used by Text widgets.
    final textStyle = DefaultTextStyle.of(context).style;

    // Find the longest text by measured width (accurate).
    double maxTextWidth = 0;
    for (final s in strings) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > maxTextWidth) maxTextWidth = tp.width;
    }

     // ✅ Compute approximate width of 15 characters (based on font metrics)
    final testPainter = TextPainter(
      text: TextSpan(text: "M" * 10, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final minTextWidth = testPainter.width;

    const double edgePadding = 80;

    // ✅ Use whichever is larger
    final totalWidth = (maxTextWidth < minTextWidth ? minTextWidth : maxTextWidth) + edgePadding;

    return Center(
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
                      TestThreadTile(
                        text: text,
                        showTime: isLast,
                        showNumber: true,
                        current: (index + 1).toString(),
                        total: strings.length.toString(),
                      ),
                      if (strings.length == 1) Ridge(),
                      if (!isLast) const Thether(), // bottom tether (skip if last)
                    ],
                  ),
                  if (!isFirst) const Thether(top: true), // top tether (skip if first)
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class Ridge extends StatelessWidget {
  const Ridge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: EdgeInsets.all(5),
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.3)
          ),
        );
  }
}


class TestThreadTile extends StatelessWidget {
  final String text;
  final bool? showTime;
  final bool? showNumber;
  final String? current;
  final String? total;
  const TestThreadTile({
    super.key,
    required this.text,
    this.showTime = false,
    this.showNumber = false,
    this.current,
    this.total, 
  });

  @override
  Widget build(BuildContext context) {
    final isLight = navigatorKey.currentContext?.isLight ?? true;
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Container(
          // Ensure the container expands to the parent's width:
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 10, top: 10,  right: 12, left: 25),
          decoration: BoxDecoration(
            color: context.isLight ? ThemeConstants.senderBlue : ThemeConstants.senderBlueDark,
            borderRadius: BorderRadius.circular(10),
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
                        style: const TextStyle(fontSize: 15),
                        softWrap: true,
                        monospaceStyle: TextStyle(
                          fontFamily: "Consolas",
                          backgroundColor: ThemeConstants.iconColorNeutral
                              .withValues(alpha: isLight ? 0.2 : 0.5),
                        ),
                        linkRecognizerBuilder: (linkText, url) {
                          return TapGestureRecognizer()
                            ..onTap = () {
                              debugPrint('URL: $url and Text: $linkText');
                            };
                        },
                      ),
                    ),
                    if (showNumber ?? false)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Transform.translate(
                          offset: Offset(0, -3),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "$current/$total",
                              style: TextStyle(
                                fontSize: 12,
                                color: ThemeConstants.iconColorNeutral,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (showTime == true) Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    DateTime.now().to12HourString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white, // ThemeConstants.subtitleLight,
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

class Thether extends StatelessWidget {
  final bool? top;
  const Thether({super.key, this.top = false});

  @override
  Widget build(BuildContext context) {
    const double threadHeight = 30;
    return Stack(
      alignment: top == true ? Alignment.topCenter : Alignment.bottomCenter,
      children: [
        const Ridge(),
        Transform.translate(
          offset: Offset(0, top == true ? - threadHeight + 7 : threadHeight - 7),
          child: Container(
            margin: EdgeInsets.all(5),
            height: threadHeight,
            width: 3.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100)
            ),
          ),
        ),
      ],
    );
  }
}


class BubbleTile extends StatelessWidget {
  final Color messageBubbleColor;
  final EdgeInsets bubblePadding;
  final bool isHighlighted;
  final Color highlightedColor;
  final VoidCallback onTap;
  final void Function(Offset offset) onLongPress;
  final String text;
  const BubbleTile({
    super.key,
    required this.messageBubbleColor,
    required this.bubblePadding,
    required this.isHighlighted,
    required this.highlightedColor,
    required this.onTap,
    required this.onLongPress,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return RippleWell(
      borderRadius: BorderRadius.circular(15),
      materialColor: messageBubbleColor,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isHighlighted ? highlightedColor : messageBubbleColor,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(
                isHighlighted ? (context.isLight ? 0.9 : 0.3) : 0.0,
              ),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(padding: bubblePadding, child: Text(text)),
      ),
    );
  }
}

Widget opaqueBubble({
  required Color messageBubbleColor,
  required EdgeInsets bubblePadding,
  required bool isHighlighted,
  required Color highlightedColor,
  required VoidCallback onTap,
  required void Function(Offset offset) onLongPress,
  required BuildContext context,
  required String text,
}) {
  return RippleWell(
    borderRadius: BorderRadius.circular(15),
    materialColor: messageBubbleColor,
    onTap: onTap,
    onLongPress: onLongPress,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isHighlighted ? highlightedColor : messageBubbleColor,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(
              isHighlighted ? (context.isLight ? 0.9 : 0.3) : 0.0,
            ),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(padding: bubblePadding, child: Text(text)),
    ),
  );
}
