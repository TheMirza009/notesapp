import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/icon_paths.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_notifier.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';
import 'package:svg_flutter/svg.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final Chat chat;
  const ChatDetailScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  late ChatDetailNotifier notifier;
  late TextEditingController titleController;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    notifier = ChatDetailNotifier(widget.chat);
    titleController =
        TextEditingController(text: widget.chat.title ?? "New Chat");
  }

  @override
  void dispose() {
    titleController.dispose();
    notifier.dispose(); // ✅ clean up
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

  void _finishEditing() {
    final newText = titleController.text.trim();
    notifier.updateTitle(newText, ref);
    setState(() => isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final chat = notifier.state;

    Size screenSize = MediaQuery.sizeOf(context);
    return DefaultTabController(
  length: 2,
  child: Scaffold(
    appBar: AppBar(
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
          onPressed: isEditing ? _finishEditing : _startEditing,
        ),
      ],
    ),
    body: NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Container(
            height: screenSize.height / 3,
            margin: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color.fromARGB(67, 164, 182, 191),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: DocumentIcon(
                size: screenSize.height / 3,
                borderWidth: 12,
                iconPadding: EdgeInsets.all(26),
              ),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            const TabBar(
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: ThemeConstants.homeSearchbarLight,
              dividerHeight: 1,
              tabs: [
                Tab(text: "Photos"),
                Tab(text: "Documents"),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                spacing: 5,
                children: [
                  SvgPicture.string(IconPaths.catSitting),
                  Text("No Photos in chat yet"),
                ],
              ),
              SizedBox(height: 800), // filler to test scrolling
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                spacing: 5,
                children: [
                  SvgPicture.string(IconPaths.catSitting),
                  Text("No Documents in chat yet"),
                ],
              ),
              SizedBox(height: 800),
            ],
          ),
        ],
      ),
    ),
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
