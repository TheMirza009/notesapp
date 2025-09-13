import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_tile_og.dart';
import 'package:notesapp/root/screens/Load_test/isar_test.dart/note_item.dart';
import 'package:notesapp/root/screens/Load_test/isar_test.dart/screens/test_chat_screen.dart';
import 'package:notesapp/root/screens/Load_test/widgets/pulldown_wrapper.dart';
import 'package:path_provider/path_provider.dart';

class LoadChatListScreen extends ConsumerStatefulWidget {
  const LoadChatListScreen({super.key});

  @override
  ConsumerState<LoadChatListScreen> createState() => _LoadTestScreenState();
}

class _LoadTestScreenState extends ConsumerState<LoadChatListScreen> {
  late Isar _isar;
  List<Chat> chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initIsar();
  }

  // =======================================================================

  //                       I S A R    F UN C T I O N S

  // =======================================================================


  /// Init Method for Isar
  Future<void> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();

    // Check if an Isar instance is already open
    if (Isar.instanceNames.contains('isar')) {
      _isar = Isar.getInstance('isar')!;
    } else {
      _isar = await Isar.open(
        [
          ChatSchema,
          MessageSchema,
          MediaSchema,
        ],
        directory: dir.path,
        name: 'isar',
      );
    }

    final loadedChats = await _isar.chats.where().findAll();
    for (final chat in loadedChats) {
      await chat.messages.load();
    }

    setState(() {
      chats = loadedChats;
      _loading = false;
    });
  }

  Future<void> _addChat(String text) async {
    final newChat = Chat.emptyChat();
    newChat.title = text;
    newChat.preview = "Messages for: $text";

    late Chat savedChat;

    await _isar.writeTxn(() async {
      final id = await _isar.chats.put(newChat);
      savedChat = await _isar.chats.get(id) ?? newChat; // get attached version
    });

    setState(() {
      chats.add(savedChat);
    });
  }

  Future<void> deleteChat(Chat chat) async {
    await _isar.writeTxn(() async {
      if (!chat.messages.isLoaded) {
        await chat.messages.load();
      }

      final messageIds = chat.messages.map((m) => m.isarId).toList();
      if (messageIds.isNotEmpty) {
        await _isar.messages.deleteAll(messageIds);
      }
      await _isar.chats.delete(chat.id);
    });

    setState(() {
      chats.remove(chat);
    });
  }

  Future<void> deleteAllChats() async {
    await _isar.writeTxn(() async {
      await _isar.chats.clear();
    });

    setState(() {
      chats.clear();
    });
  }

  // =======================================================================

  //                       U S E R   I N T E R F A C E

  // =======================================================================


  void _showAddDialog() {
  String? text;
  IconData selectedIcon = Icons.star_border_outlined;

  final iconOptions = {
    Icons.star_border_outlined: "Star",
    Icons.circle_outlined: "Circle",
    CupertinoIcons.bolt: "Square",
    Icons.change_history: "Triangle",
  };

  showCupertinoDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateSB) => CupertinoAlertDialog(
        title: const Text("Add Note"),
        content: Column(
          children: [
            const SizedBox(height: 10),
            CupertinoTextField(
              placeholder: "Enter note",
              onChanged: (val) => text = val,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            CupertinoSlidingSegmentedControl<IconData>(
                groupValue: selectedIcon,
                children: {
                  for (var entry in iconOptions.entries)
                    entry.key: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(entry.key),
                    ),
                },
                onValueChanged: (value) {
                  if (value != null) setState(() => selectedIcon = value);
                },
              ),

          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text("Add"),
            onPressed: () {
              if (text != null && text!.isNotEmpty) _addChat(text!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '', // <-- disable tooltip
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text("Chat Load Test"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Container(
              decoration: BoxDecoration(gradient: Gradients.darkBackground),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 10),
                    child: Text("Chats", style: TextStyle(fontSize: 25),),
                  ),
                  Expanded(
                    child: chats.isEmpty 
                    ? Center(child: Text("No Chats to show"),) 
                    : ListView.separated(
                        separatorBuilder: (context, index) => Divider(),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          return Dismissible(
                            key: ValueKey(chat.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => deleteChat(chat),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TestChatScreen(chat: chat))),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueGrey.withAlpha(50),
                                  child: Icon(Icons.messenger, color: ThemeConstants.homeSubtitleLight,)),
                                title: Text(
                                  chat.title ?? "N/A", 
                                  style: TextStyle(fontSize: 20),
                                  ),
                                subtitle: Text(
                                            chat.messages.isNotEmpty 
                                            ? (chat.messages.last.text ?? "No messages yet.") 
                                            : "No messages yet.",
                                  style: TextStyle(color: ThemeConstants.iconColorNeutral),
                                  ),
                                trailing: Text(
                                  TimeFormat.formatChatSubtitle(chat.date).replaceFirst("today at", "") ?? "00:00", 
                                  style: TextStyle(fontSize: 10),
                                  ),
                                ),
                            ),
                          );
                        },
                      ),
                  ),
                ],
              ),
            ),
    );
  }
}
