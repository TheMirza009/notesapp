import 'dart:io';
import 'dart:ui';
import 'dart:math' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/screens/Chat_Forward/notifier/selected_chat_notifier.dart';

class ExpandingSearchbar extends ConsumerStatefulWidget {
  const ExpandingSearchbar({super.key});

  @override
  ConsumerState<ExpandingSearchbar> createState() => _ExpandingSearchbarState();
}

class _ExpandingSearchbarState extends ConsumerState<ExpandingSearchbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ProviderSubscription<Set<String>>? _listenerSub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 350),
    );

    // ✅ Listen once here — this reacts every time provider state changes
    _listenerSub = ref.listenManual<Set<String>>(
      forwardingController,
      (_, __) {
        final notifier = ref.read(forwardingController.notifier);
        if (notifier.isSearching) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      },
    );
  }

  @override
  void dispose() {
    _listenerSub?.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(forwardingController.notifier);
    final headerColor = context.isLight
        ? ThemeConstants.hometoolbarLight2
        : ThemeConstants.darkAppbar;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value.clamp(0.0, 1.0);
        final screenWidth = MediaQuery.of(context).size.width;
        const horizontalPadding = 0.0;
        const collapsedSize = 40.0;
        final fullWidth = screenWidth - (horizontalPadding * 2);
        final height = kToolbarHeight * 0.74;
        final topOffset = (kToolbarHeight - height) / 2;
        // 🔹 Animate horizontal padding -> 10.0 when expanded, 0.0 when collapsed
        final dynamicPadding =
            lerpDouble(0.0, 10.0, Curves.easeInOut.transform(progress))!;

        // 🔹 Width expands from collapsedSize to full width minus side padding
        final width =
            lerpDouble(
              collapsedSize,
              fullWidth - (dynamicPadding * 2),
              Curves.easeInOut.transform(progress),
            )!;

        // 🔹 Left & right offset respect animated padding
        final leftOffset = screenWidth - dynamicPadding - width;
        final rightOffset = dynamicPadding;

        final isReversing = _controller.status == AnimationStatus.reverse;

        // 🟢 Hide only when fully collapsed
        if (isReversing && progress == 0.0) return const SizedBox.shrink();

        // 🔹 Fade logic
        double opacity;
         if (!isReversing) {
          double forwardLambda = 0.05;
          opacity = progress < forwardLambda
              ? Curves.easeIn.transform( progress / forwardLambda ) // progress / 0.25)
              : 1.0;
        } else {
          double reverseLambda = 0.25;
          opacity = progress > reverseLambda
              ? 1.0
              : Curves.easeOut.transform(progress / reverseLambda);
        }

        final searchColor =
            Color.lerp(
              (context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark2), // collapsed
              ThemeConstants.iconLight, // expanded
              Curves.easeInOut.transform(progress),
            )!;


        return Positioned(
          top: Platform.isWindows ? topOffset : kToolbarHeight / 1.45, // topOffset,
          left: leftOffset,
          right: rightOffset,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity:  opacity,
            curve: Curves.easeInOut,
            child: ClipRRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                height: height,
                width: width,
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔍 Search icon
                    IconButton(
                      icon: Icon(Icons.search, color: searchColor),
                       constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () {
                        if (!notifier.isSearching) {
                          notifier.toggleSearch(true);
                          notifier.searchFocusNode.requestFocus();
                        }
                      },
                    ),
                        
                    // 📝 TextField
                    if (progress > 0.1)
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            height: 25,
                            child: TextField(
                              focusNode: notifier.searchFocusNode,
                              controller: notifier.searchController,
                              onChanged: notifier.searchChats,
                              autofocus: true,
                              style: const TextStyle(
                                color: ThemeConstants.iconLight,
                                fontSize: 14,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                hintText: "Search chats...",
                                hintStyle: TextStyle(
                                  color: ThemeConstants.iconLight,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4),
                              ),
                              textAlignVertical: TextAlignVertical.center,
                            ),
                          ),
                        ),
                      ),
                        
                    // ❌ Close icon
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: progress > 0.7 ? 1 : 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: ThemeConstants.iconLight),
                         constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () {
                          notifier.toggleSearch(false);
                          notifier.searchFocusNode.unfocus();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
