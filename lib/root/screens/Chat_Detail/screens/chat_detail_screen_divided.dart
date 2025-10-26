// chat_detail_screen_divided.dart
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/string_extensions.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_base_state.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_notifier.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_screen.dart';
import 'package:notesapp/root/screens/Chat_Detail/screens/chat_media_screen.dart';
import 'package:notesapp/root/screens/Chat_Detail/widgets/info_bottom_sheet.dart';
import 'package:notesapp/root/screens/Chat_screen/notifier/chat_state_notifier.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';
import 'package:notesapp/root/screens/Profile/wrappers/hero_wrapper.dart';
import 'package:notesapp/root/screens/Test/thread_test_screen.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:notesapp/root/widgets/crop/crop_screen.dart';
import 'package:photo_view/photo_view.dart';


class ChatDetailScreenDivided extends ConsumerStatefulWidget {
  final Chat chat;
  final bool? scrollToMedia;
  const ChatDetailScreenDivided({
    super.key,
    required this.chat,
    this.scrollToMedia = false,
  });

  @override
  ConsumerState<ChatDetailScreenDivided> createState() => _ChatDetailScreenDividedState();
}

class _ChatDetailScreenDividedState extends ConsumerState<ChatDetailScreenDivided> {
    late final TextEditingController titleController;
  final ScrollController scrollController = ScrollController();
  bool isEditing = false;
  static const TextStyle subStyle = TextStyle(color: ThemeConstants.iconColorNeutral, fontSize: 13);
  Offset position = Offset(0, 0);
  final bubbleTileKey1 = GlobalKey();
  final bubbleTileKey2 = GlobalKey();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.chat.title ?? "New Chat");

    if (widget.scrollToMedia == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollHeaderToTop();
      });
    }
  }
  void scrollHeaderToTop() {
    // Animate until the header is pinned (guard for scrollable extents)
    final maxExtent = scrollController.hasClients ? scrollController.position.maxScrollExtent : 0.0;
    scrollController.animateTo(
      maxExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuad,
    );
  }

  void startEditing() {
    setState(() => isEditing = true);
    // move caret to end
    Future.delayed(Duration.zero, () {
      titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: titleController.text.length),
      );
    });
  }

  void finishEditing(ChatDetailNotifier notifier) {
    final newText = titleController.text.trim();
    notifier.updateTitle(newText);
    setState(() => isEditing = false);
  }

  /// Build profile image for hero wrapper. `path` can be null.
  Widget buildProfileImage(BuildContext context, String? path, {bool expanded = false}) {
  final isLight = context.isLight;

  if (expanded) {
    final double availableHeight = context.screenHeight - 200;

    // ✅ If no photo is selected, show the DocumentIcon in PhotoView
    if (path == null || path.isEmpty) {
      return SizedBox(
        height: availableHeight,
        width: context.screenWidth,
        child: Center(
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: DocumentIcon(
              size: availableHeight / 2,
              borderWidth: 6,
              iconPadding: const EdgeInsets.all(24),
            ),
          ),
        ),
      );
    }

    // ✅ Otherwise, show the selected image
    final ImageProvider provider = FileImage(File(path));

    return SizedBox(
      height: availableHeight,
      width: context.screenWidth,
      child: PhotoView(
        gestureDetectorBehavior: HitTestBehavior.opaque,
        imageProvider: provider,
        minScale: PhotoViewComputedScale.contained,
        initialScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        tightMode: true,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }

  // Compact version (non-expanded)
  final double size = context.screenHeight / 4;

  final Widget image = (path != null && path.isNotEmpty)
      ? ExtendedImage.file(
          File(path),
          key: ValueKey<String>(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheRawData: true,
        )
      : DocumentIcon(
          size: context.screenHeight / 3,
          borderWidth: 12,
          iconPadding: const EdgeInsets.all(26),
        );

  return Container(
    height: size,
    width: size,
    decoration: const BoxDecoration(shape: BoxShape.circle),
    clipBehavior: Clip.antiAlias,
    child: image,
  );
}


  @override
  void dispose() {
    titleController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatDetailProvider);
    final notifier = ref.read(chatDetailProvider.notifier);

    final Chat? chat = state.chat;
    final photoMessages = state.photos;
    final docMessages = state.documents;
    final isLight = context.isLight;
    const Color darkPrimary = Color(0xFF81D3DF);
    final Color shareColor = chat?.chatPhotoPath == null ? ThemeConstants.iconColorNeutral : darkPrimary;
    final String colorName = ref.watch(chatStateController.select((s) => s.bubbleColor))!.name;

    if (chat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Chat not found')),
      );
    }

    return Scaffold(
      floatingActionButton: IconButton(
        icon: Icon(Icons.info_outline_rounded),
        onPressed:
            () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => ThreadTestScreen()),
            ),
      ), // showChatInfoSheet(context, chat)),
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: isEditing
            ? TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(border: InputBorder.none),
                style: const TextStyle(fontSize: 21.5, fontWeight: FontWeight.w300),
              )
            : Text(chat.title ?? "New Chat"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: isEditing ? () => finishEditing(notifier) : startEditing,
          ),
        ],
      ),
      body: ListView(
        children: [
          // Profile Image Section
          SizedBox(
            height: context.screenHeight / 3,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: HeroWrapper(
                tag: "chat-avatar-${chat.uuid ?? 'unknown'}",
                defaultChild: buildProfileImage(context, chat.chatPhotoPath, expanded: false),
                expandedChild: buildProfileImage(context, chat.chatPhotoPath, expanded: true),
                topWidget: Align(
                  alignment: Alignment.topLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                    label: const Text("Back"),
                  ),
                ),
                bottomWidget: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: vectorBuild(IconPaths.uploadImage, color: darkPrimary),
                        onPressed: () async {
                          await notifier.updateChatPhoto();
                          Navigator.pop(context);
                        },
                        label: const Text(
                          "Upload",
                          style: TextStyle(color: darkPrimary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        icon: vectorBuild(IconPaths.shareIcon, color: shareColor),
                        onPressed: () async {
                          if (chat.chatPhotoPath == null) return;
                          await Utils.shareToApps(XFile(chat.chatPhotoPath!));
                          Navigator.pop(context);
                        },
                        label: Text(
                          "Share",
                          style: TextStyle(color: shareColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Media Section ListTile
          _buildButtonTile(
            icon: vectorBuild(IconPaths.imageStack, scale: 0.63, color: ThemeConstants.sacredSeed),
            title: "Chat Media",
            subtitle: "${photoMessages.length} photos • ${docMessages.length} documents",
            destination: ChatMediaScreen(chat: chat),
          ),
          _buildButtonTile(
            key: bubbleTileKey1,
            icon: vectorBuild(IconPaths.chatBubble1, scale: 0.63, color: ThemeConstants.sacredSeed),
            title: "Bubble Color",
            subtitle: "${colorName.toSentenceCase()} Color",
            destination: ChatMediaScreen(chat: chat),
            onTap: () {
              // Compute global position of the tile
              final RenderBox box = bubbleTileKey1.currentContext!.findRenderObject() as RenderBox;
              final Offset globalPosition = box.localToGlobal(Offset.zero);
              final Size size = box.size;
          
              // We want centerRight → x = right edge, y = vertical center
              final Offset position = Offset(
                globalPosition.dx + size.width,
                globalPosition.dy + size.height / 1.1,
              );
              CustomContextMenu.showMenuAt(
                  context,
                  position: position, // Offset(300, 630),
                  menuItems: bubbleColor,
                  onSelected: (value) => handleBubbleColor(context, ref, value),
                  triangleHorizontalOffset: 120
                );
            },
          ),
          _buildButtonTile(
            key: bubbleTileKey2,
            icon: vectorBuild(IconPaths.phone2, scale: 0.63, color: ThemeConstants.sacredSeed),
            title: "Chat Background",
            subtitle: "Choose your own image",
            destination: CropScreen(isChatBackground: true),
            onTap: () {
              // Compute global position of the tile
              final RenderBox box = bubbleTileKey2.currentContext!.findRenderObject() as RenderBox;
              final Offset globalPosition = box.localToGlobal(Offset.zero);
              final Size size = box.size;

              // We want centerRight → x = right edge, y = vertical center
              final Offset position = Offset(
                globalPosition.dx + size.width,
                globalPosition.dy + size.height / 1.1,
              );

              CustomContextMenu.showMenuAt(
                  context,
                  position: position, // Offset(300, 550),
                  menuItems: chatBackgroundOptions,
                  onSelected: (value) => handleChatBackgroundAction(context, ref, value),
                  triangleHorizontalOffset: 120
                );
            },
          ),
          // const SizedBox(height: 100),
          const SizedBox(height: 100),
          // Container(
          //   height: 129,
          //   clipBehavior: Clip.none,
          //   decoration: BoxDecoration(border: Border.all(color: context.isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkIconBorder), borderRadius: BorderRadius.circular(25)),
          //   padding: EdgeInsets.only(top: 12),
          //   child: Column(
          //     children: [
          //       // Divider(color: context.isLight ? ThemeConstants.homeDividerLight : ThemeConstants.darkAppbar,),
          //       const SizedBox(height: 10),
          //       // Additional chat details can go here
          //       _buildChatInfoSection(chat),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildButtonTile({
    Key? key,
    required Widget destination,
    required String title,
    required String subtitle,
    Widget? icon,
    bool? isDisabled = false,
    bool? useMaterial = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      key: key,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Opacity(
                opacity: (isDisabled ?? false) ? 0.3 : 1.0,
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ThemeConstants.sacredSeed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: icon ?? Icon(
                        Icons.photo_library,
                        color: ThemeConstants.sacredSeed,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeConstants.subtitleLight,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: (isDisabled ?? false) ? () {} : onTap ?? () {
                      useMaterial == true ?
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => destination,
                        ),
                      ) :
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => destination,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildChatInfoSection(Chat chat) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chat Info",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.isLight ? ThemeConstants.textLight : ThemeConstants.textDark,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow("Created", TimeFormat.formatChatTime(chat.date)),
          const SizedBox(height: 5),
          _buildInfoRow("Notes", "${chat.messages.length} notes"),
          // Add more chat info as needed
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: ThemeConstants.subtitleLight,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}