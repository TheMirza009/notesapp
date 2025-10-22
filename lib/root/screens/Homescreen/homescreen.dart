import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/chat_extensions.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/chatlist_filter.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/message_list_wrapper.dart';
import 'package:notesapp/root/screens/Profile/wrappers/parent_slide_wrapper.dart';
import 'package:notesapp/root/screens/Profile/profile_screen.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/custom_icon_button.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_tile.dart';
import 'homescreen_state.dart';

class Homescreen extends ConsumerStatefulWidget {
  const Homescreen({super.key});

  @override
  ConsumerState<Homescreen> createState() => HomescreenState();
}

class HomescreenState extends HomeScreenBaseState {
  
  @override
  Widget build(BuildContext context) {
    final chatNotifier = ref.read(chatListProvider.notifier);
    final chatlist = ref.watch(chatListProvider.select((state) => state.chats));
    final isLoading = ref.watch(chatListProvider.select((state) => state.isLoading));
    final isLight = Theme.brightnessOf(context) == Brightness.light;
    final headerColor = isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
    final dividerColor = isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkIconBorder;
    final backgroundGradient = isLight ? Gradients.lightBackground : Gradients.darkBackground;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();

        if (isSliding) {
          setState(() => isSliding = false);
        } else if (lastBackPress == null || now.difference(lastBackPress!) > const Duration(seconds: 2)) {
          lastBackPress = now;
          Utils.showGlobalSnackBar("Press again to exit.", Colors.blueGrey);
        } else {
          SystemNavigator.pop();
        }
      },
      child: ParentSlideWrapper(
        overlay: ProfileScreen(
          leading: IconButton(
            onPressed: () => setState(() => isSliding = false),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: ThemeConstants.iconColorNeutral),
          ),
        ),
        trigger: isSliding,
        child: Scaffold(
          floatingActionButton: CustomIconButton(
            size: 60,
            splashColor: const Color.fromARGB(14, 96, 125, 139),
            onPressed: createNewChat,
            icon: Image.asset(IconPaths.addNoteLight, scale: 10),
          ),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: headerColor,
            shadowColor: Colors.transparent,
            toolbarHeight: 65,
            title: const Text("NotesApp", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            leading: Padding(padding: const EdgeInsets.only(left: 12), child: circularAvatar(isLight)),
            actions: [
              CustomContextMenu(
                icon: const Icon(Icons.more_vert),
                menuItems: homeScreenOptions,
                onSelected: handleContextMenuAction,
              ),
            ],
            systemOverlayStyle: SystemUiOverlayStyle(
              systemNavigationBarColor: context.isLight ? ThemeConstants.hometoolbarLight3 :ThemeConstants.messageBarDark,
            ) ,
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              height: context.screenHeight,
              width: context.screenWidth,
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(gradient: backgroundGradient),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, bottom: 8, right: 0),
                    child: Row(
                      spacing: Platform.isWindows ? 5 : 0,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 40),
                            child: SearchBar(
                              focusNode: searchFocusNode,
                              controller: searchController,
                              autoFocus: false,
                              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12))),
                              padding: WidgetStatePropertyAll(EdgeInsets.zero),
                              shadowColor: WidgetStatePropertyAll(Colors.transparent),
                              backgroundColor: WidgetStatePropertyAll(headerColor),
                              leading: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: ThemeConstants.iconLight,
                                ),
                              ),
                              trailing: [
                                searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(Icons.clear_rounded),
                                    onPressed: clearSearch,
                                  )
                                  : SizedBox.shrink(),
                              ],
                              hintText: "Search in notes...",
                              hintStyle: WidgetStatePropertyAll(
                                TextStyle(
                                  color: ThemeConstants.iconLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onChanged: (value) => chatNotifier.searchChats(value),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: IconButton(
                            onPressed: () {
                              CustomContextMenu.showMenuAt(
                                context,
                                position: Offset(context.screenWidth, kToolbarHeight * 2),
                                showTail: false,
                                menuItems: chatFilterOptions,
                                onSelected: (value) {
                                  final selectedFilter = ChatlistFilter.values.firstWhere((f) => f.name == value);
                                  chatNotifier.applyFilter(selectedFilter);
                                  },
                                triangleHorizontalOffset: 200,
                              );
                              // Navigator.push(
                              //   context,
                              //   CupertinoPageRoute(
                              //     builder: (_) => ProfileScreen(),
                              //   ),
                              // );
                              // ref.read(chatListProvider.notifier).applyFilter(ChatlistFilter.oldestCreated);
                            },
                            icon: Icon(
                              Icons.filter_list,
                              color: ThemeConstants.iconLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isLoading ? LoadIndicator() : chatlist.isEmpty
                      ? const NothingToSee()
                      : ListView.separated(
                          itemCount: chatlist.length,
                          itemBuilder: (context, index) {
                            final chat = chatlist[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, child) => Opacity(opacity: value, child: child),
                              child: ChatTile(
                                title: chat.title ?? "New Note",
                                subtitle: chat.loadLastMessage(),
                                chatPhotoPath: chat.chatPhotoPath,
                                time: TimeFormat.formatChatTime(chat.date),
                                onDismissed: (_) => chatNotifier.removeChat(chat),
                                onTap: () async => await navigateToChatScreen(chat),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => Divider(
                            thickness: 1,
                            indent: ThemeConstants.screenWidth * 0.07,
                            color: dividerColor,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
