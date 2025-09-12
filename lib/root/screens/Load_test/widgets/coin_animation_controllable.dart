import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:notesapp/core/Theme/icon_paths.dart';

class CoinAnimationControllable extends StatefulWidget {
  final double coinSize;
  final double dragOffset;
  final int coinCount;
  final bool allowSpin;
  final double triggerOffset; // when to start animation
  final double reverseThreshold; // when to reverse animation
  final Curve curve; // animation curve

  const CoinAnimationControllable({
    super.key,
    this.coinSize = 20,
    this.coinCount = 14,
    this.allowSpin = true,
    this.triggerOffset = 50,
    required this.dragOffset,
    this.reverseThreshold = 150,
    this.curve = Curves.linear,
  });

  @override
  State<CoinAnimationControllable> createState() => _CoinAnimationControllableState();
}

class _CoinAnimationControllableState extends State<CoinAnimationControllable>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  bool _hasStarted = false;
  double _lastDragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.coinCount, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + index * 100),
      );
    });

    _animations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: widget.curve))
        .toList();
  }

  @override
  void didUpdateWidget(CoinAnimationControllable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start animation if dragged past trigger
    if (!_hasStarted && widget.dragOffset >= widget.triggerOffset) {
      _startAnimation();
    }

    // Reverse animation if dragged back past reverse threshold
    if (_hasStarted &&
        widget.dragOffset < _lastDragOffset &&
        widget.dragOffset < widget.reverseThreshold) {
      _reverseAnimation();
    }

    // Reset if fully closed
    if (_hasStarted && widget.dragOffset == 0) {
      _resetAnimation();
    }

    _lastDragOffset = widget.dragOffset;
  }

  void _startAnimation() {
    _hasStarted = true;
    for (final c in _controllers) {
      c.forward();
    }
  }

  void _reverseAnimation() {
    for (final c in _controllers) {
      if (c.status == AnimationStatus.forward || c.status == AnimationStatus.completed) {
        c.reverse();
      }
    }
  }

  void _resetAnimation() {
    _hasStarted = false;
    for (final c in _controllers) {
      c.reset();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double startSpacingRatio = 3.0;
    final double endSpacingRatio = -0.25;
    final double totalHeight = widget.coinCount * widget.coinSize * startSpacingRatio;

    return SizedBox(
      height: totalHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Stack(
          children: List.generate(widget.coinCount, (index) {
            final double startY = -(250 + index * widget.coinSize * startSpacingRatio);
            final double endY = index * widget.coinSize * endSpacingRatio;

            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                final progress = _animations[index].value;
                final value = startY + (endY - startY) * progress;

                final rotation = widget.allowSpin
                    ? (-360 + 360 * progress) * (math.pi / 180)
                    : 0;
                final scale = progress;

                return Transform.translate(
                  offset: Offset(0, value),
                  child: Transform.rotate(
                    angle: rotation.toDouble(),
                    child: Transform.scale(scale: scale, child: child),
                  ),
                );
              },
              child: Image.asset(IconPaths.coin, height: widget.coinSize),
            );
          }),
        ),
      ),
    );
  }
}
