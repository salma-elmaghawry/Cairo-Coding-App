import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

extension AppDateFormats on BuildContext {
  String get _locale => locale.languageCode;

  String fullDay(DateTime date) => DateFormat('EEEE, d MMMM', _locale).format(date);

  String shortDay(DateTime date) => DateFormat('EEE d MMM', _locale).format(date);

  String weekdayShort(DateTime date) => DateFormat('EEE', _locale).format(date);

  String dayNumber(DateTime date) => DateFormat('dd', 'en').format(date);

  String time(DateTime date) => DateFormat.jm(_locale).format(date);

  String dayMonthYear(DateTime date) => DateFormat('d MMM y', _locale).format(date);

  String monthRange(DateTime start, DateTime end) {
    final format = DateFormat('d MMM', _locale);
    return '${format.format(start)} – ${format.format(end)}';
  }

  String weekdayName(int weekday) => DateFormat('EEEE', _locale).format(DateTime(2024, 1, weekday));

  String weekdayShortName(int weekday) => DateFormat('EEE', _locale).format(DateTime(2024, 1, weekday));

  String timeOfDay(int hour, int minute) => DateFormat.jm(_locale).format(DateTime(2024, 1, 1, hour, minute));

  /// "12 min ago", "2 h ago", "Yesterday, 9:14 PM", or the date for anything older.
  String relativeTime(DateTime when, DateTime now) {
    final ago = now.difference(when);
    if (ago.inMinutes < 1) return 'time.just_now'.tr();
    if (ago.inMinutes < 60) return 'time.minutes_ago'.tr(args: ['${ago.inMinutes}']);
    final today = DateTime(now.year, now.month, now.day);
    if (!when.isBefore(today)) return 'time.hours_ago'.tr(args: ['${ago.inHours}']);
    if (!when.isBefore(today.subtract(const Duration(days: 1)))) return 'time.yesterday_at'.tr(args: [time(when)]);
    return '${shortDay(when)}, ${time(when)}';
  }
}
