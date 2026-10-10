import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/data/models/student.dart';

abstract class AcademySource {
  Stream<List<AcademyGroup>> watchGroups({List<String>? ids});

  Stream<List<ClassSession>> watchSessions(List<String> groupIds);

  Stream<List<Recording>> watchRecordings(List<String> groupIds);

  Stream<List<Student>> watchStudents(String groupId);

  Future<List<ClassSession>> getSessions(String groupId);

  Future<AcademyGroup> saveGroup(AcademyGroup group);

  Future<void> saveSessions(List<ClassSession> sessions);

  Future<void> deleteSessions(String groupId, List<String> sessionIds);

  Future<Recording> saveRecording(Recording recording);

  Future<void> deleteRecording(Recording recording);

  Future<AddStudentsResult> addStudentsToGroup(String groupId, List<NewStudent> students);

  Future<void> removeStudentFromGroup(String uid, String groupId);

  Future<void> setStudentActive(String uid, bool active);
}
