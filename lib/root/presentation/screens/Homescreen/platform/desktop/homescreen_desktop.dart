import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/user_provider.dart';
import 'package:notesapp/core/extensions/chat_extensions.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/core/utils/windows_utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/domain/usecases/delete_chat_usecase.dart';
import 'package:notesapp/root/data/enums/chatlist_filter.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/chat_screen.dart';
import 'package:notesapp/root/presentation/screens/Homescreen/components/chat_list/chat_tile.dart';
import 'package:notesapp/root/presentation/screens/Homescreen/components/chat_list/doc_icon.dart';
import 'package:notesapp/root/presentation/screens/Homescreen/platform/desktop/widgets/animated_right_panel.dart';
import 'package:notesapp/root/presentation/screens/Homescreen/platform/desktop/widgets/desktop_icon_rail.dart';
import 'package:notesapp/root/presentation/screens/Profile/profile_screen.dart';
import 'package:notesapp/root/presentation/screens/Profile/wrappers/parent_slide_wrapper.dart';
import 'package:notesapp/root/presentation/screens/Settings/notifier/settings_notifier.dart';
import 'package:notesapp/root/presentation/screens/Settings/settings_screen.dart';
import 'package:notesapp/root/presentation/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/presentation/widgets/custom_icon_button.dart';
import 'package:notesapp/root/presentation/widgets/custom_icon_dialogue.dart';
import 'package:notesapp/root/presentation/widgets/nothing_to_see.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:typeset/typeset.dart';

class HomeScreenDesktop extends ConsumerStatefulWidget {
  const HomeScreenDesktop({super.key});

  @override
  ConsumerState<HomeScreenDesktop> createState() => _HomeScreenDesktopState();
}

class _HomeScreenDesktopState extends ConsumerState<HomeScreenDesktop> {
  final Map<int, GlobalKey> _chatKeys = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(canRequestFocus: false);

  bool _isSliding = false;
  RailTab _selectedTab = RailTab.chats;
  // Chat? _selectedChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userController.notifier).loadUser();
      _checkPendingDeletions();
    });
  }

  Future<void> _checkPendingDeletions() async {
    final useCase = ref.read(deleteChatUseCaseProvider);
    final count = await useCase.getAndClearPendingDeletions();
    if (count > 0 && mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return CustomAlertDialog(
            title: "Chats Restored",
            content: "Deleted chats were restored due to the app closing unexpectedly.",
            iconData: Mdi.restore,
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  GlobalKey _getChatKey(Chat chat) =>
      _chatKeys.putIfAbsent(chat.isarID, () => GlobalKey());

  // ACTIONS

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    ref.read(chatListProvider.notifier).clearSearch();
  }

  Future<void> _selectChat(Chat chat) async {
    ref.read(chatListProvider.notifier).selectChat(chat);
    // setState(() => _selectedChat = chat);
     chat.messages.load();
     Future.wait(chat.messages.map((m) => m.media.load()));
  }

  Future<void> _createNewChat() async {
    final newChat = await ref.read(chatListProvider.notifier).addChat();
    await newChat.messages.load();
    ref.read(chatListProvider.notifier).selectChat(newChat);
    ref.read(isNewChat.notifier).state = true;
    // setState(() => _selectedChat = newChat);
  }

  Future<void> _deleteChatWithFade(Chat chat) async {
    final chatNotifier = ref.read(chatListProvider.notifier);
    final deleteUseCase = ref.read(deleteChatUseCaseProvider);
    final selectedChat = ref.read(chatListProvider).selectedChat;

    chatNotifier.clearSearch();
    setState(() => chatNotifier.isDeleting[chat.isarID] = true);
    await Future.delayed(const Duration(milliseconds: 300));
    deleteUseCase.queueDelete(chat);
    chatNotifier.isDeleting.remove(chat.isarID);
    if (selectedChat?.isarID == chat.isarID) {
      chatNotifier.clearSelectedChat(); 
    }
  }

  void _handleContextMenuAction(String value) {
    final chatNotifier = ref.read(chatListProvider.notifier);
    switch (value) {
      case "profile":
        setState(() => _isSliding = true);
        WindowsUtils.setTitleBarColorDirect(
            context.isLight ? Gradients.silverSunlight2 : Gradients.shadowBlue);
        break;
      case "settings":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()));
        WindowsUtils.setTitleBarColorDirect(
            context.isLight ? Gradients.silverSunlight2 : Gradients.shadowBlue);
        break;
      case "deleteAll":
        showDialog(
          context: context,
          builder: (_) => CustomAlertDialog(
            title: "Delete all notes",
            content: "Are you sure you want to delete all notes?",
            iconColor: Colors.redAccent,
            iconData: Mdi.delete_empty_outline,
            iconSize: 25,
            option: TextButton(
              onPressed: () {
                Navigator.pop(context);
                chatNotifier.clearChats();
              },
              child: const Text("Delete",
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.brightnessOf(context) == Brightness.light;
    final headerColor = isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
    final parentRadius = BorderRadius.only(topLeft: Radius.circular(10));
    final dividerColor = isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkIconBorder;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: ParentSlideWrapper(
        overlay: RepaintBoundary(
          child: ProfileScreen(
            leading: IconButton(
              onPressed: () {
                setState(() => _isSliding = false);
                WindowsUtils.clearTitleBarColorDirect();
              },
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: ThemeConstants.iconColorNeutral),
            ),
          ),
        ),
        trigger: _isSliding,
        child: Scaffold(
          backgroundColor: headerColor,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (context.screenWidth >= 900)
              DesktopIconRail(
                headerColor: headerColor,
                profileWidget: _buildAvatar(isLight),
                selectedTab: _selectedTab, // add this to your state
                onTabSelected: (tab) => setState(() => _selectedTab = tab),
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: parentRadius,
                    border: Border.all(color: dividerColor),
                          gradient: isLight ? Gradients.lightBackground : Gradients.darkChatBackground,

                  ),
                  child: Row(
                    children: [
                      _buildLeftPanel(isLight),
                      Expanded(child: _buildRightPanel(isLight)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  // PANEL BUILDERS

  Widget _iconRail(Color headerColor) {
    return ValueListenableBuilder(
      valueListenable: windowsTitleBarColor,
      builder: (context, value, child) {
        return Container(
          color: headerColor,
          height: double.maxFinite,
          width: WindowsUtils.titlebarHeight,
          child: Column(
            children: [
              
            ],
          ),
        );
      }
    );
  }

  Widget _buildLeftPanel(bool isLight) {
    final chatNotifier = ref.read(chatListProvider.notifier);
    final chatlist = ref.watch(chatListProvider.select((state) => state.chats));
    final isLoading = ref.watch(chatListProvider.select((state) => state.isLoading));
    final headerColor = isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
    final dividerColor = isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkIconBorder;
    final backgroundGradient = isLight ? Gradients.lightBackground : Gradients.darkBackground;
    final double leftPanelWidth = 340;

    return Container(
      width: leftPanelWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        color: headerColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
        border: Border(
          right: BorderSide(color: dividerColor, width: 1),
          // top: BorderSide(color: dividerColor, width: 1)
          ),
      ),
      child: Column(
        children: [
          // SEARCH + FILTER
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 8, right: 0, top: 12),
            child: Row(
              spacing: Platform.isWindows ? 0 : 0,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 40),
                    child: SearchBar(
                      focusNode: _searchFocusNode,
                      controller: _searchController,
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
                        _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear_rounded),
                            onPressed: _clearSearch,
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
                      final currentFilter = ref.read(settingsController)?.chatListFilter ?? ChatlistFilter.oldestCreated;
                      CustomContextMenu.showMenuAt(
                        context,
                        position: Offset(
                          leftPanelWidth,
                          kToolbarHeight,
                        ),
                        showTail: false,
                        menuItems: chatFilterOptions(currentFilter),
                        onSelected: (value) {
                          final selectedFilter = ChatlistFilter.values
                                .firstWhere((f) => f.name == value);
                          ref.read(settingsController.notifier).setChatListFilter(selectedFilter);
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

          // RECENT LABEL
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 10, bottom: 4, right: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "RECENT",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: ThemeConstants.subtitleLight,
                ),
              ),
            ),
          ),

          // CHAT LIST
          Expanded(
            child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : chatlist.isEmpty
                ? const NothingToSee()
                : ListView.separated(
                    itemCount: chatlist.length,
                    itemBuilder: (context, index) {
                      final chat = chatlist[index];
                      final searchResults = ref.watch(chatListProvider.select((state) => state.searchResults));
                      final matchingMessages = searchResults[chat] ?? [];
                        
                      return TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: chatNotifier.isDeleting[chat.isarID] == true ? 1.0 : 0.0,
                          end: chatNotifier.isDeleting[chat.isarID] == true ? 0.0 : 1.0,
                        ),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) => Opacity(opacity: value, child: child),
                        child: matchingMessages.isEmpty
                          ? DesktopChatTile(
                              key: ValueKey(chat.isarID),   // ← widget identity key, unique per item
                              chatTileKey: _getChatKey(chat), // ← the GlobalKey for position lookup
                              chat: chat,
                              isSelected: ref.watch(chatListProvider.select((s) => s.selectedChat?.isarID == chat.isarID)),
                              onTap: () => _selectChat(chat),
                              onDismissed: (_) => ref.read(deleteChatUseCaseProvider).queueDelete(chat),
                              onRightClick: (position) {
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
                          : _buildSearchResultTile(chat, matchingMessages),
                      );
                    },
                    separatorBuilder: (context, index) => Divider(
                      thickness: 0.5,
                      indent: 24,
                      height: 1,
                      color: dividerColor,
                    ),
                  ),
          ),

          // NEW NOTE BUTTON
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _createNewChat,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  "New Note",
                  style: TextStyle(
                      fontFamily: "Poppins", fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(Chat chat, List<Message> matchingMessages) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final dividerColor = isLight
        ? ThemeConstants.homeDividerLight
        : ThemeConstants.darkIconBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypeSet(
                "_${matchingMessages.length} matches found",
                style: TextStyle(
                    fontSize: 11, color: ThemeConstants.subtitleLight),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      chat.chatPhotoPath == null
                          ? const DocumentIcon(
                              size: 20,
                              iconPadding: EdgeInsets.all(2),
                              borderWidth: 1.5)
                          : Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 20,
                              width: 20,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle),
                              child: Image.file(
                                  File(chat.chatPhotoPath!),
                                  fit: BoxFit.cover),
                            ),
                      Text(
                        chat.title ?? "New Note",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    TimeFormat.formatChatTime(chat.date),
                    style: TextStyle(
                        fontSize: 11,
                        color: ThemeConstants.subtitleLight),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: matchingMessages
                .map((message) => _buildMessagePreview(
                    message, _searchController.text, chat))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagePreview(Message message, String query, Chat chat) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final dividerColor = isLight
        ? ThemeConstants.homeDividerLight
        : ThemeConstants.darkIconBorder;

    return Column(
      children: [
        Divider(
            thickness: 0.5,
            height: 2,
            color: dividerColor.withOpacity(0.5),
            indent: 10,
            endIndent: 10),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              await _selectChat(chat);
              ref
                  .read(chatListProvider.notifier)
                  .navigateAndHighlight(context, message, chat);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHighlightedText(message.text, query, isLight),
                        const SizedBox(height: 4),
                        Text(
                          TimeFormat.formatChatTime(message.time),
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                ThemeConstants.subtitleLight.withOpacity(0.6),
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
        style:
            TextStyle(fontSize: 12, color: ThemeConstants.subtitleLight),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      final queryIndex =
          lowercaseText.indexOf(lowercaseQuery, currentIndex);
      if (queryIndex == -1) {
        spans.add(TextSpan(text: text.substring(currentIndex)));
        break;
      }
      if (queryIndex > currentIndex) {
        spans.add(
            TextSpan(text: text.substring(currentIndex, queryIndex)));
      }
      spans.add(TextSpan(
        text: text.substring(queryIndex, queryIndex + query.length),
        style: TextStyle(
          backgroundColor:
              isLight ? Colors.yellow[300] : Colors.amber[700],
          color: isLight ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ));
      currentIndex = queryIndex + query.length;
    }

    return Expanded(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
              overflow: TextOverflow.fade,
              fontFamily: 'Poppins',
              fontSize: 12,
              color: ThemeConstants.subtitleLight),
          children: spans,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRightPanel(bool isLight) {
    final selectedChat = ref.watch( chatListProvider.select((s) => s.selectedChat));
    final backgroundGradient = context.isLight ? Gradients.lightBackground : Gradients.darkChatBackground;

    return AnimatedRightPanel(
      selectedChat: selectedChat,
      chatList: ref.watch(chatListProvider.select((s) => s.chats)),
      backgroundGradient: backgroundGradient,
      chatScreen: const ChatScreen(),
    );
  }

  Widget _buildAvatar(bool isLight) {
    final String? path = ref.watch(userController)?.profilePhotoPath;
    return CustomIconButton(
      size: 36,
      backgroundColor: Colors.transparent,
      splashColor: const Color.fromARGB(144, 164, 182, 191),
      icon: ClipOval(
        child: SizedBox(
          width: 36,
          height: 36,
          child: path != null
              ? Image.file(File(path), fit: BoxFit.cover)
              : Image.asset(
                  isLight ? IconPaths.avatarLight : IconPaths.avatarDark,
                  fit: BoxFit.cover),
        ),
      ),
      onPressed: () {
        setState(() => _isSliding = true);
        WindowsUtils.setTitleBarColorDirect(
            isLight ? Gradients.silverSunlight2 : Gradients.shadowBlue);
      },
    );
  }
}

// ─── Desktop Chat Tile ────────────────────────────────────────────────────────
// Wraps the existing ChatTile with a selected-state highlight and
// right-click → context menu support (Windows requirement).

class DesktopChatTile extends ConsumerWidget {
  final Chat chat;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(Offset position) onRightClick;
  final void Function(DismissDirection) onDismissed;
  final GlobalKey chatTileKey;

  const DesktopChatTile({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.onTap,
    required this.onRightClick,
    required this.onDismissed,
    required this.chatTileKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final selectedColor = isLight
        ? ThemeConstants.hometoolbarLight3
        : ThemeConstants.messageBarDark;

    return GestureDetector(
      // Right-click on Windows triggers the same long-press context menu
      // onSecondaryTapUp: (details) => onRightClick(details.localPosition),
      child: AnimatedContainer(
        margin: EdgeInsets.all(8),
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          // borderRadius: BorderRadius.all(Radius.circular(5)),
          color: isSelected ? selectedColor.withOpacity(0.6) : Colors.transparent,
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: const Color(0xFF00BCD4),
                    width: 3,
                    style: BorderStyle.solid
                  ),
                )
              : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
        ),
        child: ChatTile(
          key: chatTileKey,  
          isPinned: chat.isPinned,
          title: chat.title ?? "New Note",
          subtitle: chat.loadLastMessageTextFormatted(),
          chatPhotoPath: chat.chatPhotoPath,
          time: TimeFormat.formatChatTime(chat.date),
          onDismissed: onDismissed,
          onTap: onTap,
          // onLongPress: () {
          //   final position = Utils.getObjectPosition(objectKey: chatTileKey); // ← not `key`
          //   onRightClick(position);
          // },
          onSecondaryTapUp: (details) => onRightClick(details.globalPosition.translate(-43, -12)),
        ),
      ),
    );
  }
}