class TimeFormat {

  /// Show proper date/time
  static String formatChatTime(DateTime time) {
    final DateTime currentTime = DateTime.now();
    final bool isSameDay = time.day == currentTime.day;
    final bool isSameYear = time.year == currentTime.year;
    final lastMessageTime = "${time.hour}:${time.minute}";
    final lastMessageDate = "${time.day} ${time.month}";
    final lastMessageDateWithYear = "${time.month} ${time.year}";
    if (isSameDay) {
      return lastMessageTime;
    } else if (isSameYear) {
      return lastMessageDate;
    } else {
      return lastMessageDateWithYear;
    }
  }
}