import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/screens/Chat_Forward/notifier/selected_chat_notifier.dart';
import 'package:notesapp/root/screens/Chat_Forward/widgets/expanding_searchbar.dart';

class BlurredForwardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const BlurredForwardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatlist = ref.watch(chatListProvider).chats;
    final selected = ref.watch(forwardingController);
    final notifier = ref.read(forwardingController.notifier);

    final allSelected = selected.length == chatlist.length && chatlist.isNotEmpty;
    final isSearching = notifier.isSearching;
    final animController = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 450),
    );

    if (isSearching) {
      animController.forward();
    } else {
      animController.reverse();
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 25.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base AppBar
            AppBar(
              elevation: 0,
              backgroundColor:
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.05),
              surfaceTintColor: Colors.transparent,
              title: const Text("Forward to..."),
              actions: [
                if (!isSearching)
                  IconButton(
                    icon: Icon(allSelected ? Icons.deselect_rounded : Icons.select_all),
                    tooltip: allSelected ? "Unselect All" : "Select All",
                    onPressed: () => allSelected
                        ? notifier.clear()
                        : notifier.selectAll(chatlist),
                  ),
                if (!isSearching)
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      notifier.toggleSearch(true);
                      notifier.searchFocusNode.requestFocus();
                    },
                  ),
              ],
            ),

            // Animated search overlay
            const ExpandingSearchbar(),
          ],
        ),
      ),
    );
  }
}
