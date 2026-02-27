import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class AutoHideScrollToBottom extends StatefulWidget {
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final int lastIndex; // total messages - 1
  final double bottomPadding;
  final Duration animationDuration;
  final Curve animationCurve;
  final Widget? icon;
  final Color? backgroundColor;

  const AutoHideScrollToBottom({
    super.key,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.lastIndex,
    this.bottomPadding = 135.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.icon,
    this.backgroundColor,
  });

  @override
  State<AutoHideScrollToBottom> createState() =>
      _AutoHideScrollToBottomState();
}

class _AutoHideScrollToBottomState extends State<AutoHideScrollToBottom>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.itemPositionsListener.itemPositions.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Find the max visible index (lowest item on screen)
    final maxVisible = positions.map((pos) => pos.index).reduce((a, b) => a > b ? a : b);

    final shouldShow = maxVisible < widget.lastIndex - 1; // not at bottom
    if (shouldShow != _isVisible) {
      setState(() => _isVisible = shouldShow);
    }
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      child: _isVisible
          ? Padding(
              padding: EdgeInsets.only(bottom: widget.bottomPadding),
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: widget.backgroundColor,
                ),
                onPressed: () {
                  widget.itemScrollController.scrollTo(
                    index: widget.lastIndex,
                    duration: widget.animationDuration,
                    curve: widget.animationCurve,
                  );
                },
                icon: widget.icon ?? const Iconify(Ph.caret_double_down),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
