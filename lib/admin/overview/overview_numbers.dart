import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:cairo_coding_app/data/services/quiz_averages.dart';

enum OverviewPeriod {
  week(Duration(days: 7)),
  month(Duration(days: 30)),
  all(null);

  const OverviewPeriod(this.length);

  final Duration? length;
}

/// A KPI's value now, the one from the period before for comparison, and recent points for its sparkline.
class Kpi {
  const Kpi({required this.value, this.previous, this.trend = const []});

  final double? value;
  final double? previous;
  final List<double> trend;

  double? get change => value == null || previous == null ? null : value! - previous!;
}

/// The overview's numbers across every group that isn't archived.
class OverviewNumbers {
  OverviewNumbers({required this.groups, required this.now, required this.period});

  final List<GroupInsights> groups;
  final DateTime now;
  final OverviewPeriod period;

  DateTime? get _from => period.length == null ? null : now.subtract(period.length!);
  DateTime? get _before => period.length == null ? null : now.subtract(period.length! * 2);

  bool _within(DateTime date, DateTime? from, DateTime until) =>
      (from == null || !date.isBefore(from)) && date.isBefore(until);

  /// Active students in these groups, each once.
  late final List<Student> students = {
    for (final group in groups)
      for (final student in group.members) student.uid: student,
  }.values.toList();

  late final Kpi activeStudents = Kpi(
    value: students.length.toDouble(),
    previous: _from == null
        ? null
        : students.where((s) => s.createdAt == null || s.createdAt!.isBefore(_from!)).length.toDouble(),
    trend: [
      for (var week = 7; week >= 0; week--)
        students
            .where((s) => s.createdAt == null || s.createdAt!.isBefore(now.subtract(Duration(days: 7 * week))))
            .length
            .toDouble(),
    ],
  );

  /// Every counted session with the share of its group present, oldest first.
  late final List<(ClassSession, double)> _sessionRates = [
    for (final group in groups)
      for (final session in group.counted)
        if (Attendance.sessionRate(session, group.memberIds) case final rate?) (session, rate),
  ]..sort((a, b) => a.$1.startsAt.compareTo(b.$1.startsAt));

  double? _meanRate(DateTime? from, DateTime until) {
    final rates = [
      for (final (session, rate) in _sessionRates)
        if (_within(session.startsAt, from, until)) rate,
    ];
    return rates.isEmpty ? null : rates.reduce((a, b) => a + b) / rates.length;
  }

  late final Kpi attendance = Kpi(
    value: _meanRate(_from, now),
    previous: _from == null ? null : _meanRate(_before, _from!),
    trend: [for (final (_, rate) in _sessionRates.reversed.take(8).toList().reversed) rate],
  );

  late final Map<String, Quiz> _quizzes = {for (final group in groups) ...group.quizzes};

  double? _quizMean(DateTime? from, DateTime until) => QuizAverages.group([
    for (final group in groups)
      for (final board in group.boards)
        if (_quizzes[board.quizId] case final quiz? when _within(quiz.opensAt, from, until)) board,
  ], _quizzes);

  late final Kpi quizScore = () {
    final recent = (_quizzes.values.where((q) => q.opensAt.isBefore(now)).toList()
      ..sort((a, b) => a.opensAt.compareTo(b.opensAt)));
    return Kpi(
      value: _quizMean(_from, now),
      previous: _from == null ? null : _quizMean(_before, _from!),
      trend: [
        for (final quiz in recent.reversed.take(8).toList().reversed)
          ?QuizAverages.group([for (final group in groups) ?group.boardOf(quiz.id)], _quizzes),
      ],
    );
  }();

  late final List<ClassSession> _held = [for (final group in groups) ...group.held];

  /// This week's sessions: from the most recent Saturday, the first day of the week in Egypt.
  late final DateTime weekStart = () {
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: (today.weekday - DateTime.saturday) % 7));
  }();

  late final List<ClassSession> thisWeek = _held
      .where((s) => _within(s.startsAt, weekStart, weekStart.add(const Duration(days: 7))))
      .toList();

  late final int doneThisWeek = thisWeek.where((s) => s.isPast(now)).length;

  late final Kpi sessionsThisWeek = Kpi(
    value: thisWeek.length.toDouble(),
    trend: [
      for (var week = 7; week >= 0; week--)
        () {
          final start = weekStart.subtract(Duration(days: 7 * week));
          return _held.where((s) => _within(s.startsAt, start, start.add(const Duration(days: 7)))).length.toDouble();
        }(),
    ],
  );

  /// Open quizzes that close within a day.
  late final int quizzesClosingSoon = _quizzes.values
      .where((q) => q.isPublished && q.isOpen(now) && q.closesAt.difference(now).inHours < 24)
      .length;

  /// Sessions still to come, soonest first.
  late final List<(GroupInsights, ClassSession)> upcoming = [
    for (final group in groups)
      for (final session in group.held)
        if (!session.isPast(now)) (group, session),
  ]..sort((a, b) => a.$2.startsAt.compareTo(b.$2.startsAt));
}
