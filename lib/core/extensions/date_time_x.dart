import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  /// Returns a formatted month label, e.g. "Jan", "Feb".
  String get shortMonth => DateFormat.MMM().format(this);

  /// Returns a formatted month + year label, e.g. "Jan 2025".
  String get monthYear => DateFormat.yMMM().format(this);

  /// Returns a formatted full date, e.g. "18 May 2025".
  String get fullDate => DateFormat('dd MMM yyyy').format(this);

  /// Returns a formatted date and time, e.g. "18 May 2025, 14:30".
  String get dateTime => DateFormat('dd MMM yyyy, HH:mm').format(this);

  /// Returns the relative label like "Today", "Yesterday", or a date string.
  String get relativeLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat.EEEE().format(this); // Monday, Tuesday…
    return fullDate;
  }

  /// Whether this date falls in the same month and year as [other].
  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  /// Returns midnight of this date (time stripped).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the last moment of this date.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns the first day of this month.
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Returns the last day of this month.
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);
}
