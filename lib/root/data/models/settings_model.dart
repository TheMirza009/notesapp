import 'package:isar/isar.dart';
import 'package:notesapp/root/data/enums/bubble_style.dart';

part 'settings_model.g.dart';

@collection
class Settings {
  /// Always only 1 record. Use a fixed ID (e.g. 0) instead of autoIncrement.
  Id id = 0;

  /// Store enum as int for Isar compatibility
  int selectedBubbleStyleIndex = BubbleStyle.opaque.index;

  Settings({
    BubbleStyle? selectedBubbleStyle,
  }) {
    if (selectedBubbleStyle != null) {
      selectedBubbleStyleIndex = selectedBubbleStyle.index;
    }
  }

  /// Getter/Setter wrapper for convenience — not stored directly.
  @ignore
  BubbleStyle get selectedBubbleStyle =>  BubbleStyle.values[selectedBubbleStyleIndex];

  @ignore
  set selectedBubbleStyle(BubbleStyle style) =>  selectedBubbleStyleIndex = style.index;

  Settings copyWith({BubbleStyle? selectedBubbleStyle}) {
    return Settings(
      selectedBubbleStyle:
          selectedBubbleStyle ?? this.selectedBubbleStyle,
    );
  }

  Settings setBubbleStyle(BubbleStyle style) {
    return copyWith(selectedBubbleStyle: style);
  }
}
