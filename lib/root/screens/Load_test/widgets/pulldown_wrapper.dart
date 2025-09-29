import 'package:flutter/material.dart';
import 'package:notesapp/root/screens/Load_test/widgets/coin_animation_controllable.dart';

class PullDownWrapper extends StatefulWidget {
  final Widget child;
  final double maxRevealHeight;
  final Color backdropColor;

  const PullDownWrapper({
    super.key,
    required this.child,
    this.maxRevealHeight = 300,
    this.backdropColor = Colors.red,
  });

  @override
  State<PullDownWrapper> createState() => _PullDownWrapperState();
}

class _PullDownWrapperState extends State<PullDownWrapper> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _animationController;
  late Animation<double> _dragAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _dragAnimation = Tween<double>(begin: 0, end: 0).animate(_animationController)
      ..addListener(() {
        setState(() {
          _dragOffset = _dragAnimation.value;
        });
      });
  }

  void _animateTo(double target) {
  _dragAnimation = Tween<double>(begin: _dragOffset, end: target)
      .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint))
    ..addListener(() {
      setState(() {
        _dragOffset = _dragAnimation.value;
      });
    });
  _animationController.forward(from: 0).whenComplete(() {
    _dragOffset = target; // ensure final value
  });
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // The backdrop behind
        Positioned(
          top: -widget.maxRevealHeight + _dragOffset - 1,
          left: 0,
          right: 0,
          height: widget.maxRevealHeight,
          child: Container(
            color: widget.backdropColor,
            child: CoinAnimationControllable(
              key: ValueKey("coinAnim"),
              coinSize: 30,
              coinCount: 12,
              allowSpin: true,
              dragOffset: _dragOffset,
              triggerOffset: widget.maxRevealHeight * 0.10,
              reverseThreshold: widget.maxRevealHeight * 0.75,
              curve:  Curves.easeInOutQuint, // Curves.bounceInOut,
            ),
          ),
        ),

        // Foreground child
        GestureDetector(
          onVerticalDragUpdate: (details) {
            print(_dragOffset);
            setState(() {
              // Apply drag factor: resistance increases with dragOffset
              double dragFactor = 1.0 - (_dragOffset / widget.maxRevealHeight) * 0.9;
              if (dragFactor < 0.3) dragFactor = 0.3; // clamp so it never stops fully

              _dragOffset += details.delta.dy * dragFactor;

              if (_dragOffset < 0) _dragOffset = 0;
              if (_dragOffset > widget.maxRevealHeight) {
                _dragOffset = widget.maxRevealHeight;
              }
            });
          },
          onVerticalDragEnd: (details) {
            _animateTo(0); // always snap closed when released
          },
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: widget.child,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}