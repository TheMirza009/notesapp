import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/Theme/gradients.dart';
import 'package:notesapp/core/controllers/theme_provider.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';
import 'package:notesapp/core/utils/time_format.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Homescreen/components/chat_tile_og.dart';
import 'package:notesapp/root/screens/Load_test/isar_test.dart/note_item.dart';
import 'package:notesapp/root/screens/Load_test/widgets/pulldown_wrapper.dart';
import 'package:path_provider/path_provider.dart';

class LoadTestScreen extends ConsumerStatefulWidget {
  const LoadTestScreen({super.key});

  @override
  ConsumerState<LoadTestScreen> createState() => _LoadTestScreenState();
}

class _LoadTestScreenState extends ConsumerState<LoadTestScreen> {
  late Isar _isar;
  List<NoteItem> notes = [];
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
          NoteItemSchema,
          TextDataSchema,
          ChatSchema,
          MessageSchema,
          MediaSchema,
        ],
        directory: dir.path,
        name: 'isar',
      );
    }

    final loadedNotes = await _isar.noteItems.where().findAll();
    final loadedChats = await _isar.chats.where().findAll();
    for (final chat in loadedChats) {
      await chat.messages.load();
    }

    setState(() {
      notes = loadedNotes;
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

  Future<void> deleteAllChats() async {
    await _isar.writeTxn(() async {
      await _isar.chats.clear();
    });

    setState(() {
      chats.clear();
    });
  }

  /// Add Note and save method
  Future<void> _addNote(String text, IconData icon) async {
    final chatTitle = text;

    final textData =
        TextData()
          ..title = chatTitle
          ..subtitle = text;

    final note =
        NoteItem()
          ..iconCode = icon.codePoint
          ..textdata.value = textData;

    await _isar.writeTxn(() async {
      await _isar.textDatas.put(textData);
      await _isar.noteItems.put(note);
      await note.textdata.save();
    });

    _addChat(text);

    setState(() => notes.add(note));
  }

  /// Delete Note
  Future<void> _deleteNote(NoteItem note) async {
    await _isar.writeTxn(() async {
      if (!note.textdata.isLoaded) {
        await note.textdata.load();
      }

      // Now safely access it
      final linked = note.textdata.value;
      if (linked != null) {
        await _isar.textDatas.delete(linked.id);
      }

      // Delete the note itself
      await _isar.noteItems.delete(note.id);
    });

    deleteAllChats();
    setState(() => notes.remove(note));
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
              if (text != null && text!.isNotEmpty) _addNote(text!, selectedIcon);
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
      appBar: AppBar(title: const Text("Load Test"), backgroundColor: Colors.transparent, elevation: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white,),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(gradient: Gradients.darkBackground),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 10),
                    child: Text("Notes", style: TextStyle(fontSize: 25),),
                  ),
                  SizedBox(
                    height: context.screenHeight / 3,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteNote(note),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () => print(note.textdata.value?.title ?? "No title"),
                              contentPadding: EdgeInsets.all(20),
                              leading: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Icon(IconData(note.iconCode, fontFamily: 'MaterialIcons'), color: Colors.white),
                              ),
                              title: Text(note.textdata.value?.subtitle ?? "No title" ),
                              subtitle: Text(note.textdata.value?.subtitle ?? "No title" , style: TextStyle(color: Colors.blueGrey),),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 10),
                    child: Text("Chats", style: TextStyle(fontSize: 25),),
                  ),
                  // SizedBox(height: context.screenHeight / 3,
                  // child: chats.isEmpty 
                  // ? Center(child: Text("No Chats to show"),) 
                  // : ListView.builder(
                  //     itemCount: chats.length,
                  //     itemBuilder: (context, index) {
                  //       final chat = chats[index];
                  //       return ListTile(
                  //         title: Text(chat.title ?? "N/A"),
                  //         subtitle: Text(chat.preview),
                  //         trailing: Text(TimeFormat.formatChatSubtitle( chat.date, ) ?? "00:00",) );
                  //     },
                  //   ),
                  // ),
                  // AnimatedSlide(
                  //   duration: Duration(milliseconds: 300),
                  //   curve: Curves.bounceIn,
                  //   offset: Offset(0, showEmojis ? 0 : 1),
                  //   child: EmojiPicker(
                    
                  //   ),
                  // )
                ],
              ),
            ),
    );
  }
}
