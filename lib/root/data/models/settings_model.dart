import 'package:isar_community/isar.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';

part 'settings_model.g.dart';

@collection
class Settings {
  /// Always only 1 record. Use a fixed ID (e.g. 0) instead of autoIncrement.
  Id id = 0;

  /// Store enum as int for Isar compatibility
  int selectedBubbleStyleIndex = BubbleStyle.opaque.index;

  bool chatDisplayAscending = true; // True = start from top of chat || False = start from bottom of chat
  bool isLightMode = false;

  Settings({
    BubbleStyle? selectedBubbleStyle,
    this.chatDisplayAscending = true,
    this.isLightMode = false,
  }) {
    if (selectedBubbleStyle != null) {
      selectedBubbleStyleIndex = selectedBubbleStyle.index;
    }
  }

  /// Getter/Setter wrapper for convenience — not stored directly.
  @ignore
  BubbleStyle get selectedBubbleStyle => BubbleStyle.values[selectedBubbleStyleIndex];

  @ignore
  set selectedBubbleStyle(BubbleStyle style) => selectedBubbleStyleIndex = style.index;

  Settings copyWith({
    BubbleStyle? selectedBubbleStyle,
    bool? chatDisplayAscending,
    bool? isLightMode,
  }) {
    return Settings(
      selectedBubbleStyle: selectedBubbleStyle ?? this.selectedBubbleStyle,
      chatDisplayAscending: chatDisplayAscending ?? this.chatDisplayAscending,
      isLightMode: isLightMode ?? this.isLightMode,
    );
  }

  /// Convenience methods
  Settings setBubbleStyle(BubbleStyle style) {
    return copyWith(selectedBubbleStyle: style);
  }

  Settings toggleChatDisplayOrder() {
    return copyWith(chatDisplayAscending: !chatDisplayAscending);
  }

  Settings toggleTheme() {
    return copyWith(isLightMode: !isLightMode);
  }

  /// Helper to get display-friendly chat order description
  @ignore
  String get chatOrderDescription => chatDisplayAscending 
      ? "Oldest first (start from top)" 
      : "Newest first (start from bottom)";

  /// Helper to get theme name
  @ignore
  String get themeName => isLightMode ? "Light" : "Dark";

  @override
  String toString() => 'Settings('
      'bubbleStyle: $selectedBubbleStyle, '
      'chatOrder: $chatOrderDescription, '
      'theme: $themeName'
      ')';
}