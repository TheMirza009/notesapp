import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/controllers/media_handler.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/models/media_model.dart';
import 'package:notesapp/root/data/models/message_model.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/bottom_message_bar.dart';
import 'package:notesapp/root/screens/Chat_Screen/components/message_bubbles.dart/message_bubble_wrapper.dart';
import 'package:notesapp/root/widgets/nothing_to_see.dart';

/// ------------------ Chat State ------------------

class ChatState {
  final Chat chat;
  final List<Message> messages;

  ChatState({required this.chat, required this.messages});

  ChatState copyWith({Chat? chat, List<Message>? messages}) {
    return ChatState(
      chat: chat ?? this.chat,
      messages: messages ?? this.messages,
    );
  }
}

/// ------------------ Chat Notifier ------------------

class ChatNotifier extends FamilyNotifier<ChatState, Chat> {
  late final Isar isar;

  @override
  ChatState build(Chat chat) {
    isar = Isar.getInstance('isar')!;
    final stateInitial = ChatState(chat: chat, messages: []);
    loadMessages(chat); // async load messages
    return stateInitial;
  }

  Future<void> loadMessages(Chat chat) async {
    await chat.messages.load();
    await Future.wait(chat.messages.map((m) => m.media.load()));
    state = state.copyWith(messages: chat.messages.toList());
  }

  Future<void> pickImage() async {
    final image = await MediaHandler.pickImage();
    if (image == null) return;

    final newImageMessage = Message()
      ..text = ""
      ..isSender = true
      ..isSelected = false
      ..time = DateTime.now()
      ..media.value = image;

    await isar.writeTxn(() async {
      await isar.medias.put(image);
      await isar.messages.put(newImageMessage);
      await newImageMessage.media.save();
      state.chat.messages.add(newImageMessage);
      await state.chat.messages.save();
      state.chat.preview = "📷 Photo";
      state.chat.date = newImageMessage.time;
      await isar.chats.put(state.chat);
    });

    state = state.copyWith(messages: [...state.messages, newImageMessage]);
  }

  Future<void> sendMessage(String text) async {
    final newMessage = Message()
      ..text = text
      ..isSender = true
      ..isSelected = false
      ..time = DateTime.now();

    await isar.writeTxn(() async {
      await isar.messages.put(newMessage);
      state.chat.messages.add(newMessage);
      await state.chat.messages.save();
      state.chat.preview = text;
      state.chat.date = newMessage.time;
      await isar.chats.put(state.chat);
    });

    state = state.copyWith(messages: [...state.messages, newMessage]);
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
    loadMessages(state.chat);
  }

  Future<void> deleteMessage(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.delete(message.isarId);
      state.chat.messages.remove(message);
      await state.chat.messages.save();
    });

    state = state.copyWith(
      messages: state.messages.where((m) => m != message).toList(),
    );
  }
}

/// ------------------ Riverpod Provider ------------------

final chatProvider = NotifierProvider.family<ChatNotifier, ChatState, Chat>(
  () => ChatNotifier(),
);

/// ------------------ UI ------------------

class TestChatScreen extends ConsumerWidget {
  final Chat chat;
  const TestChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider(chat));
    final chatNotifier = ref.read(chatProvider(chat).notifier);

    return Scaffold(
      backgroundColor: ThemeConstants.textLight,
      appBar: AppBar(
        title: Text("Chat: ${chat.title}"),
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
            child: chatState.messages.isEmpty
                ? const NothingToSee()
                : ListView.builder(
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      return MessageBubble(
                        style: BubbleStyle.opaque,
                        message: message,
                        onTap: () {
                          message.isSender = !message.isSender;
                          chatNotifier.updateMessage(message);
                        },
                        onLongPress: (_) => chatNotifier.deleteMessage(message),
                      );
                    },
                  ),
          ),
          BottomMessageBar(
            onEmojiTap: () {},
            onAttachmentTap: () => chatNotifier.pickImage(),
            onMicTap: () {},
            onSend: (text) => chatNotifier.sendMessage(text),
          ),
        ],
      ),
    );
  }
}
