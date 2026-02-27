import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/string_extensions.dart';
import 'package:notesapp/core/extensions/time_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/components/message_bubble/content/thread_message/thether.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/components/message_bubble/helpers/ripple_well.dart';
import 'package:notesapp/root/presentation/widgets/context_menus/custom_context_menu.dart';
import 'package:typeset/typeset.dart';

/// Thread-style stacked message bubbles with visual connectors
class ThreadMessageView extends ConsumerWidget {
  final Message message;
  final VoidCallback onTap;
  final void Function(Offset)? onLongPress;
  final void Function(int)? onClearPressed;
  final double edgePadding;
  final EdgeInsetsGeometry? padding;

  // colors
  final Color tileColor;
  final Color highlightedColor;
  final bool isHighlighted;

  const ThreadMessageView({
    super.key,
    required this.message,
    required this.onTap,
    required this.tileColor,
    required this.highlightedColor,
    required this.isHighlighted,
    this.onLongPress,
    this.onClearPressed,
    this.edgePadding = 80.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   // ✅ Check if this is the active editing thread
    final activeThread = ref.watch(
      chatStateController.select((s) => s.activeEditingThread),
    );
    final isActiveThread = activeThread?.isarId == message.isarId;
    
    // ✅ Use live strings if editing, otherwise decode from message
    final List<String> strings = isActiveThread
        ? ref.watch(chatStateController.select((s) => s.activeThreadStrings))
        : message.text.safeDecode();

    if (strings.isEmpty) return const SizedBox.shrink();

    final isSender = message.isSender;
    final totalWidth = _calculateWidth(context, strings) + edgePadding;
    final isCancelled = ref.watch(
      chatStateController.select((s) => s.cancelledThread?.isarId == message.isarId),
    );

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      offset: isCancelled ? Offset(isSender ? 0.1 : -0.1, 0) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        opacity: isCancelled ? 0 : 1,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutQuint,
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuint,
            padding: padding ??
                EdgeInsets.only(
                  left: isSender ? 0 : 8,
                  right: isSender ? 8 : 0,
                  top: 12,
                  bottom: 12,
                ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                width: totalWidth + 45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(strings.length, (i) {
                    return _ThreadItem(
                      message: message,
                      config: _ThreadItemConfig(
                        text: strings[i],
                        index: i,
                        total: strings.length,
                        isSender: isSender,
                        colors: ThreadColors(
                          tile: tileColor,
                          highlighted: highlightedColor,
                          isHighlighted: isHighlighted,
                        ),
                      ),
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

   double _calculateWidth(BuildContext context, List<String> strings) {
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

    return maxWidth < minWidthPainter.width ? minWidthPainter.width : maxWidth;
  }

  void _showContextMenu(BuildContext context, Offset offset) {
    CustomContextMenu.showMenuAt(
      context,
      position: offset,
      menuItems: messageHoldOptions(message: message),
    );
  }
}

// ============================================================================
// DATA CLASSES (Reduce parameter passing)
// ============================================================================

class ThreadColors {
  final Color tile;
  final Color highlighted;
  final bool isHighlighted;

  const ThreadColors({
    required this.tile,
    required this.highlighted,
    required this.isHighlighted,
  });
}

class _ThreadItemConfig {
  final String text;
  final int index;
  final int total;
  final bool isSender;
  final ThreadColors colors;

  const _ThreadItemConfig({
    required this.text,
    required this.index,
    required this.total,
    required this.isSender,
    required this.colors,
  });

  bool get isFirst => index == 0;
  bool get isLast => index == total - 1;
  bool get isSingle => total == 1;
}

// ============================================================================
// INDIVIDUAL THREAD ITEM
// ============================================================================

class _ThreadItem extends ConsumerWidget {
  final _ThreadItemConfig config;
  final VoidCallback onTap;
  final void Function(Offset) onLongPress;
  final void Function(int)? onClearPressed;
  final Message message;

  const _ThreadItem({
    required this.config,
    required this.onTap,
    required this.onLongPress,
    required this.message,
    this.onClearPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThreading = ref.watch(chatStateController.select((s) => s.isThreading));
    final activeThread = ref.watch(chatStateController.select((s) => s.activeEditingThread));
    final isActive = activeThread?.isarId == message.isarId;

    return Padding(
      padding: EdgeInsets.only(bottom: config.isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left clear button (for sender)
          if (config.isSender)
            _ClearButtonSpace(
              show: isThreading && config.isLast && isActive,
              isSender: true,
              index: config.index,
              onPressed: onClearPressed,
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
                    _ThreadTile(
                      message: message,
                      config: config,
                      onTap: onTap,
                      onLongPress: onLongPress,
                    ),
                    if (config.isSingle) const Ridge(),
                    if (!config.isLast) const Thether(),
                  ],
                ),
                if (!config.isFirst) const Thether(top: true),
              ],
            ),
          ),

          // Right clear button (for receiver)
          if (!config.isSender)
            _ClearButtonSpace(
              show: isThreading && config.isLast && isActive,
              isSender: false,
              index: config.index,
              onPressed: onClearPressed,
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// CLEAR BUTTON SPACE (Animated wrapper)
// ============================================================================

class _ClearButtonSpace extends StatelessWidget {
  final bool show;
  final bool isSender;
  final int index;
  final void Function(int)? onPressed;

  const _ClearButtonSpace({
    required this.show,
    required this.isSender,
    required this.index,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInBack,
        transitionBuilder: (child, animation) {
          final slideOffset = Offset(isSender ? -0.4 : 0.4, 0);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(animation),
              child: RotationTransition(
                turns: Tween<double>(begin: -0.25, end: 0).animate(animation),
                child: child,
              ),
            ),
          );
        },
        child: show
            ? _ClearButton(
                key: ValueKey("clear_$index"),
                index: index,
                onPressed: onPressed,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ============================================================================
// THREAD TILE (MESSAGE BUBBLE)
// ============================================================================

class _ThreadTile extends StatelessWidget {
  final _ThreadItemConfig config;
  final VoidCallback onTap;
  final void Function(Offset) onLongPress;
  final Message message;

  const _ThreadTile({
    required this.config,
    required this.onTap,
    required this.onLongPress,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = context.isLight
        ? (config.isSender ? ThemeConstants.senderBlue : const Color(0xFFAFC0C9))
        : (config.isSender ? ThemeConstants.senderBlueDark : ThemeConstants.darkIconBorder);
    
    const initString = "_Start typing your first thread_";
    final isHighlighted = config.colors.isHighlighted;
    final color = config.colors.tile;

    return RippleWell(
      animated: true,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(15),
      materialColor: color,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutQuint,
        width: double.infinity,
        padding: const EdgeInsets.only(left: 25, right: 12, top: 10, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isHighlighted ? config.colors.highlighted : Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? Colors.white.withValues(alpha: context.isLight ? 0.9 : 0.3)
                  : Colors.transparent,
              blurRadius: isHighlighted ? 16 : 0,
              spreadRadius: isHighlighted ? 2 : 0,
            ),
          ],
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
                    config.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: (config.text == initString || config.text == "_Start typing next note_")
                          ? Colors.blueGrey
                          : (context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark),
                    ),
                    softWrap: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    "${config.index + 1}/${config.total}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            if (config.isLast)
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  message.time.to12HourString(),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
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
  final void Function(int)? onPressed;

  const _ClearButton({
    super.key,
    required this.index,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton.filled(
        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
        splashRadius: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        onPressed: () => onPressed?.call(index),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black12, // Set background color
        ),
      ),
    );
  }
}