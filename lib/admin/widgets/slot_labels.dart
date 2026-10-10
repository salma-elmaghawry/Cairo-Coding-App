import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/data/models/weekly_slot.dart';
import 'package:flutter/widgets.dart';

extension SlotLabels on BuildContext {
  String slotLabel(WeeklySlot slot) => '${weekdayShortName(slot.weekday)} ${timeOfDay(slot.hour, slot.minute)}';

  String slotsSummary(List<WeeklySlot> slots) => slots.isEmpty ? '—' : slots.map(slotLabel).join(' · ');
}
