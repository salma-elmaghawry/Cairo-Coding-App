import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:cairo_coding_app/data/services/quiz_averages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 7, 12);

  ClassSession session(int daysAgo, {List<String>? attendees, SessionStatus status = SessionStatus.scheduled}) =>
      ClassSession(
        id: 's$daysAgo',
        groupId: 'g',
        number: 30 - daysAgo,
        startsAt: now.subtract(Duration(days: daysAgo)),
        durationMin: 120,
        status: status,
        attendees: attendees,
      );

  group('Attendance', () {
    test('counts held sessions with attendance only, oldest first', () {
      final counted = Attendance.counted([
        session(1, attendees: ['a']),
        session(5, attendees: []),
        session(3),
        session(2, attendees: ['a'], status: SessionStatus.cancelled),
        session(-2, attendees: ['a']),
      ], now);
      expect(counted.map((s) => s.id), ['s5', 's1']);
    });

    test('rates a session, a group and a student', () {
      final members = {'a', 'b', 'c', 'd'};
      final counted = [
        session(3, attendees: ['a', 'b', 'c', 'd']),
        session(1, attendees: ['a', 'b', 'gone']),
      ];
      expect(Attendance.sessionRate(counted.last, members), .5);
      expect(Attendance.groupRate(counted, members), .75);
      expect(Attendance.studentRate('c', counted), .5);
      expect(Attendance.groupRate(const [], members), isNull);
      expect(Attendance.studentRate('a', const []), isNull);
      expect(Attendance.sessionRate(counted.first, const {}), isNull);
    });

    test('finds the sessions missed in a row at the end', () {
      final counted = [
        session(9, attendees: ['a']),
        session(7, attendees: []),
        session(5, attendees: ['a']),
        session(3, attendees: []),
        session(1, attendees: ['b']),
      ];
      expect(Attendance.missedStreak('a', counted).map((s) => s.id), ['s3', 's1']);
      expect(Attendance.missedStreak('b', counted), isEmpty);
      expect(percent(2 / 3), 67);
    });
  });

  group('QuizAverages', () {
    final quizzes = {
      'q1': Quiz(id: 'q1', title: 'Loops', opensAt: now, closesAt: now, totalPoints: 10),
      'q2': Quiz(id: 'q2', title: 'Arrays', opensAt: now, closesAt: now, totalPoints: 4),
    };
    BoardEntry entry(String uid, int score) =>
        BoardEntry(uid: uid, name: uid, score: score, correctCount: score, durationMs: 1000);
    final boards = [
      QuizBoard(groupId: 'g', quizId: 'q1', entries: [entry('a', 8), entry('b', 4)]),
      QuizBoard(groupId: 'g', quizId: 'q2', entries: [entry('a', 2)]),
      QuizBoard(groupId: 'g', quizId: 'unknown', entries: [entry('a', 9)]),
    ];

    test('averages a group and a student, skipping quizzes it can not score', () {
      expect(QuizAverages.group(boards, quizzes), closeTo((.8 + .4 + .5) / 3, 1e-9));
      expect(QuizAverages.student('a', boards, quizzes), closeTo(.65, 1e-9));
      expect(QuizAverages.student('nobody', boards, quizzes), isNull);
      expect(QuizAverages.submissions(boards), 4);
    });
  });
}
