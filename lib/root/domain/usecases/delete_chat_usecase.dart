// lib/root/domain/usecases/delete_chat_usecase.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notesapp/root/data/models/chat_model.dart';
import 'package:notesapp/root/data/chat_list_provider/chat_list_notifier.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/core/Theme/theme_constants.dart';
import 'package:notesapp/core/utils/global_keys.dart';
import 'package:notesapp/core/extensions/context_extensions.dart';

class DeleteChatUseCase {
  final Ref ref;
  Timer? _timer;
  final List<Chat> _queue = [];
  
  static const String _pendingKey = 'pending_deletions_count';

  DeleteChatUseCase(this.ref);

  void queueDelete(Chat chat) {
    if (!_queue.any((c) => c.isarID == chat.isarID)) {
      _queue.add(chat);
      ref.read(chatListProvider.notifier).tempRemoveChat(chat);
      _persistQueueState();
    }
    
    _resetTimer();
    _showSnackBar();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), _commitDeletes);
  }

  void undoDeletes() {
    _timer?.cancel();
    final notifier = ref.read(chatListProvider.notifier);
    for (var chat in _queue) {
      notifier.restoreTempChat(chat);
    }
    _queue.clear();
    _persistQueueState();
    
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    }
  }

  Future<void> _commitDeletes() async {
    final idsToDelete = _queue.map((c) => c.isarID).toList();
    _queue.clear();
    _persistQueueState();

    try {
      await IsarDatabase.isar.writeTxn(() async {
        await IsarDatabase.isar.chats.deleteAll(idsToDelete);
      });
    } catch (e) {
      debugPrint("Failed to commit deletes: $e");
    }

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    }
  }

  void _showSnackBar() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final scaffold = ScaffoldMessenger.of(ctx);
    scaffold.hideCurrentSnackBar();

    final count = _queue.length;
    final message = count == 1 ? "1 chat deleted" : "$count chats deleted";

    final snackBar = SnackBar(
      padding: EdgeInsets.zero,
      backgroundColor: ctx.isLight 
        ? ThemeConstants.hometoolbarLight2 
        : ThemeConstants.darkAppbar,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Using a unique key forces the animation to restart completely
          TweenAnimationBuilder<double>(
            key: UniqueKey(), 
            tween: Tween(begin: 1.0, end: 0.0),
            duration: const Duration(seconds: 4),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ctx.isLight ? ThemeConstants.sacredSeed : ThemeConstants.sinisterSeed,
                ),
                minHeight: 2,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              message,
              style: TextStyle(
                fontFamily: "Poppins",
                color: ctx.isLight 
                  ? ThemeConstants.textLight 
                  : ThemeConstants.textDark2,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: "Undo",
        textColor: ctx.isLight ? ThemeConstants.sinisterSeed : ThemeConstants.sinisterSeedHighlight,
        onPressed: () {
          undoDeletes();
        },
      ),
    );

    scaffold.showSnackBar(snackBar);
  }

  Future<void> _persistQueueState() async {
     try {
       final prefs = await SharedPreferences.getInstance();
       await prefs.setInt(_pendingKey, _queue.length);
     } catch (e) {
       debugPrint('Error saving pending deletions to SharedPreferences: $e');
     }
  }

  /// Called on app startup to check if we crashed during a pending delete
  Future<int> getAndClearPendingDeletions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_pendingKey) ?? 0;
      if (count > 0) {
        await prefs.setInt(_pendingKey, 0);
      }
      return count;
    } catch (e) {
      return 0;
    }
  }
}

final deleteChatUseCaseProvider = Provider((ref) => DeleteChatUseCase(ref));
