// chat_detail_screen.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:notesapp/core/utils/context_menu_options.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_base_state.dart';
import 'package:notesapp/root/screens/Chat_Forward/chat_forward_screen.dart';
import 'package:notesapp/root/screens/Chat_Forward/notifier/selected_chat_notifier.dart';
import 'package:notesapp/root/widgets/context_menus/custom_context_menu.dart';
import 'package:photo_view/photo_view.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/extensions/media_extensions.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/core/utils/utils.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_notifier.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_list/doc_icon.dart';
import 'package:notesapp/root/screens/Profile/wrappers/hero_wrapper.dart';
import 'package:notesapp/root/widgets/photo_view/gallery_view_wrapper.dart';
import 'package:notesapp/root/widgets/photo_view/photo_view_wrapper.dart';
import 'package:open_file/open_file.dart';
import 'package:svg_flutter/svg.dart';

/// Provider for ChatDetailNotifier
final chatDetailProvider =
    NotifierProvider<ChatDetailNotifier, ChatDetailState>(
  () => ChatDetailNotifier(),
);

class ChatDetailScreen extends ConsumerStatefulWidget {
  final Chat chat;
  final bool? scrollToMedia;
  const ChatDetailScreen({super.key, required this.chat, this.scrollToMedia = false});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

/// ---------------------------------------------------------------------------
/// Private state class: extends ChatDetailBase so all stateful logic can be
/// moved into ChatDetailBase (which can be moved into a separate file).
/// ---------------------------------------------------------------------------
class _ChatDetailScreenState extends ChatDetailBase {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatDetailProvider);
    final notifier = ref.read(chatDetailProvider.notifier);

    final Chat? chat = state.chat;
    final photoMessages = state.photos;
    final docMessages = state.documents;
    final isLight = context.isLight;
    final screenSize = MediaQuery.sizeOf(context);
    const Color darkPrimary = Color(0xFF81D3DF);
    final Color shareColor = chat?.chatPhotoPath == null ? ThemeConstants.iconColorNeutral : darkPrimary;

    // Defensive: if chat is null (shouldn't happen if navigation guarded), provide a small fallback:
    if (chat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Chat not found')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new_rounded)),
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
        body: NestedScrollView(
          controller: scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: HeroWrapper(
                  tag: "chat-avatar-${chat.uuid ?? 'unknown'}",
                  // pass `String?` — buildProfileImage handles null path.
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
                      // If you have a custom Row with spacing extension, great; otherwise use SizedBox for spacing
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: vectorBuild(IconPaths.uploadImage, color: darkPrimary),
                          onPressed: () async {
                            // ONLY the Upload button triggers the update
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
                // NOTE: InkWell alternative was intentionally removed so updateChatPhoto
                // is not implicitly called by tapping the hero. The HeroWrapper handles
                // expanding the image; the Upload button performs the upload.
              ),
            ),
          SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor:
                          isLight
                              ? ThemeConstants.homeSearchbarLight
                              : ThemeConstants.darkAppbar,
                      dividerHeight: 1,
                      tabs: const [Tab(text: "Photos"), Tab(text: "Documents")],
                    ),
                  ),
                ),
              ],
            body: TabBarView(
            children: [
              // Photos tab
              photoMessages.isEmpty
                  ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          IconPaths.catSitting,
                          color: ThemeConstants.iconLight,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text("No Photos in chat yet"),
                      ],
                    ),
                  )
                  : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                    itemCount: photoMessages.length,
                    itemBuilder: (context, index) {
                      final media = photoMessages[index];
                      final path = media.path;
                      return Container(
                        margin: const EdgeInsets.all(0.75),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: InkWell(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => GalleryViewWrapper(
                                        chatTitle: chat.title ?? '',
                                        galleryItems: photoMessages,
                                        initialIndex: index,
                                        showOptions: true,
                                        options: galleryOptions,
                                        onOptionSelect:
                                            (value) => handleGalleryOptions(
                                              context,
                                              ref,
                                              value,
                                              photoMessages[index],
                                            ),
                                      ),
                                ),
                              ),
                          child: FadeInDynamic.filePath(path, index: index),
                        ),
                      );
                    },
                  ),

              // Documents tab
              docMessages.isEmpty
                  ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          IconPaths.catSitting,
                          color: ThemeConstants.iconLight,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text("No Documents in chat yet"),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: docMessages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == docMessages.length) {
                        return const SizedBox(height: 100);
                      }

                      final doc = docMessages[index];
                      return FadeInDynamic.widget(
                        ListTile(
                          onTap: () async {
                            if (doc.path != null && doc.path!.isNotEmpty) {
                              await OpenFile.open(doc.path);
                            }
                          },
                          leading: const Icon(
                            Icons.insert_drive_file,
                            color: Colors.red,
                          ),
                          title: Text(
                            doc.name ?? "Unknown file",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (doc.path != null && doc.path!.isNotEmpty)
                                    FutureBuilder<String>(
                                      future: Utils.getFileSize(doc.path!),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Text(
                                            'Loading size...',
                                            style: ChatDetailBase.subStyle,
                                          );
                                        } else if (snapshot.hasError) {
                                          return const Text(
                                            'Size unknown',
                                            style: ChatDetailBase.subStyle,
                                          );
                                        } else {
                                          return Text(
                                            snapshot.data ?? '',
                                            style: ChatDetailBase.subStyle,
                                          );
                                        }
                                      },
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    doc.extension?.toUpperCase() ?? "",
                                    style: ChatDetailBase.subStyle,
                                  ),
                                ],
                              ),
                              Text(
                                doc.timeString ?? '',
                                style: ChatDetailBase.subStyle,
                              ),
                            ],
                          ),
                        ),
                        index: index,
                        isImage: false,
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to fade in an image or arbitrary widget with optional staggered delay.
/// I provide factory constructors for clarity and to avoid passing incompatible
/// `child` types at runtime.
class FadeInDynamic extends StatefulWidget {
  final Widget child;
  final int index;
  final bool isImage;

  const FadeInDynamic._({
    required this.child,
    required this.index,
    required this.isImage,
    super.key,
  });

  /// Convenience factory when you have a file path for an image.
  factory FadeInDynamic.filePath(String? filePath, {required int index}) {
    final Widget childWidget;
    if (filePath != null && filePath.isNotEmpty) {
      childWidget = Image.file(File(filePath), fit: BoxFit.cover);
    } else {
      childWidget = const SizedBox.shrink();
    }
    return FadeInDynamic._(child: childWidget, index: index, isImage: true);
  }

  /// Convenience factory when you want to fade any widget (e.g. ListTile).
  factory FadeInDynamic.widget(Widget widget, {required int index, bool isImage = false}) {
    return FadeInDynamic._(child: widget, index: index, isImage: isImage);
  }

  @override
  State<FadeInDynamic> createState() => _FadeInDynamicState();
}

class _FadeInDynamicState extends State<FadeInDynamic> with SingleTickerProviderStateMixin {
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Staggered fade-in based on index; guard index >= 0
    final safeIndex = (widget.index >= 0) ? widget.index : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: (safeIndex * 80).clamp(0, 800)), () {
        if (mounted) {
          setState(() => opacity = 1.0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: widget.child,
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _TabBarDelegate(this._tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
