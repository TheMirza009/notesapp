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
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/date_chip.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/glass_bubble.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/glass_bubble_2.dart';
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
    final notifier = ref.read(chatScreenController.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.init(chatId);
    });
    final currentChat = ref.watch(chatScreenController);
    final backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;
    if (currentChat == null) {
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
                  title: notifier.isSelecting ? "${notifier.selectCount()} Notes selected" : currentChat.title!,
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
                      itemCount: currentChat.messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == currentChat.messages.length) {
                          return Container(
                            height: 150,
                            color: Colors.transparent,
                          );
                        }
                        
                        final message = currentChat.messages[index];
                        final info = currentChat.messages.layoutInfo(index);
                    
                        return Column(
                          children: [
                              if (info.showDateChip) DateChip(message.time),
                                GlassBubble2(
                                  message: message,
                                  isSelecting: notifier.isSelecting,
                                  topPadding: info.topPadding,
                                  bottomPadding: info.bottomPadding,
                                  onTapWhileSelecting: () {
                                    message.isSelected
                                        ? notifier.unselectMessage(message)
                                        : notifier.selectMessage(message);
                                  },
                                  dismissBackground: dismissBackground(context, alignLeft: !message.isSender),
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
                                )

                            // Stack(
                            //   children: [
                            //     Padding(
                            //       padding: EdgeInsets.symmetric(
                            //         horizontal: 10,
                            //       ),
                            //       child: Dismissible(
                            //         key: ValueKey(message.id),
                            //         direction: message.isSender ? DismissDirection.endToStart : DismissDirection.startToEnd,
                            //         dismissThresholds: const {
                            //           DismissDirection.startToEnd: 1.0, // 100% (prevents auto-dismiss)
                            //           DismissDirection.endToStart: 1.0,
                            //         },
                            //         confirmDismiss: (direction) async => false, // never dismiss
                            //         movementDuration: Duration.zero, // 🔹 disables swipe-off animation
                            //         resizeDuration: null, // 🔹 prevents shrink animation
                            //         onUpdate: (details) {},
                            //         background: dismissBackground(context, alignLeft: !message.isSender),
                            //         child: MessageBubble(
                            //           message: message,
                            //           onTap: notifier.isSelecting
                            //             ? () {
                            //               message.isSelected
                            //               ? notifier .unselectMessage( message, )
                            //               : notifier .selectMessage( message, );
                            //             }
                            //             : () {
                            //               notifier.toggleSender(
                            //                 message,
                            //               );
                            //             },
                            //             onLongPress: (position) {
                            //             notifier.selectMessage(message);
                            //             CustomContextMenu.showMenuAt(
                            //               context,
                            //               position: position,
                            //               menuItems: messageHoldOptions,
                            //               triangleHorizontalOffset: message.isSender ? 120 : 40,  
                            //               onSelected: (val) {
                            //                 if (val == 'deleteMessage') notifier.deleteMessage(message);
                            //               },
                            //             );
                            //           },
                            //         ),
                            //       ),
                            //     ),
                            //     if (notifier.isSelecting)
                            //     Positioned.fill(
                            //       child: GestureDetector(
                            //         onTap: () {
                            //           message.isSelected ? notifier .unselectMessage( message, ) : notifier .selectMessage( message, );
                            //         },
                            //         child: Container(
                            //           color: message.isSelected
                            //           ? ThemeConstants .sinisterSeed .withValues(alpha: 0.2)
                            //           : Colors.transparent,
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
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

Widget dismissBackground(BuildContext context, {required bool alignLeft}) {
    return Container(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.string(
            IconPaths.messageReply,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark2,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
