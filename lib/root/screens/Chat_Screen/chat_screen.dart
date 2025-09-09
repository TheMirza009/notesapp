import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier.dart';
import 'package:notesapp/root/screens/chat_screen/components/bottom_message_bar.dart' show BottomMessageBar;
import 'package:notesapp/root/screens/chat_screen/components/chat_appbar.dart';
import 'package:notesapp/root/screens/chat_screen/components/message_bubble.dart' show MessageBubble;
import 'package:notesapp/root/widgets/nothing_to_see.dart';

class ChatScreen extends ConsumerWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatScreenController.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
    notifier.init(chatId);
  });
    final currentChat = ref.watch(chatScreenController);
    final backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;

    return PopScope(
      onPopInvokedWithResult: (didPop, context) {
        notifier.removeChatIfEmpty();
      },
      child: Scaffold(
        body: Container(
          height: ThemeConstants.screenHeight,
          width: ThemeConstants.screenWidth,
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Column(
            children: [
              ChatAppBar(
                title: currentChat.title!,
                lastEdited: currentChat.messages.isNotEmpty
                    ? currentChat.messages.last.time
                    : DateTime.now(),
                onTitleTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => ChatDetailScreen(chat: currentChat),
                    ),
                  );
                },
                onOptionsPressed: () {
                  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                  showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      10,
                      200,
                      overlay.size.width - 10,
                      overlay.size.height - 200,
                    ),
                    items: const [
                      PopupMenuItem<String>(
                        value: "data",
                        child: Text("Data"),
                      ),
                      PopupMenuItem<String>(
                        value: "settings",
                        child: Text("Settings"),
                      ),
                    ],
                  );
                },
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: ThemeConstants.screenWidth * 0.03,
                  ),
                  children: currentChat.messages.isNotEmpty
                      ? currentChat.messages.map((message) {
                          return MessageBubble(
                            message: message,
                            onTap: () => notifier.toggleSender(message),
                            onDeleteMessage: () => notifier.deleteMessage(message),
                          );
                        }).toList()
                      : [const NothingToSee()],
                ),
              ),
              BottomMessageBar(
                onEmojiTap: () => debugPrint("Emoji tapped"),
                onAttachmentTap: () => debugPrint("Attachment tapped"),
                onMicTap: () => debugPrint(notifier.initText),
                onSend: notifier.sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
