import 'dart:math';
import 'package:flutter/material.dart';
import 'package:notesapp/root/screens/Load_test/coin_animation.dart';

class CoinStackPullDown2 extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double triggerDistance;
  final double coinSize;
  final int coinCount;
  final Color backgroundColor;

  const CoinStackPullDown2({
    super.key,
    required this.child,
    required this.onRefresh,
    this.triggerDistance = 120,
    this.coinSize = 15,
    this.coinCount = 10,
    this.backgroundColor = Colors.white,
  });

  @override
  State<CoinStackPullDown2> createState() => _CoinStackPullDown2State();
}

class _CoinStackPullDown2State extends State<CoinStackPullDown2>
    with TickerProviderStateMixin {
  double pullDistance = 0;
  bool isRefreshing = false;
  late AnimationController _pullBackController;
  late Animation<double> _pullBackAnimation;

  // Controller for repeating coin cycles
  late AnimationController _coinCycleController;

  final double dragFactor = 0.5;

  @override
  void initState() {
    super.initState();
    _pullBackController = AnimationController(vsync: this);
    _pullBackAnimation =
        Tween<double>(begin: 0, end: 0).animate(_pullBackController);

    // One cycle = coin stack (1.1s) + slide down (0.5s)
    _coinCycleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void dispose() {
    _pullBackController.dispose();
    _coinCycleController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isRefreshing) return;
    setState(() {
      pullDistance += details.delta.dy * dragFactor;
      if (pullDistance < 0) pullDistance = 0;
      if (pullDistance > widget.triggerDistance * 1.5) {
        pullDistance = widget.triggerDistance * 1.5;
      }
    });
  }

  void _animateBack(double from, double to,
      {Curve curve = Curves.easeOut, int ms = 400}) {
    _pullBackController.stop();
    _pullBackController.duration = Duration(milliseconds: ms);
    _pullBackAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _pullBackController, curve: curve),
    )..addListener(() {
        setState(() {
          pullDistance = _pullBackAnimation.value;
        });
      });
    _pullBackController.forward(from: 0);
  }

  void _handleDragEnd(_) async {
    if (pullDistance >= widget.triggerDistance && !isRefreshing) {
      setState(() => isRefreshing = true);

      // Snap to trigger distance
      _animateBack(pullDistance, widget.triggerDistance,
          curve: Curves.easeOut, ms: 200);

      await Future.delayed(const Duration(milliseconds: 100));

      // Start looping coins
      _coinCycleController.repeat();

      await widget.onRefresh();

      // Stop looping coins after the current cycle finishes
      await _coinCycleController.forward(from: 0);
      _coinCycleController.stop();

      // Animate everything back up
      _animateBack(widget.triggerDistance, 0,
          curve: Curves.elasticOut, ms: 600);

      setState(() => isRefreshing = false);
    } else {
      // Animate back without triggering
      _animateBack(pullDistance, 0, curve: Curves.easeOut, ms: 300);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bgHeight = max(pullDistance, 0);

    return GestureDetector(
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Show background only if dragging or refreshing
          if (bgHeight > 0 || isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: bgHeight,
              child: Container(
                color: widget.backgroundColor,
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isRefreshing)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          pullDistance >= widget.triggerDistance
                              ? "Release to load"
                              : "Pull to load",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (isRefreshing)
                      SizedBox(
                        height: widget.coinSize * 5,
                        child: AnimatedBuilder(
                          animation: _coinCycleController,
                          builder: (context, _) {
                            final progress = _coinCycleController.value;

                            // First 70% = coin stack
                            if (progress < 0.7) {
                              return CoinAnimation(
                                coinSize: widget.coinSize,
                                coinCount: widget.coinCount,
                              );
                            }

                            // Last 30% = slide coins downward & fade out
                            final slideDown = (progress - 0.7) / 0.3;
                            return Transform.translate(
                              offset: Offset(0, slideDown * 80),
                              child: Opacity(
                                opacity: 1 - slideDown,
                                child: CoinAnimation(
                                  coinSize: widget.coinSize,
                                  coinCount: widget.coinCount,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Scrollable content moves down with pullDistance
          Transform.translate(
            offset: Offset(0, pullDistance),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
