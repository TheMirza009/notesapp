import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notesapp/root/screens/Load_test/widgets/coin_animation.dart';

/// A wrapper that repeats the [CoinAnimation] infinitely while refreshing.
/// - Plays one stack fully.
/// - Coins exit smoothly (slide down) before the next stack begins.
/// - Keeps looping until [isRefreshing] is false.
class RepeatableCoinStack extends StatefulWidget {
  final double coinSize;
  final int coinCount;
  final bool isRefreshing;
  final Duration exitDuration;

  const RepeatableCoinStack({
    super.key,
    required this.coinSize,
    required this.coinCount,
    required this.isRefreshing,
    this.exitDuration = const Duration(milliseconds: 800),
  });

  @override
  State<RepeatableCoinStack> createState() => _RepeatableCoinStackState();
}

class _RepeatableCoinStackState extends State<RepeatableCoinStack>
    with TickerProviderStateMixin {
  bool _showStack = true; // controls whether to show current stack
  late AnimationController _exitController;
  late Animation<double> _exitAnimation;
  Timer? _loopTimer;

  @override
  void initState() {
    super.initState();

    _exitController = AnimationController(
      vsync: this,
      duration: widget.exitDuration,
    );

    _exitAnimation = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _startLoop();
  }

  @override
  void didUpdateWidget(covariant RepeatableCoinStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _startLoop();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      _stopLoop();
    }
  }

  void _startLoop() {
    _loopTimer?.cancel();

    if (!widget.isRefreshing) return;

    // Schedule loop with delay equal to coin animation length
    _loopTimer = Timer.periodic(
      const Duration(milliseconds: 1100), // full cycle of CoinAnimation
      (_) async {
        if (!mounted || !widget.isRefreshing) return;

        // Trigger exit animation
        await _exitController.forward(from: 0);

        if (!mounted || !widget.isRefreshing) return;

        setState(() {
          _showStack = !_showStack; // swap to "new" stack
        });

        _exitController.reset();
      },
    );
  }

  void _stopLoop() {
    _loopTimer?.cancel();
    _exitController.reset();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _exitAnimation.value), // slide down on exit
          child: CoinAnimation(
            coinSize: widget.coinSize,
            coinCount: widget.coinCount,
            key: ValueKey(_showStack), // force rebuild each cycle
          ),
        );
      },
    );
  }
}
