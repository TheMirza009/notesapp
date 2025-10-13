import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Chat_Forward/notifier/selected_chat_notifier.dart';

class BlurredForwardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const BlurredForwardAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatlist = ref.watch(chatListProvider).chats;
    final selected = ref.watch(forwardingController);
    final notifier = ref.read(forwardingController.notifier);

    final allSelected = selected.length == chatlist.length && chatlist.isNotEmpty;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 25.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.05),
          surfaceTintColor: Colors.transparent,
          title: const Text("Forward to..."),
          actions: [
            IconButton(
              icon: Icon(allSelected ? Icons.remove_done : Icons.select_all),
              tooltip: allSelected ? "Unselect All" : "Select All",
              onPressed: () {
                if (allSelected) {
                  notifier.clear();
                } else {
                  notifier.selectAll(chatlist);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: search logic
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
