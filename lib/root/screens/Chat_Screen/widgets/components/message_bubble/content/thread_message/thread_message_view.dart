import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/time_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/content/thread_message/thether.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/ripple_well.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:typeset/typeset.dart';

/// Thread-style stacked message bubbles with visual connectors
class ThreadMessageView extends StatelessWidget {
  final Message message;
  final List<String> strings;
  final VoidCallback onTap;
  final void Function(Offset)? onLongPress;
  final void Function(int)? onClearPressed;
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

    final isSender = message.isSender;
    final totalWidth = _calculateWidth(context) + edgePadding;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left:  isSender ? 0 : 8, // Remove 45px padding
          right:  isSender ? 8 : 0, // Remove 45px padding
          top: 12,
          bottom: 12,
        ),
        child: SizedBox(
          width: totalWidth + 45, // Add 45px for button space
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(strings.length, (i) {
              return _ThreadItem(
                text: strings[i],
                index: i,
                total: strings.length,
                isSender: isSender,
                onTap: onTap,
                onLongPress: onLongPress ?? (offset) => _showContextMenu(context, offset),
                onClearPressed: onClearPressed,
              );
            }),
          ),
        ),
      ),
    );
  }

  double _calculateWidth(BuildContext context) {
    final textStyle = DefaultTextStyle.of(context).style;
    double maxWidth = 0;

    for (final text in strings) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > maxWidth) maxWidth = tp.width;
    }

    final minWidthPainter = TextPainter(
      text: TextSpan(text: "M" * 10, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final minWidth = minWidthPainter.width;
    return maxWidth < minWidth ? minWidth : maxWidth;
  }

  void _showContextMenu(BuildContext context, Offset offset) {
    CustomContextMenu.showMenuAt(
      context,
      position: offset,
      menuItems: messageHoldOptions(isMedia: false),
    );
  }
}

// ============================================================================
// INDIVIDUAL THREAD ITEM
// ============================================================================

class _ThreadItem extends StatelessWidget {
  final String text;
  final int index;
  final int total;
  final bool isSender;
  final VoidCallback onTap;
  final void Function(Offset) onLongPress;
  final void Function(int)? onClearPressed;

  const _ThreadItem({
    required this.text,
    required this.index,
    required this.total,
    required this.isSender,
    required this.onTap,
    required this.onLongPress,
    this.onClearPressed,
  });

  bool get isFirst => index == 0;
  bool get isLast => index == total - 1;
  bool get isSingle => total == 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left spacer (45px) - contains clear button for sender
          if (isSender) 
          SizedBox(
            width: 45,
            child: isSender && isLast
                ? _ClearButton(
                    index: index,
                    isSender: isSender,
                    onPressed: onClearPressed,
                  )
                : null,
          ),
          
          // Main thread tile with connectors
          Expanded(
            child: Stack(
              alignment: Alignment.topLeft,
              clipBehavior: Clip.none,
              children: [
                Stack(
                  alignment: Alignment.bottomLeft,
                  clipBehavior: Clip.none,
                  children: [
                    // Tile with bottom connectors
                    Stack(
                      alignment: Alignment.bottomLeft,
                      clipBehavior: Clip.none,
                      children: [
                        _ThreadTile(
                          text: text,
                          showTime: isLast,
                          isSender: isSender,
                          current: index + 1,
                          total: total,
                          onTap: onTap,
                          onLongPress: onLongPress,
                        ),
                        
                        // Bottom connectors
                        if (isSingle) const Ridge(),
                        if (!isLast) const Thether(),
                      ],
                    ),
                  ],
                ),
                
                // Top connector
                if (!isFirst) const Thether(top: true),
              ],
            ),
          ),
          
          // Right spacer (45px) - contains clear button for receiver
          if (!isSender) 
          SizedBox(
            width: 45,
            child: !isSender && isLast
                ? _ClearButton(
                    index: index,
                    isSender: isSender,
                    onPressed: onClearPressed,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// THREAD TILE (MESSAGE BUBBLE)
// ============================================================================

class _ThreadTile extends StatelessWidget {
  final String text;
  final bool showTime;
  final bool isSender;
  final int current;
  final int total;
  final VoidCallback onTap;
  final void Function(Offset) onLongPress;

  const _ThreadTile({
    required this.text,
    required this.showTime,
    required this.isSender,
    required this.current,
    required this.total,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.isLight
        ? (isSender ? ThemeConstants.senderBlue : Colors.grey)
        : (isSender ? ThemeConstants.senderBlueDark : Colors.blueGrey);
    const initString = "_Start typing your first thread_";

    return RippleWell(
      animated: true,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(15),
      materialColor: color,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          left: 25,
          right: 12,
          top: 10,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: color,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TypeSet(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      color: (text == initString) ? Colors.blueGrey : ( context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark ),
                    ),
                    softWrap: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    "$current/$total",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            if (showTime)
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
    );
  }
}

// ============================================================================
// CLEAR BUTTON
// ============================================================================

class _ClearButton extends StatelessWidget {
  final int index;
  final bool isSender;
  final void Function(int)? onPressed;

  const _ClearButton({
    required this.index,
    required this.isSender,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInBack,
        transitionBuilder: (child, animation) {
          final slideOffset = isSender
              ? const Offset(-0.4, 0) // Slide from left for sender
              : const Offset(0.4, 0);  // Slide from right for receiver

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: slideOffset,
                end: Offset.zero,
              ).animate(animation),
              child: RotationTransition(
                turns: Tween<double>(
                  begin: -0.25, // -90 degrees
                  end: 0,
                ).animate(animation),
                child: child,
              ),
            ),
          );
        },
        child: IconButton(
          key: ValueKey("clear_$index"),
          icon: const Icon(
            Icons.close_rounded,
            size: 18,
            color: Colors.white70,
          ),
          splashRadius: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          onPressed: () => onPressed?.call(index),
        ),
      ),
    );
  }
}