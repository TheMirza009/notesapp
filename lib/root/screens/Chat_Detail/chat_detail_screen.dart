import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/screens/Chat_Detail/chat_detail_notifier.dart';
import 'package:notesapp/root/screens/Homescreen/components/doc_icon.dart';

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
              : Text(chat.title ?? "New Chat"), // ✅ no crash risk
          actions: [
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit),
              onPressed: isEditing ? _finishEditing : _startEditing,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: screenSize.height / 3,
                margin: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(67, 164, 182, 191),
                  shape: BoxShape.circle,
                ),
                child: Center(child: DocumentIcon(size: screenSize.height / 3)),
              ),
              Column(
                children: [
                  TabBar(
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: "Photos"),
                      Tab(text: "Documents"),
                    ],
                  ),
                  // TabBarView(children: [
                  //   Text("No Photos in chat yet"),
                  //   Text("No Documents in chat yet"),
                  // ])
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
