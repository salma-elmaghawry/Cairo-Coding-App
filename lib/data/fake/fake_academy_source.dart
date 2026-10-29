import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/sources/academy_source.dart';

class FakeAcademySource implements AcademySource {
  FakeAcademySource(this._store);

  final FakeAcademyStore _store;

  Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 350));

  Future<T> _write<T>(T Function() change) async {
    await _latency();
    final result = change();
    _store.notify();
    return result;
  }

  @override
  Stream<List<AcademyGroup>> watchGroups({List<String>? ids}) =>
      _store.watch(() => _store.groups.values.where((g) => ids == null || ids.contains(g.id)).toList());

  @override
  Stream<List<ClassSession>> watchSessions(List<String> groupIds) =>
      _store.watch(() => _store.sessions.values.where((s) => groupIds.contains(s.groupId)).toList());

  @override
  Stream<List<Recording>> watchRecordings(List<String> groupIds) =>
      _store.watch(() => _store.recordings.values.where((r) => groupIds.contains(r.groupId)).toList());

  @override
  Stream<List<Student>> watchStudents(String groupId) =>
      _store.watch(() => _store.students.values.where((s) => s.groupIds.contains(groupId)).toList());

  @override
  Stream<List<Student>> watchAllStudents() => _store.watch(() => _store.students.values.toList());

  @override
  Future<List<ClassSession>> getSessions(String groupId) async {
    await _latency();
    return _store.sessions.values.where((s) => s.groupId == groupId).toList();
  }

  @override
  Future<List<ClassSession>> getSessionsBetween(List<String> groupIds, DateTime from, DateTime until) async {
    await _latency();
    return _store.sessions.values
        .where((s) => groupIds.contains(s.groupId) && !s.startsAt.isBefore(from) && s.startsAt.isBefore(until))
        .toList();
  }

  @override
  Future<AcademyGroup> saveGroup(AcademyGroup group) => _write(() {
    final saved = group.id.isEmpty ? group.copyWith(id: _store.newId('group')) : group;
    _store.groups[saved.id] = saved;
    return saved;
  });

  @override
  Future<void> saveSessions(List<ClassSession> sessions) => _write(() {
    for (final session in sessions) {
      final saved = session.id.isEmpty ? session.copyWith(id: _store.newId('session')) : session;
      _store.sessions[saved.id] = saved;
    }
  });

  @override
  Future<void> deleteSessions(String groupId, List<String> sessionIds) =>
      _write(() => sessionIds.forEach(_store.sessions.remove));

  @override
  Future<Recording> saveRecording(Recording recording) => _write(() {
    final saved = recording.id.isEmpty ? recording.copyWith(id: _store.newId('recording')) : recording;
    _store.recordings[saved.id] = saved;
    return saved;
  });

  @override
  Future<void> deleteRecording(Recording recording) => _write(() => _store.recordings.remove(recording.id));

  @override
  Future<AddStudentsResult> addStudentsToGroup(String groupId, List<NewStudent> students) => _write(() {
    var created = 0;
    var linked = 0;
    for (final newStudent in students) {
      final existing = _store.studentByEmail(newStudent.email);
      if (existing != null) {
        if (!existing.groupIds.contains(groupId)) {
          _store.students[existing.uid] = existing.copyWith(groupIds: [...existing.groupIds, groupId]);
          linked++;
        }
        continue;
      }
      final uid = _store.newId('user');
      final email = newStudent.email.trim().toLowerCase();
      _store.students[uid] = Student(
        uid: uid,
        name: newStudent.name.isEmpty ? email.split('@').first : newStudent.name,
        email: email,
        phone: newStudent.phone,
        groupIds: [groupId],
        active: true,
      );
      created++;
    }
    return AddStudentsResult(created: created, linked: linked);
  });

  @override
  Future<void> removeStudentFromGroup(String uid, String groupId) => _write(() {
    final student = _store.students[uid];
    if (student == null) return;
    _store.students[uid] = student.copyWith(groupIds: student.groupIds.where((id) => id != groupId).toList());
  });

  @override
  Future<void> setStudentActive(String uid, bool active) => _write(() {
    final student = _store.students[uid];
    if (student == null) return;
    _store.students[uid] = student.copyWith(active: active);
  });

  @override
  Stream<List<Instructor>> watchInstructors() => _store.watch(() => _store.instructors.values.toList());

  @override
  Future<Instructor> saveInstructor(Instructor instructor) => _write(() {
    final saved = instructor.id.isEmpty ? instructor.copyWith(id: _store.newId('instructor')) : instructor;
    _store.instructors[saved.id] = saved;
    return saved;
  });

  @override
  Future<void> deleteInstructor(String id) => _write(() => _store.instructors.remove(id));

  @override
  Stream<List<Course>> watchCourses() => _store.watch(() => _store.courses.values.toList());

  @override
  Future<Course> saveCourse(Course course) => _write(() {
    final saved = course.id.isEmpty ? course.copyWith(id: _store.newId('course')) : course;
    _store.courses[saved.id] = saved;
    return saved;
  });

  @override
  Future<void> deleteCourse(String id) => _write(() => _store.courses.remove(id));
}
