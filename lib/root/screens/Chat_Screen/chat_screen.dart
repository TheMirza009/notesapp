import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/message_list_layout.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/date_chip.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/ripple_menu.dart';
import 'package:notesapp/root/screens/chat_screen/components/bottom_message_bar.dart' show BottomMessageBar;
import 'package:notesapp/root/screens/chat_screen/components/chat_appbar.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu_2.dart';
import 'package:notesapp/root/widgets/glass_container.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
import 'package:svg_flutter/svg.dart';

class ChatScreen extends ConsumerWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatScreenController(chatId).notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {

    });
    final currentChat = ref.watch(chatScreenController(chatId));
    final backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;
    if (currentChat.uuid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    String imageURL1 = "https://downloadscdn6.freepik.com/23/2149338/2149337920.jpg?filename=close-up-colored-plant-leaf.jpg&token=exp=1757671394~hmac=ae1b322f07f0d05b06685f2df9830845&filename=2149337920.jpg";
    String imageURL2 = 'https://4kwallpapers.com/images/wallpapers/dark-blue-pink-3840x2160-12661.jpg';

    return PopScope(
      onPopInvokedWithResult: (didPop, context) {
        notifier.removeChatIfEmpty();
      },
      child: GestureDetector(
        onTap: () => notifier.unSelectAllMessages(),
        child: Scaffold(
          body: Container(
            height: ThemeConstants.screenHeight,
            width: ThemeConstants.screenWidth,
            decoration: BoxDecoration(gradient: backgroundGradient, image: DecorationImage(
              image: NetworkImage(imageURL2),
              fit: BoxFit.fitHeight,
              )),
            child: Column(
              children: [
                ChatAppBar(
                  leading: notifier.isSelecting
                    ? IconButton(
                      onPressed: () => notifier.unSelectAllMessages(),
                      icon: Icon(Icons.clear, color: ThemeConstants.iconColorNeutral,),
                    )
                    : IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: ThemeConstants.iconColorNeutral,),
                    ),
                  title: notifier.isSelecting ? "${notifier.selectCount()} Notes selected" : currentChat.title ?? "New Note",
                  lastEdited: currentChat.messages.isNotEmpty ? currentChat.messages.last.time : DateTime.now(),
                  isSelecting: notifier.isSelecting,
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
                  actions: notifier.isSelecting
                    ? [ IconButton(onPressed: () => notifier.deleteSelected(), icon: Icon(Icons.delete_outline_rounded))]
                    : null,
                ),
                Expanded(
                  child: currentChat.messages.isEmpty 
                  ? NothingToSee() 
                  : ListView.builder(
                      padding: EdgeInsets.symmetric( horizontal: 0), // ThemeConstants.screenWidth * 0.03, ),
                      itemCount: currentChat.messages.toList().length + 1,
                      itemBuilder: (context, index) {
                        if (index == currentChat.messages.length) {
                          return Container(
                            height: 150,
                            color: Colors.transparent,
                          );
                        }
                        
                        final message = currentChat.messages.toList()[index];
                        final info = currentChat.messages.toList().layoutInfo(index);
                    
                        return Column(
                          children: [
                              if (info.showDateChip) DateChip(message.time),
                                MessageBubble(
                                  style: BubbleStyle.glass,
                                  message: message,
                                  isSelecting: notifier.isSelecting,
                                  topPadding: info.topPadding,
                                  bottomPadding: info.bottomPadding,
                                  onTapWhileSelecting: () {
                                    message.isSelected
                                        ? notifier.unselectMessage(message)
                                        : notifier.selectMessage(message);
                                  },
                                  // dismissBackground: dismissBackground(context, alignLeft: !message.isSender),
                                  onTap: () => notifier.toggleSender(message),
                                  onLongPress: (pos) {
                                    notifier.selectMessage(message);
                                    CustomContextMenu.showMenuAt(
                                      context,
                                      position: pos,
                                      menuItems: messageHoldOptions,
                                      triangleHorizontalOffset: message.isSender ? 120 : 40,
                                      onSelected: (val) => notifier.handleMessageMenuAction(val, message),
                                    );
                                  },
                                ),
                          ],
                        );
                      },
                    ),
                ),

                BottomMessageBar(
                  onEmojiTap: () => debugPrint("Emoji tapped"),
                  onAttachmentTap: () => notifier.pickImage(),
                  onMicTap: () => debugPrint(notifier.initText),
                  onSend: notifier.sendMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageContextMenu(
    BuildContext context,
    Offset details,
    Message message,
    VoidCallback onDeleteMessage,
  ) {
    CustomContextMenu2(
      position: details,
      items: [MenuItem.text("Delete", onDeleteMessage)],
    ).show(context);
  }
}
