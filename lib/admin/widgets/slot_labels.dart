import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/data/models/weekly_slot.dart';
import 'package:flutter/widgets.dart';

extension SlotLabels on BuildContext {
  String slotLabel(WeeklySlot slot) => '${weekdayShortName(slot.weekday)} ${timeOfDay(slot.hour, slot.minute)}';

  String slotsSummary(List<WeeklySlot> slots) => slots.isEmpty ? '—' : slots.map(slotLabel).join(' · ');

  /// "Sun · Thu, 7:00 PM" when every slot starts at the same time, otherwise [slotsSummary].
  String slotsCompact(List<WeeklySlot> slots) {
    if (slots.length < 2 || slots.any((s) => s.minuteOfDay != slots.first.minuteOfDay)) return slotsSummary(slots);
    final first = slots.first;
    return '${slots.map((s) => weekdayShortName(s.weekday)).join(' · ')}, ${timeOfDay(first.hour, first.minute)}';
  }
}
