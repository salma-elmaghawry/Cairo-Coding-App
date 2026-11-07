import 'package:cairo_coding_app/data/models/class_session.dart';

/// Attendance worked out from the sessions' attendee lists.
///
/// Only sessions that were held and have attendance count, so sessions from before attendance was recorded
/// don't read as everyone missing them.
class Attendance {
  const Attendance._();

  /// Held sessions with attendance taken, oldest first.
  static List<ClassSession> counted(Iterable<ClassSession> sessions, DateTime now) =>
      sessions.where((s) => s.isPast(now) && !s.isCancelled && s.hasAttendance).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  /// The share of [members] who were at [session], from 0 to 1; null when there's nobody to expect.
  static double? sessionRate(ClassSession session, Set<String> members) {
    if (members.isEmpty || !session.hasAttendance) return null;
    return session.attendees!.where(members.contains).length / members.length;
  }

  /// The mean of [sessionRate] over [counted]; null before any session counts.
  static double? groupRate(List<ClassSession> counted, Set<String> members) {
    final rates = [for (final session in counted) ?sessionRate(session, members)];
    if (rates.isEmpty) return null;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  /// The share of [counted] sessions [uid] was at; null before any session counts.
  static double? studentRate(String uid, List<ClassSession> counted) {
    if (counted.isEmpty) return null;
    return counted.where((s) => s.attendees!.contains(uid)).length / counted.length;
  }

  /// The latest sessions [uid] missed one after another, oldest first.
  static List<ClassSession> missedStreak(String uid, List<ClassSession> counted) {
    final missed = <ClassSession>[];
    for (final session in counted.reversed) {
      if (session.attendees!.contains(uid)) break;
      missed.insert(0, session);
    }
    return missed;
  }
}

/// A rate from 0 to 1 as a whole percentage.
int percent(double rate) => (rate * 100).round();
