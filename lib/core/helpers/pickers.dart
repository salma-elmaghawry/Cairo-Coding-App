import 'package:flutter/material.dart';

Future<DateTime?> pickDateTime(BuildContext context, {required DateTime initial}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(initial.year - 1),
    lastDate: DateTime(initial.year + 2),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

Future<DateTime?> pickDate(BuildContext context, {required DateTime initial}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(initial.year - 2),
    lastDate: DateTime(initial.year + 3),
  );
}
