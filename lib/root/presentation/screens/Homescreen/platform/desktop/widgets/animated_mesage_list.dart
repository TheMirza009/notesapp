import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/widgets/wrappers/message_list_wrapper.dart';
import 'package:notesapp/root/data/models/chat_model.dart';

class AnimatedMessageList extends ConsumerStatefulWidget {
  const AnimatedMessageList({super.key});

  @override
  ConsumerState<AnimatedMessageList> createState() => _AnimatedMessageListState();
}

class _AnimatedMessageListState extends ConsumerState<AnimatedMessageList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  int? _previousChatId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220), // slightly snappier
    );
    // Initialize with proper tweens from the start
    _fade = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.value = 1.0;
    _previousChatId = ref.read(chatListProvider).selectedChat?.isarID;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

void _triggerAnimation(Chat? previous, Chat? next, List<Chat> chatList) {
  Offset beginOffset = const Offset(0, 0.09);

  if (next == null) {
    beginOffset = Offset.zero;
  } else if (previous == null) {
    beginOffset = const Offset(0, 0.09);
  } else {
    final prevIndex = chatList.indexWhere((c) => c.isarID == previous.isarID);
    final nextIndex = chatList.indexWhere((c) => c.isarID == next.isarID);
    if (prevIndex != -1 && nextIndex != -1) {
      beginOffset = nextIndex < prevIndex
          ? const Offset(0, -0.09)
          : const Offset(0, 0.09);
    }
  }

  // Rebuild both tweens with fresh CurvedAnimation each trigger
  final curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  final fadeCurved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  _slide = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curved);
  _fade = Tween<double>(begin: 0.0, end: 1.0).animate(fadeCurved);

  // setState forces build() to pick up the new tween references
  if (mounted) setState(() {});
  _controller.forward(from: 0);
}

  @override
  Widget build(BuildContext context) {
    ref.listen(
      chatListProvider.select((s) => s.selectedChat),
      (previous, next) {
        if (previous?.isarID == next?.isarID) return;
        final chatList = ref.read(chatListProvider).chats;
        _triggerAnimation(previous, next, chatList);
        _previousChatId = next?.isarID;
      },
    );

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: const MessageListWrapper(),
      ),
    );
  }
}