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
import 'package:notesapp/core/extensions/message_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/core/utils/windows_utils.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/root/data/enums/chatlist_filter.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/chat_screen.dart';
import 'package:notesapp/root/presentation/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/presentation/screens/Homescreen/components/chat_list/chat_tile.dart';
import 'package:notesapp/root/presentation/screens/Homescreen/components/chat_list/doc_icon.dart';
import 'package:notesapp/root/presentation/screens/Profile/profile_screen.dart';
import 'package:notesapp/root/presentation/screens/Profile/wrappers/parent_slide_wrapper.dart';
import 'package:notesapp/root/presentation/screens/Settings/settings_screen.dart';
import 'package:notesapp/root/presentation/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/presentation/widgets/custom_icon_button.dart';
import 'package:notesapp/root/presentation/widgets/custom_icon_dialogue.dart';
import 'package:notesapp/root/presentation/widgets/nothing_to_see.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:notesapp/root/data/models/media_model.dart';
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

  ChatlistFilter _filter = ChatlistFilter.oldestCreated;
  bool _isSliding = false;
  Chat? _selectedChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userController.notifier).loadUser();
      ref.read(chatListProvider.notifier).applyFilter(_filter);
    });
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
    setState(() => _selectedChat = chat);
    await chat.messages.load();
    await Future.wait(chat.messages.map((m) => m.media.load()));
  }

  Future<void> _createNewChat() async {
    final newChat = await ref.read(chatListProvider.notifier).addChat();
    await newChat.messages.load();
    ref.read(chatListProvider.notifier).selectChat(newChat);
    ref.read(isNewChat.notifier).state = true;
    setState(() => _selectedChat = newChat);
  }

  Future<void> _deleteChatWithFade(Chat chat) async {
    final chatNotifier = ref.read(chatListProvider.notifier);
    chatNotifier.clearSearch();
    setState(() => chatNotifier.isDeleting[chat.isarID] = true);
    chatNotifier.applyFilter(_filter);
    await Future.delayed(const Duration(milliseconds: 300));
    await chatNotifier.deleteChatWithUndo(chat);
    chatNotifier.isDeleting.remove(chat.isarID);
    if (_selectedChat?.isarID == chat.isarID) {
      setState(() => _selectedChat = null);
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

  // PANEL BUILDERS

  Widget _buildLeftPanel(bool isLight) {
    final chatNotifier = ref.read(chatListProvider.notifier);
    final chatlist =
        ref.watch(chatListProvider.select((state) => state.chats));
    final isLoading =
        ref.watch(chatListProvider.select((state) => state.isLoading));
    final headerColor =
        isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
    final dividerColor = isLight
        ? ThemeConstants.homeDividerLight
        : ThemeConstants.darkIconBorder;
    final backgroundGradient =
        isLight ? Gradients.lightBackground : Gradients.darkBackground;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        border: Border(
          right: BorderSide(
            color: dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // SEARCH + FILTER
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 8, right: 0, top: 12),
            child: Row(
              spacing: Platform.isWindows ? 5 : 0,
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
                          final searchResults = ref.watch(chatListProvider
                              .select((state) => state.searchResults));
                          final matchingMessages =
                              searchResults[chat] ?? [];

                          return TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: chatNotifier.isDeleting[chat.isarID] ==
                                      true
                                  ? 1.0
                                  : 0.0,
                              end: chatNotifier.isDeleting[chat.isarID] == true
                                  ? 0.0
                                  : 1.0,
                            ),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, child) =>
                                Opacity(opacity: value, child: child),
                            child: matchingMessages.isEmpty
                                ? _DesktopChatTile(
                                    key: ValueKey(chat.isarID),   // ← widget identity key, unique per item
                                    chatTileKey: _getChatKey(chat), // ← the GlobalKey for position lookup
                                    chat: chat,
                                    isSelected: _selectedChat?.isarID == chat.isarID,
                                    onTap: () => _selectChat(chat),
                                    onRightClick: (position) {
                                      CustomContextMenu.showMenuAt(
                                        context,
                                        position: position,
                                        menuItems: chatTileOptions(chat),
                                        onSelected: (value) {
                                          if (value == "delete") {
                                            _deleteChatWithFade(chat);
                                          }
                                          chatNotifier
                                              .handleChatHoldOptions(value, chat);
                                        },
                                      );
                                    },
                                    onDismissed: (_) =>
                                        chatNotifier.deleteChatWithUndo(chat),
                                  )
                                : _buildSearchResultTile(
                                    chat, matchingMessages),
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
    final headerColor =
        isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;
    final backgroundGradient =
        isLight ? Gradients.lightBackground : Gradients.darkBackground;

    if (_selectedChat == null) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note_rounded,
                    size: 64,
                    color: ThemeConstants.subtitleLight.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  "Select a note to view",
                  style: TextStyle(
                    fontSize: 16,
                    color: ThemeConstants.subtitleLight.withOpacity(0.5),
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Chat is selected — show ChatScreen inline
    return const Expanded(child: ChatScreen());
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

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.brightnessOf(context) == Brightness.light;
    final headerColor =
        isLight ? ThemeConstants.hometoolbarLight2 : ThemeConstants.darkAppbar;

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
          appBar: AppBar(
            elevation: 0,
            backgroundColor: headerColor,
            shadowColor: Colors.transparent,
            toolbarHeight: 52,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  _buildAvatar(isLight),
                  const SizedBox(width: 10),
                  const Text(
                    "NotesApp",
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            actions: [
              CustomContextMenu(
                icon: const Icon(Icons.more_vert),
                menuItems: homeScreenOptions,
                onSelected: _handleContextMenuAction,
              ),
              const SizedBox(width: 4),
            ],
            systemOverlayStyle: SystemUiOverlayStyle(
              systemNavigationBarColor: isLight
                  ? ThemeConstants.hometoolbarLight3
                  : ThemeConstants.messageBarDark,
            ),
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLeftPanel(isLight),
              _buildRightPanel(isLight),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Desktop Chat Tile ────────────────────────────────────────────────────────
// Wraps the existing ChatTile with a selected-state highlight and
// right-click → context menu support (Windows requirement).

class _DesktopChatTile extends ConsumerWidget {
  final Chat chat;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(Offset position) onRightClick;
  final void Function(DismissDirection) onDismissed;
  final GlobalKey chatTileKey;

  const _DesktopChatTile({
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
      onSecondaryTapUp: (details) => onRightClick(details.globalPosition),
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
          onLongPress: () {
            final position = Utils.getObjectPosition(objectKey: chatTileKey); // ← not `key`
            onRightClick(position);
          },
          onSecondaryTapUp: (details) => onRightClick(details.globalPosition),
        ),
      ),
    );
  }
}