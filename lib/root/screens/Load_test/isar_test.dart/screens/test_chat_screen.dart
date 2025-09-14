import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/core/extensions/chat_list_isar_extensions.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/bottom_message_bar.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';
import 'package:notesapp/root/widgets/glass_container.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';

class TestChatScreen extends StatefulWidget {
  final Chat chat;
  const TestChatScreen({super.key, required this.chat});

  @override
  State<TestChatScreen> createState() => _TestChatScreenState();
}


class _TestChatScreenState extends State<TestChatScreen> {
  List<Message> messages = [];
  late final Isar isar;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isar = Isar.getInstance('isar')!;
    loadMessages();
  }

  Future<void> getIsarInstance() async {
    isar = Isar.getInstance('isar')!;
    if (isar == null) {
      throw Exception("Isar has not been initialized.");
    }
  }

  Future<void> loadMessages() async {
    // Load the messages linked to this chat
    await widget.chat.messages.load();
    Future.wait(widget.chat.messages.map((message) => message.media.load()));

    setState(() {
      messages = widget.chat.messages.toList();
    });
  }

  Future<void> pickImage() async {
   final image = await MediaHandler.pickImage();
   if (image == null) return;

   final newImageMessage = Message()
   ..text = ""
   ..isSelected = false
   ..isSender = true
   ..time = DateTime.now()
   ..media.value = image; 

   await isar.writeTxn(() async {
    await isar.medias.put(image!);
    await isar.messages.put(newImageMessage);
    await newImageMessage.media.save();
    widget.chat.messages.add(newImageMessage);
    await widget.chat.messages.save();
    widget.chat.preview = "📷 Photo";
    widget.chat.date = newImageMessage.time;
    await isar.chats.put(widget.chat);
   });

   setState(() {
     messages.add(newImageMessage);
   });
  }

  Future<void> sendMessage(String text) async {

    // Message creation
    final newMessage = Message()
    ..text = text
    ..isSender = true
    ..isSelected = false
    ..time = DateTime.now();

    // Database save
    await isar.writeTxn(() async {

      // add to messages database
      await isar.messages.put(newMessage);

      // connect to chat object
      widget.chat.messages.add(newMessage); // adding to local detached chat object
      await widget.chat.messages.save();

      // update chat
      widget.chat.preview = newMessage.text;
      widget.chat.date = newMessage.time;
      await isar.chats.put(widget.chat);
    });

    setState(() {
      messages.add(newMessage);
    });
  }

  Future<void> updateMessage(Message message) async {
    await isar.writeTxn(() async {
      // Check if the message exists in DB
      final existing = await isar.messages.get(message.isarId);

      if (existing != null) {
        // Exists -> update fields
        existing.isSender = message.isSender;
        existing.text = message.text;
        existing.isSelected = message.isSelected;

        await isar.messages.put(existing); // update
        print("Message updated: ${existing.id}");
      } else {
        // Does not exist -> insert new
        await isar.messages.put(message);
        print("Message inserted: ${message.id}");
      }
    });

    // setState(() {});
  }

  Future<void> deleteMessage(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.delete(message.isarId);
      widget.chat.messages.remove(message);
      await widget.chat.messages.save();
    });

    setState(() {
      messages.remove(message);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.textLight,
      appBar: AppBar(
        title: Text("Chat: ${widget.chat.title}"),
        backgroundColor: ThemeConstants.messageBarDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '', // <-- disable tooltip
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty 
            ? NothingToSee() 
            : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final Message message = messages[index];
                // return GlassContainer(child: Text(message.text));
              return MessageBubble(
                style: BubbleStyle.opaque,
                message: message,
                onTap: () {
                  setState(() {
                    message.isSender = !message.isSender;
                  });
                  updateMessage(message);
                },
                onLongPress: (p0) {
                  deleteMessage(message);
                },

              );
            }),
          ),
          BottomMessageBar(
            onEmojiTap: () {},
            onAttachmentTap: () => pickImage(),
            onMicTap: () {},
            onSend: (text) {
              print(text);
              sendMessage(text);
            },
          )
        ],
      ),
    );
  }
}