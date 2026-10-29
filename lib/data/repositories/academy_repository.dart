import 'package:cairo_coding_app/core/error_handling/error_mapper.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/utils/stream_utils.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/course.dart';
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

  Stream<List<Student>> watchAllStudents() => ErrorMapper.mapStream(
    _source.watchAllStudents().map((list) => [...list]..sort((a, b) => a.name.compareTo(b.name))),
  );

  /// Students of several groups, each listed once.
  Stream<List<Student>> watchStudentsOf(List<String> groupIds) => ErrorMapper.mapStream(
    combineLatestLists([for (final groupId in groupIds) _source.watchStudents(groupId)]).map(
      (list) =>
          {for (final student in list) student.uid: student}.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
    ),
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

  Future<Result<Instructor>> addInstructor(String name, {String email = '', String phone = ''}) => Result.guard(
    () => _source.saveInstructor(
      Instructor(id: '', name: name.trim(), email: email.trim().toLowerCase(), phone: phone.trim()),
    ),
  );

  /// Saves [instructor] and adds them to or removes them from [courses] so they teach exactly [courseIds].
  /// A new name replaces the old one on every session that carries it.
  Future<Result<void>> updateInstructor(
    Instructor previous,
    Instructor instructor, {
    required List<Course> courses,
    required Set<String> courseIds,
  }) => Result.guard(() async {
    final saved = await _source.saveInstructor(
      instructor.copyWith(
        name: instructor.name.trim(),
        email: instructor.email.trim().toLowerCase(),
        phone: instructor.phone.trim(),
      ),
    );
    for (final course in courses) {
      final teaches = course.instructorIds.contains(saved.id);
      if (teaches == courseIds.contains(course.id)) continue;
      await _source.saveCourse(
        course.copyWith(
          instructorIds: teaches
              ? course.instructorIds.where((id) => id != saved.id).toList()
              : [...course.instructorIds, saved.id],
        ),
      );
    }
    if (saved.name != previous.name) await _source.renameSessionInstructor(previous.name, saved.name);
  });

  Future<Result<void>> deleteInstructor(Instructor instructor) =>
      Result.guard(() => _source.deleteInstructor(instructor.id));

  Stream<List<Course>> watchCourses() => ErrorMapper.mapStream(
    _source.watchCourses().map(
      (list) => [...list]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    ),
  );

  Future<Result<Course>> saveCourse(Course course) => Result.guard(
    () => _source.saveCourse(
      course.copyWith(
        name: course.name.trim(),
        sessionTitles: [
          for (final title in course.sessionTitles)
            if (title.trim().isNotEmpty) title.trim(),
        ],
      ),
    ),
  );

  Future<Result<void>> deleteCourse(Course course) => Result.guard(() => _source.deleteCourse(course.id));

  Future<Result<void>> setCourseInstructors(Course course, List<String> instructorIds) =>
      Result.guard(() => _source.saveCourse(course.copyWith(instructorIds: instructorIds)));

  Future<Result<void>> addSession(
    AcademyGroup group, {
    required String topic,
    required int number,
    required DateTime startsAt,
    required String instructor,
    required String meetingLink,
  }) => Result.guard(
    () => _source.saveSessions([
      ClassSession(
        id: '',
        groupId: group.id,
        number: number,
        startsAt: startsAt,
        durationMin: group.weeklySlots.firstOrNull?.durationMin ?? 120,
        topic: topic.trim(),
        instructor: instructor.trim(),
        meetingLinkOverride: meetingLink.trim(),
        manual: true,
      ),
    ]),
  );

  Future<Result<void>> updateSession(
    ClassSession session, {
    required String topic,
    required int number,
    required DateTime startsAt,
    required String instructor,
    required String meetingLink,
  }) {
    // Same as Reschedule: a generated session that changes time is marked moved, so regenerating keeps it.
    final moved = startsAt != session.startsAt && session.status == SessionStatus.scheduled && !session.manual;
    return Result.guard(
      () => _source.saveSessions([
        session.copyWith(
          topic: topic.trim(),
          number: number,
          startsAt: startsAt,
          instructor: instructor.trim(),
          meetingLinkOverride: meetingLink.trim(),
          status: moved ? SessionStatus.moved : null,
        ),
      ]),
    );
  }

  Future<Result<void>> setSessionStatus(ClassSession session, SessionStatus status) =>
      Result.guard(() => _source.saveSessions([session.copyWith(status: status)]));

  Future<Result<void>> deleteSession(ClassSession session) =>
      Result.guard(() => _source.deleteSessions(session.groupId, [session.id]));

  Future<Result<void>> reschedule(ClassSession session, DateTime startsAt) =>
      Result.guard(() => _source.saveSessions([session.copyWith(startsAt: startsAt, status: SessionStatus.moved)]));

  /// A new session that doesn't inherit a name gets the one [course] plans for its number.
  Future<Result<int>> saveSlotsAndGenerate(AcademyGroup group, List<WeeklySlot> slots, {Course? course}) =>
      Result.guard(() async {
        final updated = group.copyWith(weeklySlots: slots);
        await _source.saveGroup(updated);

        final now = _clock();
        final existing = await _source.getSessions(group.id);
        final replaceable = existing
            .where((s) => !s.isPast(now) && s.status == SessionStatus.scheduled && !s.manual)
            .toList();
        final kept = existing.where((s) => !replaceable.contains(s));
        final lastNumber = kept.map((s) => s.number ?? 0).fold<int>(0, (max, n) => n > max ? n : max);
        final from = now.isAfter(group.startDate) ? now : group.startDate;
        // Topics follow the course order, so the n-th replaced session hands its topic to the n-th new one.
        replaceable.sort((a, b) => a.startsAt.compareTo(b.startsAt));
        final generated = [
          for (final (index, session)
              in const SessionGenerator().generate(group: updated, from: from, firstNumber: lastNumber + 1).indexed)
            () {
              final replaced = index < replaceable.length ? replaceable[index] : null;
              final topic = replaced?.topic ?? '';
              return session.copyWith(
                topic: topic.isNotEmpty ? topic : course?.titleOf(session.number) ?? '',
                instructor: replaced?.instructor,
                meetingLinkOverride: replaced?.meetingLinkOverride,
              );
            }(),
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
