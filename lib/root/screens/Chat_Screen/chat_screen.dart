import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/date_chip.dart';
import 'package:notesapp/root/screens/chat_screen/components/bottom_message_bar.dart' show BottomMessageBar;
import 'package:notesapp/root/screens/chat_screen/components/chat_appbar.dart';
import 'package:notesapp/root/screens/chat_screen/components/message_bubble.dart' show MessageBubble;
import 'package:notesapp/root/widgets/glass_container.dart';
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
                child: currentChat.messages.isEmpty 
                ? NothingToSee() 
                : ListView.builder(
                  padding: EdgeInsets.symmetric( horizontal: ThemeConstants.screenWidth * 0.03, ),
                  itemCount: currentChat.messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == currentChat.messages.length) {
                      return Container(height: 150, color: Colors.transparent);
                    }

                    final message = currentChat.messages[index];
                    final prevMessage = index > 0 ? currentChat.messages[index - 1] : null;

                    // Check if a new date chip should be shown
                    final showDateChip =
                        prevMessage == null ||
                        message.time.day != prevMessage.time.day ||
                        message.time.month != prevMessage.time.month ||
                        message.time.year != prevMessage.time.year;

                    return Column(
                      children: [
                        if (showDateChip) DateChip(message.time),
                        // Align(
                        //   alignment: message.isSender ? Alignment.centerLeft : Alignment.centerRight,
                        //   child: Padding(
                        //     padding: const EdgeInsets.all(8.0),
                        //     child: GlassContainer(
                        //       backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        //       borderRadius: 20,
                        //       child: Text(message.text),
                        //       ),
                        //   ),
                        // )
                        MessageBubble(
                          message: message,
                          onTap: () => notifier.toggleSender(message),
                          onDeleteMessage: () => notifier.deleteMessage(message),
                        ),
                      ],
                    );
                  },
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
