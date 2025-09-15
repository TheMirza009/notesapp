import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/enums/media_type.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/bottom_message_bar.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';

class ChatNotifier extends Notifier<Chat> {
  late final Isar isar;
  final Chat initialChat;

  ChatNotifier(this.initialChat);

  @override
  Chat build() {
    isar = Isar.getInstance('isar')!;
    loadFromDatabase();
    return initialChat; // return non-null fallback
  }

  Future<void> loadFromDatabase() async {
    final freshChat = await isar.chats.get(initialChat.isarID);
    if (freshChat != null) {
      await freshChat.messages.load();
      await Future.wait(freshChat.messages.map((m) => m.media.load()));
      state = freshChat;
    }
  }

  Future<void> pickImage() async {
    final pickedMedia = await MediaHandler.pickImage();
    if (pickedMedia == null) return;

    deleteInitMessage();
    // Persist the media with the cached aspect ratio
    await isar.writeTxn(() async {
      await isar.medias.put(pickedMedia);
    });

    // Reload persisted media
    final persistedMedia = await isar.medias.get(pickedMedia.isarId);
    if (persistedMedia == null) return;

    // Create message
    final newMessage =
        Message()
          ..text = ""
          ..isSender = true
          ..isSelected = false
          ..time = DateTime.now()
          ..media.value = persistedMedia;

    // Persist message and attach to chat
    await isar.writeTxn(() async {
      await isar.messages.put(newMessage);
      await newMessage.media.save();

      initialChat.messages.add(newMessage);
      await initialChat.messages.save();

      initialChat.preview = "📷 Photo";
      initialChat.date = newMessage.time;
      await isar.chats.put(initialChat);
    });

    await newMessage.media.load();

    state = initialChat;
  }

  Future<void> sendMessage(String text) async {
    deleteInitMessage();
    final newMessage =
        Message()
          ..text = text
          ..isSender = true
          ..isSelected = false
          ..time = DateTime.now();

    await isar.writeTxn(() async {
      await isar.messages.put(newMessage);

      // attach to the chat relation and persist
      initialChat.messages.add(newMessage);
      await initialChat.messages.save();

      initialChat.preview = text;
      initialChat.date = newMessage.time;
      await isar.chats.put(initialChat);
    });
  }

  void deleteInitMessage() {
    const String initID = "0000";
    const String initText = "This is a new chat. Start typing to create your first note.";
    bool initCheck = initialChat.messages.first.id == initID && initialChat.messages.first.text == initText;
    if (initCheck) {
      deleteMessage(initialChat.messages.first);
    }
  }

  Future<void> updateMessage(Message message) async {
    await isar.writeTxn(() async {
      final existing = await isar.messages.get(message.isarId);
      if (existing != null) {
        existing.isSender = message.isSender;
        existing.text = message.text;
        existing.isSelected = message.isSelected;
        await isar.messages.put(existing);
      } else {
        await isar.messages.put(message);
      }
    });
  }

  Future<void> deleteMessage(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.delete(message.isarId);

      // remove relation and persist
      initialChat.messages.remove(message);
      await initialChat.messages.save();
      await isar.chats.put(initialChat);
    });
    if (message.media.value?.type == Mediatype.image) {
      await MediaHandler.deleteMedia(message.media.value!);
    }
  }
}

/// ------------------ Riverpod Provider ------------------
/// Factory function to create a provider bound to a specific chat
NotifierProvider<ChatNotifier, Chat> chatProvider(Chat chat) {
  return NotifierProvider<ChatNotifier, Chat>(
    () => ChatNotifier(chat),
  );
}

/// ------------------ UI ------------------

class TestChatScreen extends ConsumerWidget {
  final Chat chat;
  const TestChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch the provider that is bound to this chat
    final currentChat = ref.watch(chatProvider(chat)); // ✅ state is Chat
    final notifier = ref.read(chatProvider(chat).notifier,); // ✅ access methods

    // Defensive: if for any reason chatState is null (shouldn't be with Notifier<Chat>),
    // show a loader.
    if (currentChat == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final messages = currentChat.messages.toList();

    return Scaffold(
      backgroundColor: ThemeConstants.textLight,
      appBar: AppBar(
        title: Text("Chat: ${currentChat.title}"),
        backgroundColor: ThemeConstants.messageBarDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '',
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                messages.isEmpty
                    ? const NothingToSee()
                    : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return MessageBubble(
                          style: BubbleStyle.opaque,
                          message: message,
                          onTap: () {
                            message.isSender = !message.isSender;
                            notifier.updateMessage(message);
                          },
                          onLongPress:
                              (_) => notifier.deleteMessage(message),
                        );
                      },
                    ),
          ),
          BottomMessageBar(
            onEmojiTap: () {},
            onAttachmentTap: () => notifier.pickImage(),
            onMicTap: () {},
            onSend: (text) => notifier.sendMessage(text),
          ),
        ],
      ),
    );
  }
}
