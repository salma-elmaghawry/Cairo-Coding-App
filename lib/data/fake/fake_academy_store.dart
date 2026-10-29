import 'dart:async';

import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/models/weekly_slot.dart';
import 'package:cairo_coding_app/data/services/session_generator.dart';

class FakeAcademyStore {
  FakeAcademyStore({DateTime? now}) {
    _seed(now ?? DateTime.now());
  }

  static const String demoStudentEmail = 'mariam.adel@example.com';
  static const String demoAdminEmail = 'admin@cairocoding.school';

  static const List<String> cppSessions = [
    'Intro To Programming & Datatypes',
    'Operators In C++',
    'Conditions In C++',
    'Loops In C++',
    'Array & String In C++',
    'Function In C++',
    'Pointer & Dynamic Allocation In C++',
    'Struct In C++ & Project XO',
    'OOP (Encapsulation)',
    'OOP (Inheritance)',
    'OOP (Polymorphism)',
    'OOP (Abstract) & SOLID',
    'Time Complexity & Algorithm Searching',
    'Sorting Algorithm',
    'Intro to DS & Linked List',
    'Stack & Queue',
    'Trees & Graph & Hash Table',
    'Intro To Database',
    'Intro To SQL',
    'Intro To Design Pattern',
    'Intro To Unit Testing',
    'File Handling & Exception Handling',
  ];

  final Map<String, AcademyGroup> groups = {};
  final Map<String, ClassSession> sessions = {};
  final Map<String, Recording> recordings = {};
  final Map<String, Student> students = {};
  final Map<String, Instructor> instructors = {};
  final Map<String, Course> courses = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  String newId(String prefix) => '${prefix}_${_nextId++}';

  void notify() => _changes.add(null);

  Stream<T> watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  Student? studentByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final student in students.values) {
      if (student.email.toLowerCase() == normalized) return student;
    }
    return null;
  }

  void _seed(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime daysFrom(int days) => DateTime(today.year, today.month, today.day + days);

    const salma = Instructor(
      id: 'instructor_salma',
      name: 'Eng. Salma Elmaghawry',
      email: 'salma@example.com',
      phone: '010 2222 3141',
      groupIds: ['cs140', 'cs150', 'cs120'],
    );
    const youssef = Instructor(
      id: 'instructor_youssef',
      name: 'Eng. Youssef Nabil',
      email: 'youssef@example.com',
      phone: '011 5555 2718',
      groupIds: ['workshop'],
    );
    for (final instructor in [salma, youssef]) {
      instructors[instructor.id] = instructor;
    }
    final seededCourses = [
      Course(id: 'cpp', name: 'C++', sessionTitles: cppSessions, instructorIds: [salma.id]),
      Course(
        id: 'tools',
        name: 'Tools and setup',
        sessionTitles: const ['Setting up VS Code', 'Git basics', 'Debugging', 'Clean code'],
        instructorIds: [youssef.id],
      ),
    ];
    for (final course in seededCourses) {
      courses[course.id] = course;
    }

    final seededGroups = [
      AcademyGroup(
        id: 'cs140',
        name: 'CS140',
        courseId: 'cpp',
        meetingLink: 'https://meet.google.com/',
        location: 'Online · Google Meet',
        startDate: daysFrom(-24),
        endDate: daysFrom(70),
        weeklySlots: const [
          WeeklySlot(weekday: DateTime.sunday, hour: 19, minute: 0, durationMin: 120),
          WeeklySlot(weekday: DateTime.thursday, hour: 19, minute: 0, durationMin: 120),
        ],
      ),
      AcademyGroup(
        id: 'cs150',
        name: 'CS150',
        courseId: 'cpp',
        meetingLink: 'https://meet.google.com/',
        location: 'Online · Google Meet',
        startDate: daysFrom(-5),
        endDate: daysFrom(90),
        weeklySlots: const [
          WeeklySlot(weekday: DateTime.monday, hour: 18, minute: 0, durationMin: 120),
          WeeklySlot(weekday: DateTime.wednesday, hour: 18, minute: 0, durationMin: 120),
        ],
      ),
      AcademyGroup(
        id: 'workshop',
        name: 'Workshop',
        courseId: 'tools',
        meetingLink: 'https://meet.google.com/',
        location: 'Online · Google Meet',
        startDate: daysFrom(-20),
        endDate: daysFrom(20),
        weeklySlots: const [WeeklySlot(weekday: DateTime.monday, hour: 19, minute: 0, durationMin: 90)],
      ),
      AcademyGroup(
        id: 'cs120',
        name: 'CS120',
        courseId: 'cpp',
        meetingLink: 'https://meet.google.com/',
        location: 'Online · Google Meet',
        startDate: daysFrom(-150),
        endDate: daysFrom(-60),
        weeklySlots: const [
          WeeklySlot(weekday: DateTime.saturday, hour: 18, minute: 0, durationMin: 120),
          WeeklySlot(weekday: DateTime.tuesday, hour: 18, minute: 0, durationMin: 120),
        ],
        archived: true,
      ),
    ];
    for (final group in seededGroups) {
      groups[group.id] = group;
      for (final session in const SessionGenerator().generate(group: group, from: group.startDate)) {
        sessions[session.id] = session;
      }
    }

    final upcoming = sessions.values.where((s) => s.groupId == 'cs140' && s.startsAt.isAfter(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    if (upcoming.length > 4) {
      final moved = upcoming[2];
      sessions[moved.id] = moved.copyWith(
        startsAt: moved.startsAt.add(const Duration(hours: 1)),
        status: SessionStatus.moved,
      );
      final cancelled = upcoming[3];
      sessions[cancelled.id] = cancelled.copyWith(status: SessionStatus.cancelled);
      final extraId = newId('session');
      sessions[extraId] = ClassSession(
        id: extraId,
        groupId: 'cs140',
        startsAt: cancelled.startsAt.add(const Duration(days: 1)),
        durationMin: 120,
        status: SessionStatus.extra,
      );
    }

    // Groups that are teaching in the demo, with how many of their past sessions have a recording.
    const recordedByGroup = {'cs140': 8, 'workshop': 3};
    final instructorByCourse = {'cpp': salma.name, 'tools': youssef.name};
    for (final session in sessions.values.toList()) {
      if (!recordedByGroup.containsKey(session.groupId)) continue;
      final courseId = groups[session.groupId]!.courseId;
      final topic = courses[courseId]!.titleOf(session.number);
      if (topic == null) continue;
      sessions[session.id] = session.copyWith(topic: topic, instructor: instructorByCourse[courseId]);
    }
    for (final session in sessions.values.where((s) => s.isPast(now)).toList()) {
      final number = session.number ?? 0;
      if (session.topic.isEmpty || number > (recordedByGroup[session.groupId] ?? 0)) continue;
      final id = newId('recording');
      recordings[id] = Recording(
        id: id,
        groupId: session.groupId,
        title: session.topic,
        sessionNumber: number,
        url: 'https://www.youtube.com/',
        recordedAt: session.startsAt,
      );
    }

    const people = [
      ('Mariam Adel', demoStudentEmail, '010 1234 4821', ['cs140', 'workshop'], true),
      ('Omar Khaled', 'omar.k@example.com', '011 2345 1930', ['cs140'], true),
      ('Nour Hassan', 'nour.h@example.com', '012 3456 7714', ['cs140', 'workshop'], true),
      ('Youssef Samir', 'youssef.s@example.com', '010 4567 0562', ['cs140'], true),
      ('Farida Mostafa', 'farida.m@example.com', '015 5678 3348', ['cs140'], true),
      ('Karim Ashraf', 'karim.a@example.com', '011 6789 8201', ['cs140'], false),
      ('Salma Tarek', 'salma.t@example.com', '010 7890 1188', ['cs150'], true),
      ('Ahmed Fathy', 'ahmed.f@example.com', '012 8901 6630', ['cs150', 'workshop'], true),
      ('Hana Ibrahim', 'hana.i@example.com', '015 9012 4402', ['cs150'], true),
      ('Ziad Mahmoud', 'ziad.m@example.com', '011 0123 9975', ['workshop'], true),
    ];
    for (final (name, email, phone, groupIds, active) in people) {
      final uid = newId('user');
      students[uid] = Student(uid: uid, name: name, email: email, phone: phone, groupIds: groupIds, active: active);
    }
  }
}
