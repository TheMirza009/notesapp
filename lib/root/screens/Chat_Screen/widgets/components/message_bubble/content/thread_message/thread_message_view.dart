import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/time_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/content/thread_message/thether.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/components/message_bubble/helpers/ripple_well.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:typeset/typeset.dart';

/// Thread-style stacked message bubbles with visual connectors
class ThreadMessageView extends ConsumerWidget {
  final Message message;
  final List<String> strings;
  final VoidCallback onTap;
  final void Function(Offset)? onLongPress;
  final void Function(int)? onClearPressed;
  final double edgePadding;
  final EdgeInsetsGeometry? padding;

  const ThreadMessageView({
    super.key,
    required this.message,
    required this.strings,
    required this.onTap,
    this.onLongPress,
    this.onClearPressed,
    this.edgePadding = 80.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (strings.isEmpty) return const SizedBox.shrink();

    final isSender = message.isSender;
    final totalWidth = _calculateWidth(context) + edgePadding;
    final bool isCancelled = ref.watch(
      chatStateController.select((s) => s.cancelledThread?.isarId == message.isarId)
    );
    return AnimatedSlide(
      duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
        offset: (isCancelled ?? false) ? Offset(isSender ? 0.1 : -0.1, 0) : Offset.zero,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
        opacity: (isCancelled ?? false) ? 0 : 1,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutQuint,
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuint,
            padding:
                padding ??
                EdgeInsets.only(
                  left: isSender ? 0 : 8, // Remove 45px padding
                  right: isSender ? 8 : 0, // Remove 45px padding
                  top: 12,
                  bottom: 12,
                ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
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

class _ThreadItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the ChatStateController to determine if we're threading
    final isThreading = ref.watch(chatStateController.select((s) => s.isThreading));
    // final isActiveThread = ref.watch(chatStateController.select((s) => s.activeEditingThread.text == ThreadMessageView.strings))
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left spacer (45px) - contains clear button for sender
          if (isSender)
            SizedBox(
              width: 45,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                transitionBuilder: (child, animation) {
                  final slideOffset = const Offset(-0.4, 0);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: slideOffset,
                        end: Offset.zero,
                      ).animate(animation),
                      child: RotationTransition(
                        turns: Tween<double>(
                          begin: -0.25,
                          end: 0,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                  );
                },
                // Show button only if threading is active AND it’s the last item
                child: (isThreading && isSender && isLast)
                    ? _ClearButton(
                        index: index,
                        isSender: isSender,
                        onPressed: onClearPressed,
                      )
                    : const SizedBox.shrink(),
              ),
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
                    // ✅ Wrap _ThreadTile in a Consumer to reactively rebuild
                    _ThreadTile(
                      text: text,
                      showTime: isLast,
                      isSender: isSender,
                      current: index + 1,
                      total: total,
                      onTap: onTap,
                      onLongPress: onLongPress,
                    ),
                    if (isSingle) const Ridge(),
                    if (!isLast) const Thether(),
                  ],
                ),
                if (!isFirst) const Thether(top: true),
              ],
            ),
          ),

          // Right spacer (45px) - contains clear button for receiver
          if (!isSender)
            SizedBox(
              width: 45,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                transitionBuilder: (child, animation) {
                  final slideOffset = const Offset(0.4, 0);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: slideOffset,
                        end: Offset.zero,
                      ).animate(animation),
                      child: RotationTransition(
                        turns: Tween<double>(
                          begin: -0.25,
                          end: 0,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                  );
                },
                // Show button only if threading is active AND it’s the last item
                child: (isThreading && !isSender && isLast)
                    ? _ClearButton(
                        index: index,
                        isSender: isSender,
                        onPressed: onClearPressed,
                      )
                    : const SizedBox.shrink(),
              ),
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
    super.key,
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
          final slideOffset = !isSender
              ? const Offset(-0.1, 0) // Slide from left for sender
              : const Offset(0.1, 0);  // Slide from right for receiver

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