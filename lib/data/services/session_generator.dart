import 'package:cairo_coding_app/core/utils/cairo_time.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';

class SessionGenerator {
  const SessionGenerator();

  List<ClassSession> generate({required AcademyGroup group, required DateTime from, int firstNumber = 1}) {
    final sessions = <ClassSession>[];
    var number = firstNumber;
    final fromCairo = CairoTime.from(from);
    final endCairo = CairoTime.from(group.endDate);
    var day = DateTime.utc(fromCairo.year, fromCairo.month, fromCairo.day);
    final lastDay = DateTime.utc(endCairo.year, endCairo.month, endCairo.day);
    final slots = [...group.weeklySlots]..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));

    while (!day.isAfter(lastDay)) {
      for (final slot in slots.where((slot) => slot.weekday == day.weekday)) {
        final startsAt = CairoTime.at(day.year, day.month, day.day, slot.hour, slot.minute);
        if (startsAt.isBefore(from)) continue;
        sessions.add(
          ClassSession(
            id: '${group.id}_${startsAt.millisecondsSinceEpoch}',
            groupId: group.id,
            number: number++,
            startsAt: startsAt,
            durationMin: slot.durationMin,
          ),
        );
      }
      day = day.add(const Duration(days: 1));
    }
    return sessions;
  }
}
