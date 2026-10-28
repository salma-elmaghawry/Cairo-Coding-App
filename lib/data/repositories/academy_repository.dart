import 'package:cairo_coding_app/core/error_handling/error_mapper.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/models/weekly_slot.dart';
import 'package:cairo_coding_app/data/services/session_generator.dart';
import 'package:cairo_coding_app/data/sources/academy_source.dart';

class AcademyRepository {
  AcademyRepository(this._source, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AcademySource _source;
  final DateTime Function() _clock;

  Stream<List<AcademyGroup>> watchGroups({List<String>? ids}) => ErrorMapper.mapStream(
    _source.watchGroups(ids: ids).map((groups) => [...groups]..sort((a, b) => a.name.compareTo(b.name))),
  );

  Stream<List<ClassSession>> watchSessions(List<String> groupIds) => ErrorMapper.mapStream(
    _source.watchSessions(groupIds).map((list) => [...list]..sort((a, b) => a.startsAt.compareTo(b.startsAt))),
  );

  Stream<List<Recording>> watchRecordings(List<String> groupIds) => ErrorMapper.mapStream(
    _source.watchRecordings(groupIds).map((list) => [...list]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt))),
  );

  Stream<List<Student>> watchStudents(String groupId) => ErrorMapper.mapStream(
    _source.watchStudents(groupId).map((list) => [...list]..sort((a, b) => a.name.compareTo(b.name))),
  );

  Future<Result<List<ClassSession>>> sessionsBetween(List<String> groupIds, DateTime from, DateTime until) =>
      Result.guard(() => _source.getSessionsBetween(groupIds, from, until));

  Future<Result<AcademyGroup>> saveGroup(AcademyGroup group) => Result.guard(() => _source.saveGroup(group));

  Future<Result<void>> setArchived(AcademyGroup group, bool archived) =>
      Result.guard(() => _source.saveGroup(group.copyWith(archived: archived)));

  Stream<List<Instructor>> watchInstructors() => ErrorMapper.mapStream(
    _source.watchInstructors().map(
      (list) => [...list]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    ),
  );

  Future<Result<Instructor>> addInstructor(String name) =>
      Result.guard(() => _source.saveInstructor(Instructor(id: '', name: name.trim())));

  Future<Result<void>> deleteInstructor(Instructor instructor) =>
      Result.guard(() => _source.deleteInstructor(instructor.id));

  Future<Result<void>> updateSessionDetails(
    ClassSession session, {
    required String topic,
    required String instructor,
  }) =>
      Result.guard(() => _source.saveSessions([session.copyWith(topic: topic.trim(), instructor: instructor.trim())]));

  Future<Result<void>> setSessionStatus(ClassSession session, SessionStatus status) =>
      Result.guard(() => _source.saveSessions([session.copyWith(status: status)]));

  Future<Result<void>> reschedule(ClassSession session, DateTime startsAt) =>
      Result.guard(() => _source.saveSessions([session.copyWith(startsAt: startsAt, status: SessionStatus.moved)]));

  Future<Result<void>> addExtraSession(AcademyGroup group, DateTime startsAt, int durationMin) => Result.guard(
    () => _source.saveSessions([
      ClassSession(
        id: '',
        groupId: group.id,
        startsAt: startsAt,
        durationMin: durationMin,
        status: SessionStatus.extra,
      ),
    ]),
  );

  Future<Result<int>> saveSlotsAndGenerate(AcademyGroup group, List<WeeklySlot> slots) => Result.guard(() async {
    final updated = group.copyWith(weeklySlots: slots);
    await _source.saveGroup(updated);

    final now = _clock();
    final existing = await _source.getSessions(group.id);
    final replaceable = existing.where((s) => !s.isPast(now) && s.status == SessionStatus.scheduled).toList();
    final kept = existing.where((s) => !replaceable.contains(s));
    final lastNumber = kept.map((s) => s.number ?? 0).fold<int>(0, (max, n) => n > max ? n : max);
    final from = now.isAfter(group.startDate) ? now : group.startDate;
    // Topics follow the course order, so the n-th replaced session hands its topic to the n-th new one.
    replaceable.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final generated = [
      for (final (index, session)
          in const SessionGenerator().generate(group: updated, from: from, firstNumber: lastNumber + 1).indexed)
        index < replaceable.length
            ? session.copyWith(topic: replaceable[index].topic, instructor: replaceable[index].instructor)
            : session,
    ];

    await _source.deleteSessions(group.id, replaceable.map((s) => s.id).toList());
    await _source.saveSessions(generated);
    return generated.length;
  });

  Future<Result<Recording>> saveRecording(Recording recording) => Result.guard(() => _source.saveRecording(recording));

  Future<Result<void>> deleteRecording(Recording recording) => Result.guard(() => _source.deleteRecording(recording));

  Future<Result<AddStudentsResult>> addStudents(String groupId, List<NewStudent> students) =>
      Result.guard(() => _source.addStudentsToGroup(groupId, students));

  Future<Result<void>> removeStudentFromGroup(String uid, String groupId) =>
      Result.guard(() => _source.removeStudentFromGroup(uid, groupId));

  Future<Result<void>> setStudentActive(String uid, bool active) =>
      Result.guard(() => _source.setStudentActive(uid, active));
}
