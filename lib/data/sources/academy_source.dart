import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/announcement.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/data/models/student.dart';

abstract class AcademySource {
  Stream<List<AcademyGroup>> watchGroups({List<String>? ids});

  Stream<List<ClassSession>> watchSessions(List<String> groupIds);

  Stream<List<Recording>> watchRecordings(List<String> groupIds);

  Stream<List<Student>> watchStudents(String groupId);

  Stream<List<Student>> watchAllStudents();

  Future<List<ClassSession>> getSessions(String groupId);

  Future<List<ClassSession>> getSessionsBetween(List<String> groupIds, DateTime from, DateTime until);

  Future<AcademyGroup> saveGroup(AcademyGroup group);

  Future<void> saveSessions(List<ClassSession> sessions);

  Future<void> deleteSessions(String groupId, List<String> sessionIds);

  Future<Recording> saveRecording(Recording recording);

  Future<void> deleteRecording(Recording recording);

  Future<AddStudentsResult> addStudentsToGroup(String groupId, List<NewStudent> students);

  Future<void> removeStudentFromGroup(String uid, String groupId);

  Future<void> setStudentActive(String uid, bool active);

  /// Saves what an admin can change on [student]; the sign-in email stays as it is.
  Future<void> updateStudent(Student student);

  Stream<List<Instructor>> watchInstructors();

  Future<Instructor> saveInstructor(Instructor instructor);

  Future<void> deleteInstructor(String id);

  /// Puts [to] on every session that names [from] as its instructor.
  Future<void> renameSessionInstructor(String from, String to);

  Stream<List<Course>> watchCourses();

  Future<Course> saveCourse(Course course);

  Future<void> deleteCourse(String id);

  /// Adds [uid] to the session's attendees. The rules let a student add only themselves, and only while
  /// the session runs (from 30 minutes before it starts).
  Future<void> markAttended(String groupId, String sessionId, String uid);

  /// Replaces who attended, for the admin taking or correcting attendance.
  Future<void> setAttendance(String groupId, String sessionId, List<String> uids);

  /// Adds [uid] to the students who opened the recording.
  Future<void> markViewed(String groupId, String recordingId, String uid);

  /// Stamps the student's profile with the server's time, so the dashboard can tell who signed in.
  Future<void> touchLastSeen(String uid);

  /// Each group keeps its own copy of an announcement, so the same one can come back once per group.
  Stream<List<Announcement>> watchAnnouncements(List<String> groupIds);

  /// Writes one copy per group, all with the same id.
  Future<Announcement> saveAnnouncement(Announcement announcement);

  Future<void> deleteAnnouncement(Announcement announcement);
}
