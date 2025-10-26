import 'package:intl/intl.dart';

extension TimeExtensions on DateTime {
  String to12HourString() {
    return DateFormat.jm().format(this);
  }
}
