import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/chat_extensions.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_Forward/notifier/selected_chat_notifier.dart';
import 'package:notesapp/root/presentation/screens/Chat_Forward/widgets/blurred_appbar.dart';
import 'package:notesapp/root/presentation/screens/Chat_Forward/widgets/selection_check.dart';
import 'package:notesapp/root/presentation/screens/Chat_Forward/widgets/send_button.dart';
import 'package:notesapp/root/presentation/screens/Homescreen/components/chat_list/chat_tile.dart';
import 'package:notesapp/root/presentation/widgets/nothing_to_see.dart';

class ChatForwardScreen extends ConsumerWidget {
  final Message message;
  final bool? isSend;
  const ChatForwardScreen({super.key, required this.message, this.isSend = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatlist = ref.watch(chatListProvider).chats;
    final selectedIds = ref.watch(forwardingController);
    final notifier = ref.read(forwardingController.notifier);

    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundGradient = isLight ? Gradients.lightBackground : Gradients.darkBackground;
    return PopScope(
      canPop: notifier.isSearching == false,
      onPopInvokedWithResult: (didPop, result) {
        notifier.clearSearch();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: BlurredForwardAppBar(isSend: isSend),
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: chatlist.isEmpty
                      ? const NothingToSee()
                      : ListView.builder(
                          itemCount: chatlist.length + 1,
                          itemBuilder: (context, index) {
                            if (index == chatlist.length) {
                              return const SizedBox(height: 150);
                            }
      
                            final chat = chatlist[index];
                            final isSelected = selectedIds.contains(chat.uuid);
      
                            return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, value, child) => Opacity(opacity: value, child: child),
                              child: ChatTile(
                                title: chat.title ?? "New Note",
                                subtitle: chat.loadLastMessage(),
                                chatPhotoPath: chat.chatPhotoPath,
                                time: TimeFormat.formatChatTime(chat.date),
                                isDismissible: false,
                                onTap: () => notifier.toggleSelect(chat.uuid),
                                trailing: SelectionCheck(
                                  isSelected: isSelected,
                                  onTap: () => notifier.toggleSelect(chat.uuid),
                                ),
                              ),
                            );
                          },
                        ),
                ),
      
                // ✅ Floating send button
                SendButton(
                  backgroundColor: ThemeConstants.sinisterSeed,
                  isVisible: selectedIds.isNotEmpty,
                  onPressed: () async => await notifier.forwardMessageToSelected(message),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
