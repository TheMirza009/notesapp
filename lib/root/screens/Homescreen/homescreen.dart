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
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/chatlist_filter.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_screen/chat_screen.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/old_notifiers/chat_state_notifier_5.dart';
import 'package:notesapp/root/screens/Chat_screen/widgets/wrappers/message_list_wrapper.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_list/doc_icon.dart';
import 'package:notesapp/root/screens/Profile/wrappers/parent_slide_wrapper.dart';
import 'package:notesapp/root/screens/Profile/profile_screen.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/custom_icon_button.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_list/chat_tile.dart';
import 'package:notesapp/root/widgets/video_view/video_gallery_player.dart';
import 'package:typeset/typeset.dart';
import 'homescreen_state.dart';

class Homescreen extends ConsumerStatefulWidget {
  const Homescreen({super.key});

  @override
  ConsumerState<Homescreen> createState() => HomescreenState();
}

class HomescreenState extends HomeScreenBaseState {

  final Map<int, GlobalKey> _chatKeys = {};
  

  GlobalKey _getChatKey(Chat chat) {
    return _chatKeys.putIfAbsent(chat.isarID, () => GlobalKey());
  }

  
  Future<void> _deleteChatWithFade(Chat chat) async {
    final chatNotifier = ref.read(chatListProvider.notifier);
    ref.read(chatListProvider.notifier).clearSearch();
    // Trigger fade-out
    setState(() => chatNotifier.isDeleting[chat.isarID] = true);
    chatNotifier.applyFilter(filter);

    // Wait for fade animation
    await Future.delayed(const Duration(milliseconds: 300));

    // Now delete from database + state
    await ref.read(chatListProvider.notifier).deleteChatWithUndo(chat);  //removeChat(chat);

    // Clean up fade flag (in case the list is rebuilt later)
    chatNotifier.isDeleting.remove(chat.isarID);
  }
  
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
        overlay: RepaintBoundary(
          child: ProfileScreen(
            leading: IconButton(
              onPressed: () => setState(() => isSliding = false),
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: ThemeConstants.iconColorNeutral),
            ),
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
            title: const Text("NotesApp", style: TextStyle(fontSize: 22, fontFamily: "Poppins", fontWeight: FontWeight.w500)),
            leading: Padding(padding: const EdgeInsets.only(left: 12), child: circularAvatar(isLight)),
            actions: [
              // IconButton(onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => VideoGalleryPlayer(media: Media.fromFilePath(samplePhone)))), icon: Icon(Icons.play_arrow)),
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
                              onChanged: (value) async {
                                if (value.isNotEmpty) {
                                  await chatNotifier.searchMessages(value);
                                } else {
                                  chatNotifier.clearSearch();
                                }
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: IconButton(
                            onPressed: () {
                              CustomContextMenu.showMenuAt(
                                context,
                                position: Offset(
                                  context.screenWidth,
                                  kToolbarHeight * 2,
                                ),
                                showTail: false,
                                menuItems: chatFilterOptions,
                                onSelected: (value) {
                                  final selectedFilter = ChatlistFilter.values
                                      .firstWhere((f) => f.name == value);
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
                                final searchResults = ref.watch(
                                  chatListProvider.select(
                                    (state) => state.searchResults,
                                  ),
                                );
                                final matchingMessages = searchResults[chat] ?? [];
                                // print(searchResults);
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: chatNotifier.isDeleting[chat.isarID] == true ? 1.0 : 0.0, end: chatNotifier.isDeleting[chat.isarID] == true ? 0.0 : 1.0),
                                  duration: const Duration(milliseconds: 300),
                                  builder: (context, value, child) => Opacity(opacity: value, child: child),
                                  child: matchingMessages.isEmpty
                                    ? ChatTile(
                                      key: _getChatKey(chat),
                                      isPinned: chat.isPinned,
                                      title: chat.title ?? "New Note",
                                      subtitle: chat.loadLastMessageFull().getMessageDisplayText, // loadLastMessageTextFormatted(), //loadLastMessage(),
                                      chatPhotoPath: chat.chatPhotoPath,
                                      time: TimeFormat.formatChatTime( chat.date, ),
                                      onDismissed: (_) async => await chatNotifier.deleteChatWithUndo(chat), // _deleteChatWithFade(chat),// chatNotifier.removeChat( chat, ),
                                      onTap: () async => await navigateToChatScreen(chat),
                                      onLongPress: () {
                                        final position = Utils.getObjectPosition( objectKey: _getChatKey( chat, ), );
                                        CustomContextMenu.showMenuAt(
                                          context,
                                          position: position,
                                          menuItems: chatTileOptions(chat),
                                          onSelected: (value) {
                                            if (value == "delete") {
                                              _deleteChatWithFade(chat);
                                            }
                                            chatNotifier.handleChatHoldOptions(value, chat);
                                            },
                                        );
                                      },
                                    )
                                    : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              TypeSet("_${matchingMessages.length} matches found", style: TextStyle(color: ThemeConstants.subtitleLight),),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    spacing: 10,
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      chat.chatPhotoPath == null
                                                          ? DocumentIcon(size: 25, iconPadding: EdgeInsets.all(2), borderWidth: 2,)
                                                          : Container(
                                                            margin: EdgeInsets.only( top: 5, ),
                                                            height: 25,
                                                            width: 25,
                                                            clipBehavior: Clip.antiAlias,
                                                            decoration: BoxDecoration( shape: BoxShape.circle),
                                                            child: Image.file(
                                                              File( chat.chatPhotoPath!, ),
                                                              fit: BoxFit .cover,
                                                            ),
                                                          ),
                                                          Text(
                                                            chat.title ??
                                                                "New Note",
                                                            style: TextStyle(
                                                              fontSize: 17,
                                                            ),
                                                          ),
                                                    ],
                                                  ),
                                                  Text( TimeFormat.formatChatTime( chat.date, ), style: TextStyle(fontSize: 12, color: ThemeConstants.subtitleLight),)
                                                    ],
                                                  ),
                                                ],
                                          ),
                                        ),

                                        // ChatTile(
                                        //   title: chat.title ?? "New Note",
                                        //   subtitle: chat.loadLastMessage(),
                                        //   chatPhotoPath: chat.chatPhotoPath,
                                        //   time: TimeFormat.formatChatTime( chat.date, ),
                                        //   onDismissed: (_) => chatNotifier .removeChat(chat),
                                        //   onTap: () async {
                                        //     if (matchingMessages.isNotEmpty) {
                                        //       ref.read(chatListProvider.notifier).navigateAndHighlight(context, matchingMessages.first, chat);
                                        //     } else {
                                        //       await navigateToChatScreen(chat);
                                        //     }
                                        //   },
                                        // ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric( horizontal: 16.0, vertical: 8.0, ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: matchingMessages.map( 
                                              (message) => _buildMessagePreview(message, searchController.text, chat), ).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                );
                              },
                              separatorBuilder:
                                  (context, index) => Divider(
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

  // Add these helper methods in your HomescreenState class
  String _buildSubtitle(
    Chat chat,
    List<Message> matchingMessages,
    String query,
  ) {
    if (matchingMessages.isEmpty) {
      return chat.loadLastMessage();
    } else if (matchingMessages.length == 1) {
      return _highlightText(matchingMessages.first.text, query);
    } else {
      return "${matchingMessages.length} matches found";
    }
  }

  String _highlightText(String text, String query) {
    // Simple highlighting by returning the text as-is
    // You can enhance this to actually highlight the matching parts
    return text;
  }

  Widget _buildMessagePreview(Message message, String query, Chat chat) {
    final dividerColor =
        context.isLight
            ? ThemeConstants.homeDividerLight
            : ThemeConstants.darkIconBorder;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      children: [
        Divider(thickness: 1, height: 2, color: dividerColor.withOpacity(0.5), indent: 20, endIndent: 20,),
        Material(
          color: Colors.transparent,
           borderRadius: BorderRadius.circular(8.0),
           clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async => ref.read(chatListProvider.notifier).navigateAndHighlight(context, message, chat),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: ThemeConstants.subtitleLight.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Highlighted text with matching query
                        _buildHighlightedText(message.text, query, isLight),
                        const SizedBox(height: 4),
                        Text(
                          TimeFormat.formatChatTime(message.time),
                          style: TextStyle(
                            fontSize: 10,
                            color: ThemeConstants.subtitleLight.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedText(String text, String query, bool isLight) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(fontSize: 12, color: ThemeConstants.subtitleLight),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      final queryIndex = lowercaseText.indexOf(lowercaseQuery, currentIndex);

      if (queryIndex == -1) {
        // No more matches, add the remaining text
        spans.add(TextSpan(text: text.substring(currentIndex)));
        break;
      }

      // Add text before the match
      if (queryIndex > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, queryIndex)));
      }

      // Add the highlighted match
      spans.add(
        TextSpan(
          text: text.substring(queryIndex, queryIndex + query.length),
          style: TextStyle(
            backgroundColor: isLight ? Colors.yellow[300] : Colors.amber[700],
            color: isLight ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      currentIndex = queryIndex + query.length;
    }

    return Expanded(
      child: RichText(
        text: TextSpan(
          style: TextStyle(overflow: TextOverflow.fade, fontFamily: 'Poppins', fontSize: 12, color: ThemeConstants.subtitleLight),
          children: spans,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
