import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:notesapp/core/controllers/isar_database.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';
import 'package:notesapp/root/data/models/settings_model.dart';

class SettingsNotifier extends StateNotifier<Settings?> {
  SettingsNotifier() : super(null) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isar = IsarDatabase.isar;

    // Always only 1 settings object — load or create it
    final existing = await isar.settings.get(0);
    if (existing != null) {
      state = existing;
      return;
    }

    // Create default if not found
    final defaultSettings = Settings(selectedBubbleStyle: BubbleStyle.opaque);
    await isar.writeTxn(() async {
      await isar.settings.put(defaultSettings);
    });
    state = defaultSettings;
  }

  Future<void> update(Settings newSettings) async {
    final isar = IsarDatabase.isar;
    await isar.writeTxn(() async {
      await isar.settings.put(newSettings);
    });
    state = newSettings;
  }

  Future<void> setBubbleStyle(BubbleStyle style) async {
    final current = state ?? Settings(selectedBubbleStyle: style);
    final updated = current.setBubbleStyle(style);
    await update(updated);
  }
}

final settingsController =
    StateNotifierProvider<SettingsNotifier, Settings?>(
  (ref) => SettingsNotifier(),
);
