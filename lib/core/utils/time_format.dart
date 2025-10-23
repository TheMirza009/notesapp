import 'package:intl/intl.dart';

class TimeFormat {

  /// Show proper date/time for chat
  static String formatChatTime(DateTime time) {
    final DateTime now = DateTime.now();
    final bool isSameDay = time.year == now.year &&  time.month == now.month &&  time.day == now.day;
    final bool isSameYear = time.year == now.year;
    final String timeAMPM = DateFormat.jm().format(time);
    final String date = DateFormat('d MMM').format(time);
    final String dateWithYear = DateFormat('MMM yyyy').format(time);

    if (isSameDay) {
      return timeAMPM; // show time with AM/PM e.g., 3:45 PM
    } else if (isSameYear) {
      return date; // Show day + month name, e.g., "12 Sep"
    } else {
      return dateWithYear; // Show month name + year, e.g., "Sep 2024"
    }
  }

  static String formatChatDateChip(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return "Today";
    } else if (msgDate == yesterday) {
      return "Yesterday";
    } else if (now.difference(msgDate).inDays < 7) {  // Show weekday name
      return DateFormat.EEEE().format(date); // e.g. "Sunday"
    } else {  // Show full date
      return DateFormat('d MMM yyyy').format(date); // e.g. "14 Jun 2024"
    }
  }

  static String formatChatSubtitle(DateTime lastEdited) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastEditedDate = DateTime(lastEdited.year, lastEdited.month, lastEdited.day);
    final String formattedTime = DateFormat.jm().format(lastEdited);

    if (lastEditedDate == today) {
      return "today at $formattedTime";
    } else if (lastEditedDate == yesterday) {
      return "yesterday $formattedTime";
    } else if (now.difference(lastEditedDate).inDays < 7) {
      return DateFormat.EEEE().format(lastEdited);
    } else {
      return DateFormat('d MMM yyyy').format(lastEdited);
    }
  }

  static String imageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayPart;
    if (dateOnly == today) {
      dayPart = "Today";
    } else if (dateOnly == yesterday) {
      dayPart = "Yesterday";
    } else {
      // show date: 13 September (year if different)
      dayPart = DateFormat('d MMMM').format(dateTime);
      if (dateTime.year != now.year) {
        dayPart += " ${dateTime.year}";
      }
    }

    final timePart = DateFormat('hh:mm a').format(dateTime); // 02:45 PM
    return "$dayPart, $timePart";
  }
}
