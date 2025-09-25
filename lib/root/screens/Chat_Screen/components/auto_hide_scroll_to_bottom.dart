import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';

class AutoHideScrollToBottom extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onPressed;
  final double buffer;
  final double bottomPadding;
  final Duration animationDuration;
  final Curve animationCurve;
  final Widget? icon;
  final Color? backgroundColor;

  const AutoHideScrollToBottom({
    super.key,
    required this.scrollController,
    required this.onPressed,
    this.buffer = 50.0,
    this.bottomPadding = 135.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.icon,
    this.backgroundColor,
  });

  @override
  State<AutoHideScrollToBottom> createState() =>  _AutoHideScrollToBottomState();
}

class _AutoHideScrollToBottomState extends State<AutoHideScrollToBottom> with SingleTickerProviderStateMixin {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final distanceFromBottom =  widget.scrollController.position.maxScrollExtent -  widget.scrollController.offset;
    final shouldShow = distanceFromBottom > widget.buffer;
    if (shouldShow != _isVisible) {
      setState(() => _isVisible = shouldShow);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
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
                style: IconButton.styleFrom(backgroundColor: widget.backgroundColor),
                onPressed: widget.onPressed,
                icon: widget.icon ?? Iconify(Ph.caret_double_down),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
