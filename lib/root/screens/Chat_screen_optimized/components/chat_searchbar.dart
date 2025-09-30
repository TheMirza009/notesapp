import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_Screen/chat_screen_notifier_3.dart';
import 'package:notesapp/root/screens/Chat_screen_optimized/notifier/chat_state_notifier.dart';

class ChatSearchBar extends ConsumerWidget {
  const ChatSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("🔄 Searchbar rebuilt");
    final notifier = ref.read(chatStateController.notifier);
    final isSearching = ref.watch(chatStateController.select((s) => s.isSearching));
    final headerColor = context.isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;

    return AnimatedSize(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutQuint,
      child:
          isSearching
              ? Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  bottom: 0,
                  right: 12,
                  top: 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: isSearching ? 40 : 0,
                    // maxWidth: notifier.isSearching ? double.maxFinite : 0
                  ),
                  child: SearchBar(
                    focusNode: notifier.searchFocusNode,
                    controller: notifier.searchController,
                    autoFocus: false,
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(12),
                      ),
                    ),
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    shadowColor: WidgetStatePropertyAll(Colors.transparent),
                    backgroundColor: WidgetStatePropertyAll(headerColor),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Icon(
                        Icons.search,
                        color: ThemeConstants.iconLight,
                      ),
                    ),
                    trailing: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: notifier.searchController,
                        builder: (context, value, _) {
                          return value.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: notifier.clearSearch,
                              )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],

                    hintText: "Search in notes...",
                    hintStyle: WidgetStatePropertyAll(
                      TextStyle(
                        color: ThemeConstants.iconLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (value) => notifier.searchChats(value),
                  ),
                ),
              )
              : SizedBox.shrink(),
    );
  }
}
