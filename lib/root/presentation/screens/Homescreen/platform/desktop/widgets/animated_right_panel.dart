import 'package:flutter/material.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/chat_screen.dart';

class AnimatedRightPanel extends StatefulWidget {
  final Chat? selectedChat;
  final List<Chat> chatList;
  final Gradient backgroundGradient;
  final Widget chatScreen;

  const AnimatedRightPanel({
    super.key, 
    required this.selectedChat,
    required this.chatList,
    required this.backgroundGradient,
    required this.chatScreen,
  });

  @override
  State<AnimatedRightPanel> createState() => _AnimatedRightPanelState();
}

class _AnimatedRightPanelState extends State<AnimatedRightPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  Chat? _previousChat;
  Chat? _currentChat;
  Offset _beginOffset = const Offset(0, 0.04); // slide up from below

  @override
  void initState() {
    super.initState();
    _currentChat = widget.selectedChat;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_controller);
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedRightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedChat?.isarID == widget.selectedChat?.isarID) return;

    _previousChat = oldWidget.selectedChat;
    _currentChat = widget.selectedChat;

    _beginOffset = _resolveDirection(
      previous: _previousChat,
      next: _currentChat,
      chatList: widget.chatList,
    );

    _slide = Tween<Offset>(begin: _beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(from: 0);
  }

  /// Resolves slide direction based on selection change:
  /// - null → non-null: slide up from below
  /// - non-null → null: fade only (no slide)
  /// - going to higher index: slide up from below
  /// - going to lower index: slide down from above
  Offset _resolveDirection({
    required Chat? previous,
    required Chat? next,
    required List<Chat> chatList,
  }) {
    // Becoming null — fade only
    if (next == null) return Offset.zero;

    // Was null — slide up from below
    if (previous == null) return const Offset(0, 0.04);

    final prevIndex = chatList.indexWhere((c) => c.isarID == previous.isarID);
    final nextIndex = chatList.indexWhere((c) => c.isarID == next.isarID);

    if (prevIndex == -1 || nextIndex == -1) return const Offset(0, 0.04);

    // Going to lower index (up in list) → slide down from above
    // Going to higher index (down in list) → slide up from below
    return nextIndex < prevIndex
        ? const Offset(0, -0.04)
        : const Offset(0, 0.04);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentChat == null) {
      return FadeTransition(
        opacity: _fade,
        child: Container(
           width: double.infinity,
           height: double.infinity,
          decoration: BoxDecoration(gradient: widget.backgroundGradient),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note_rounded,
                    size: 64,
                    color: ThemeConstants.subtitleLight.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  "Select a note to view",
                  style: TextStyle(
                    fontSize: 16,
                    color: ThemeConstants.subtitleLight.withOpacity(0.5),
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.chatScreen,
      ),
    );
  }
}