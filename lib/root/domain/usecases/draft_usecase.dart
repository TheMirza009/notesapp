// lib/root/domain/usecases/draft_usecase.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-chat unsent message text ("drafts").
///
/// Cached in SharedPreferences so a draft survives an app restart, but it is
/// intentionally non-critical: losing one is harmless. The in-memory [state]
/// map (chatId -> draft) is the reactive source the chat tiles watch;
/// SharedPreferences is the persistent source of truth the chat screen reads.
class DraftUseCase extends Notifier<Map<int, String>> {
  // ── Control Panel ─────────────────────────────────────────────────────────
  static const String _keyPrefix = 'draft_';                  // prefs key = draft_<chatId>
  static const Duration _debounce = Duration(milliseconds: 400);

  // ── Fields ────────────────────────────────────────────────────────────────
  Timer? _debounceTimer;
  int? _pendingChatId;
  String? _pendingText;

  @override
  Map<int, String> build() {
    _hydrate();
    return {};
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  /// Loads every saved draft from prefs into [state] (called once on startup).
  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <int, String>{};
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(_keyPrefix)) continue;
        final chatId = int.tryParse(key.substring(_keyPrefix.length));
        final text = prefs.getString(key);
        if (chatId != null && text != null && text.isNotEmpty) {
          map[chatId] = text;
        }
      }
      state = map;
      debugPrint('[DRAFT] hydrated ${map.length} draft(s): ${map.keys.toList()}');
    } catch (e) {
      debugPrint('[DRAFT] hydrate failed: $e');
    }
  }

  /// Queues a debounced save of [text] for [chatId]; blank text clears instead.
  void save(int chatId, String text) {
    debugPrint('[DRAFT] save() chatId=$chatId len=${text.length}');
    if (chatId <= 0) return;
    if (text.trim().isEmpty) {
      clear(chatId);
      return;
    }
    _pendingChatId = chatId;
    _pendingText = text;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _flushPending);
  }

  // Writes the pending draft to prefs and the reactive map in one step.
  Future<void> _flushPending() async {
    final chatId = _pendingChatId;
    final text = _pendingText;
    if (chatId == null || text == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$chatId', text);
      state = {...state, chatId: text};
      debugPrint('[DRAFT] flushed to prefs: draft_$chatId (len=${text.length})');
    } catch (e) {
      debugPrint('[DRAFT] save failed: $e');
    }
  }

  /// Drops the draft for [chatId] from prefs and the reactive map immediately.
  Future<void> clear(int chatId) async {
    _debounceTimer?.cancel();
    if (_pendingChatId == chatId) {
      _pendingChatId = null;
      _pendingText = null;
    }
    if (!state.containsKey(chatId)) {
      // Still clear prefs in case the map hasn't hydrated this key yet.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$_keyPrefix$chatId');
      } catch (_) {}
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$chatId');
      state = {...state}..remove(chatId);
    } catch (e) {
      debugPrint('Draft clear failed: $e');
    }
  }

  /// Reads the persisted draft for [chatId] (source of truth, used on chat open).
  Future<String?> getDraft(int chatId) async {
    if (chatId <= 0) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('$_keyPrefix$chatId');
      debugPrint('[DRAFT] getDraft($chatId) -> ${value == null ? "null" : "len=${value.length}"}');
      return value;
    } catch (e) {
      debugPrint('[DRAFT] read failed: $e');
      return null;
    }
  }
}

final draftUseCaseProvider =
    NotifierProvider<DraftUseCase, Map<int, String>>(() => DraftUseCase());