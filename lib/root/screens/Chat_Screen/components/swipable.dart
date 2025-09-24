import 'package:flutter/material.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';

class Swipeable extends StatefulWidget {
  final Widget child;
  final bool isSender;
  final bool isSelecting;
  final VoidCallback? onTapWhileSelecting;
  final void Function()? onSwiped;

  const Swipeable({
    super.key,
    required this.child,
    required this.isSender,
    this.isSelecting = false,
    this.onTapWhileSelecting,
    this.onSwiped,
  });

  @override
  State<Swipeable> createState() => _SwipeableState();
}

class _SwipeableState extends State<Swipeable>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  final double swipeThreshold = 50.0; // swipe to trigger

  bool get _isDragging => _dragOffset.abs() > 0.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  void _resetPosition() {
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuint),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSender = widget.isSender;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Only render background icon while dragging
        if (_isDragging)
          replyIconBackground(context, alignLeft: !isSender),

        // Draggable effect using Transform.translate
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dx * 0.5; // resistive drag
            });
          },
          onHorizontalDragEnd: (details) {
            if ((isSender && _dragOffset < -swipeThreshold) ||
                (!isSender && _dragOffset > swipeThreshold)) {
              if (widget.onSwiped != null) widget.onSwiped!();
            }
            _resetPosition(); // always snap back
          },
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
