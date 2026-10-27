import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:intl/intl.dart';

typedef Translate = String Function(String key, [List<String> args]);

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.visibleFor,
  });

  final int id;
  final DateTime fireAt;
  final String title;
  final String body;
  final Duration visibleFor;
}

class ReminderPlanner {
  const ReminderPlanner({required this.translate, required this.languageCode});

  static const Duration dayBefore = Duration(hours: 24);
  static const Duration hourBefore = Duration(hours: 1);
  static const Duration horizon = Duration(days: 14);
  static const int maxReminders = 40;

  final Translate translate;
  final String languageCode;

  String get channelName => translate('settings.reminders_title');

  String get channelDescription => translate('settings.reminders_message');

  List<PlannedReminder> plan(
    List<ClassSession> sessions, {
    required Map<String, String> groupNames,
    required DateTime now,
  }) {
    final earliest = now.add(const Duration(minutes: 1));
    final until = now.add(horizon);
    final reminders = [
      for (final session in sessions)
        if (!session.isCancelled && session.startsAt.isBefore(until))
          for (final lead in const [dayBefore, hourBefore])
            if (session.startsAt.subtract(lead).isAfter(earliest))
              _reminder(session, lead, groupNames[session.groupId]),
    ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return reminders.take(maxReminders).toList();
  }

  PlannedReminder _reminder(ClassSession session, Duration lead, String? groupName) {
    final sessionTitle = session.number == null
        ? translate('session.extra_title')
        : translate('session.title', ['${session.number}']);
    final time = DateFormat.jm(languageCode).format(session.startsAt);

    return PlannedReminder(
      id: _stableId('${session.groupId}/${session.id}/${lead.inMinutes}'),
      fireAt: session.startsAt.subtract(lead),
      title: translate(lead == dayBefore ? 'reminders.tomorrow' : 'reminders.soon', [sessionTitle, time]),
      body: groupName == null ? translate('reminders.body') : translate('reminders.body_group', [groupName]),
      visibleFor: lead + Duration(minutes: session.durationMin),
    );
  }

  // FNV-1a, because String.hashCode isn't guaranteed to match between the app and the background isolate.
  static int _stableId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}
