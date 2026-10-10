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
}
