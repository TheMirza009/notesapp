import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Clickable Circle')
Widget previewClickableCircle() { // 👈 Change return type from 'ClickableCircle' to 'Widget'
  return ClickableCircle(
    size: 60.0, 
    onTap: () => print('Tapped!'),
    child: const Icon(Icons.car_crash, color: Colors.white), 
  );
}

@Preview(name: 'Drop Down') 
Widget previewDropDown() {
  return DropdownButton<String>(
    items: [
      DropdownMenuItem(value: 'Option 1', child: Text('Option 1')),
      DropdownMenuItem(value: 'Option 2', child: Text('Option 2')),
    ],
    onChanged: (value) {
      print('Selected: $value');
    },
    hint: Text('Select an option'),
  );
}

class ClickableCircle extends StatefulWidget {
  final Widget child;  // This can be any widget (Icon, Image, etc.)
  final double size;  // Size of the clickable circle
  final VoidCallback onTap;  // Callback for when the circle is tapped
  final VoidCallback? onLongPress; // Nullable callback for long press
  final Color splashColor;  // Color for splash effect
  final Color highlightColor;  // Color for highlight effect
  final EdgeInsets? padding;

  const ClickableCircle({
    super.key,
    required this.child,
    this.size = 50.0,  // Default size is 50
    required this.onTap,
    this.onLongPress,  // Nullable long press callback
    this.splashColor = Colors.grey,  // Default splash color
    this.highlightColor = Colors.transparent,  // Default highlight color
    this.padding,
  });

  @override
  _ClickableCircleState createState() => _ClickableCircleState();
}

class _ClickableCircleState extends State<ClickableCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLongPress = false; // Track if the user is holding the circle

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300), // Default duration for quick tap
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startLongPress() {
    if (widget.onLongPress != null) {
      widget.onLongPress!();  // Trigger the onLongPress callback if it's provided
    }

    setState(() {
      _isLongPress = true;
    });

    // Change animation duration for long press to slow down the effect
    _controller.duration = Duration(milliseconds: 600); // Slower duration
    _controller.forward(from: 0.0); // Keep the splash effect visible
  }

  void _endLongPress() {
    setState(() {
      _isLongPress = false;
    });

    // Return to the normal fade speed
    _controller.duration = Duration(milliseconds: 300); // Faster duration
    _controller.reverse();  // Fade out the splash effect when long press ends
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();  // Trigger the onTap callback
        if (!_isLongPress) {
          _controller.forward(from: 0.0);  // Trigger fade animation on tap
          Future.delayed(Duration(milliseconds: 100), () {
            _controller.reverse();  // Fade out splash after 100ms
          });
        }
      },
      onLongPressStart: (_) {
        _startLongPress();  // Trigger the long press behavior
      },
      onLongPressEnd: (_) {
        _endLongPress();  // End the long press and return to normal fade
      },
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            padding: widget.padding,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.highlightColor,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Splash effect (fade out after tap, hold during long press)
                  if (_fadeAnimation.value > 0)
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.splashColor.withOpacity(_fadeAnimation.value),
                      ),
                    ),
                  // Icon/Image in the center
                  child!,
                ],
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
