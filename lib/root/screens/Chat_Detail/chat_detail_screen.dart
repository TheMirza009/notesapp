import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_notifier.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';
import 'package:svg_flutter/svg.dart';

/// Provider for ChatDetailNotifier
final chatDetailProvider =
    NotifierProvider<ChatDetailNotifier, ChatDetailState>(
  () => ChatDetailNotifier(),
);

class ChatDetailScreen extends ConsumerStatefulWidget {
  final Chat chat;
  const ChatDetailScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  late TextEditingController titleController;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.chat.title ?? "New Chat");
    // Future.microtask(() {
    //   ref.read(chatDetailProvider.notifier).getPhotos();
    // });

    // Initialize provider with chat once
    // Future.microtask(() {
    //   ref.read(chatDetailProvider.notifier).init(widget.chat);
    // });
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => isEditing = true);
    Future.delayed(Duration.zero, () {
      titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: titleController.text.length),
      );
    });
  }

  void _finishEditing(ChatDetailNotifier notifier) {
    final newText = titleController.text.trim();
    notifier.updateTitle(newText);
    setState(() => isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatDetailProvider);
    final notifier = ref.read(chatDetailProvider.notifier);

    final chat = state.chat;
    final photoMessages = state.photos;
    final isLight = context.isLight;
    final screenSize = MediaQuery.sizeOf(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
          title: isEditing
              ? TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(border: InputBorder.none),
                  style: const TextStyle(fontSize: 21.5, fontWeight: FontWeight.w300),
                )
              : Text(chat?.title ?? "New Chat"),
          actions: [
            IconButton(
              icon: Icon(isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
              onPressed: () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
            ),
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit),
              onPressed: isEditing ? () => _finishEditing(notifier) : _startEditing,
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  splashColor: const Color.fromARGB(87, 220, 247, 255),
                  onTap: () async {
                    // final Media? file = await MediaHandler.pickImage();
                    // if (file != null) print(file.name);
                    await notifier.updateChatPhoto();
                  },
                  customBorder: const CircleBorder(),
                  child: Center(
                    child:
                      chat!.chatPhotoPath != null
                        ? Image.file(
                          File(chat.chatPhotoPath!),
                          height: screenSize.height / 3,
                          fit: BoxFit.cover,
                        )
                        : DocumentIcon(
                          size: screenSize.height / 3,
                          borderWidth: 12,
                          iconPadding: const EdgeInsets.all(26),
                        ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: isLight
                      ? ThemeConstants.homeSearchbarLight
                      : ThemeConstants.darkAppbar,
                  dividerHeight: 1,
                  tabs: const [
                    Tab(text: "Photos"),
                    Tab(text: "Documents"),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              photoMessages.isEmpty
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        SvgPicture.string(
                          IconPaths.catSitting,
                          color: ThemeConstants.iconLight,
                          height: 20,
                        ),
                        const Text("No Photos in chat yet"),
                      ],
                    )
                  : GridView.count(
                      crossAxisCount: 3,
                      children: List.generate(
                        photoMessages.length,
                        (index) => Container(
                          margin: EdgeInsets.all(0.75),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5)
                          ),
                          child: _FadeInImage(
                            File(photoMessages[index].path!), 
                            index,
                            ),
                        ),
                      ),
                    ),
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      SvgPicture.string(
                        IconPaths.catSitting,
                        color: ThemeConstants.iconLight,
                        height: 20,
                      ),
                      const Text("No Documents in chat yet"),
                    ],
                  ),
                  const SizedBox(height: 800),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget to fade in a single image
class _FadeInImage extends StatefulWidget {
  final File file;
  final int? index;
  const _FadeInImage(this.file, this.index);

  @override
  State<_FadeInImage> createState() => _FadeInImageState();
}

class _FadeInImageState extends State<_FadeInImage> {
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger fade-in after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: ((widget.index ?? 1) * 100)), 
      () => setState(() => opacity = 1.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: opacity,
      child: Image.file(
        widget.file,
        fit: BoxFit.cover,
      ),
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
