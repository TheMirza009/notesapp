extension StringCaseX on String {
  String toSentenceCase() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();
}
