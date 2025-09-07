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
}
