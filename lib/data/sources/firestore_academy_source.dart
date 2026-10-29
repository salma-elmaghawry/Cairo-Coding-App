import 'dart:math';

import 'package:cairo_coding_app/core/utils/stream_utils.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/sources/academy_source.dart';
import 'package:cairo_coding_app/data/sources/firestore_mapping.dart';
import 'package:cairo_coding_app/data/sources/firestore_paths.dart';
import 'package:cairo_coding_app/data/sources/student_account_creator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreAcademySource implements AcademySource {
  FirestoreAcademySource(this._db, this._accountCreator);

  final FirebaseFirestore _db;
  final StudentAccountCreator _accountCreator;

  CollectionReference<Map<String, dynamic>> get _groups => _db.collection(FirestorePaths.groups);
  CollectionReference<Map<String, dynamic>> get _users => _db.collection(FirestorePaths.users);
  CollectionReference<Map<String, dynamic>> get _instructors => _db.collection(FirestorePaths.instructors);
  CollectionReference<Map<String, dynamic>> get _courses => _db.collection(FirestorePaths.courses);
  CollectionReference<Map<String, dynamic>> _sessionsOf(String groupId) =>
      _groups.doc(groupId).collection(FirestorePaths.sessions);
  CollectionReference<Map<String, dynamic>> _recordingsOf(String groupId) =>
      _groups.doc(groupId).collection(FirestorePaths.recordings);

  List<T> _map<T>(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    T Function(String id, Map<String, dynamic> data) build,
  ) => snapshot.docs.map((doc) => build(doc.id, fromFirestore(doc.data()))).toList();

  @override
  Stream<List<AcademyGroup>> watchGroups({List<String>? ids}) {
    if (ids == null) return _groups.snapshots().map((s) => _map(s, AcademyGroup.fromMap));
    return combineLatestLists([
      for (final id in ids)
        _groups.doc(id).snapshots().map((doc) {
          final data = doc.data();
          return data == null ? <AcademyGroup>[] : [AcademyGroup.fromMap(doc.id, fromFirestore(data))];
        }),
    ]);
  }

  @override
  Stream<List<ClassSession>> watchSessions(List<String> groupIds) => combineLatestLists([
    for (final groupId in groupIds) _sessionsOf(groupId).snapshots().map((s) => _map(s, ClassSession.fromMap)),
  ]);

  @override
  Stream<List<Recording>> watchRecordings(List<String> groupIds) => combineLatestLists([
    for (final groupId in groupIds) _recordingsOf(groupId).snapshots().map((s) => _map(s, Recording.fromMap)),
  ]);

  @override
  Stream<List<Student>> watchStudents(String groupId) =>
      _users.where('groupIds', arrayContains: groupId).snapshots().map((s) => _map(s, Student.fromMap));

  @override
  Future<List<ClassSession>> getSessions(String groupId) async =>
      _map(await _sessionsOf(groupId).get(), ClassSession.fromMap);

  @override
  Future<List<ClassSession>> getSessionsBetween(List<String> groupIds, DateTime from, DateTime until) async {
    final snapshots = await Future.wait([
      for (final groupId in groupIds)
        _sessionsOf(groupId)
            .where('startsAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
            .where('startsAt', isLessThan: Timestamp.fromDate(until))
            .get(),
    ]);
    return [for (final snapshot in snapshots) ..._map(snapshot, ClassSession.fromMap)];
  }

  @override
  Future<AcademyGroup> saveGroup(AcademyGroup group) async {
    final doc = group.id.isEmpty ? _groups.doc() : _groups.doc(group.id);
    await doc.set(toFirestore(group.toMap()));
    return group.copyWith(id: doc.id);
  }

  @override
  Future<void> saveSessions(List<ClassSession> sessions) async {
    for (var i = 0; i < sessions.length; i += 450) {
      final batch = _db.batch();
      for (final session in sessions.sublist(i, min(i + 450, sessions.length))) {
        final collection = _sessionsOf(session.groupId);
        final doc = session.id.isEmpty ? collection.doc() : collection.doc(session.id);
        batch.set(doc, {...toFirestore(session.toMap()), 'updatedAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> deleteSessions(String groupId, List<String> sessionIds) async {
    for (var i = 0; i < sessionIds.length; i += 450) {
      final batch = _db.batch();
      for (final id in sessionIds.sublist(i, min(i + 450, sessionIds.length))) {
        batch.delete(_sessionsOf(groupId).doc(id));
      }
      await batch.commit();
    }
  }

  @override
  Future<Recording> saveRecording(Recording recording) async {
    final collection = _recordingsOf(recording.groupId);
    final doc = recording.id.isEmpty ? collection.doc() : collection.doc(recording.id);
    await doc.set({
      ...toFirestore(recording.toMap()),
      if (recording.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return recording.copyWith(id: doc.id);
  }

  @override
  Future<void> deleteRecording(Recording recording) => _recordingsOf(recording.groupId).doc(recording.id).delete();

  @override
  Future<AddStudentsResult> addStudentsToGroup(String groupId, List<NewStudent> students) async {
    var created = 0;
    var linked = 0;
    final skipped = <String>[];
    for (final student in students) {
      final email = student.email.trim().toLowerCase();
      final existing = await _users.where('email', isEqualTo: email).limit(1).get();
      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final groupIds = List<String>.from(doc.data()['groupIds'] as List? ?? const []);
        if (!groupIds.contains(groupId)) {
          await doc.reference.update({
            'groupIds': FieldValue.arrayUnion([groupId]),
          });
          linked++;
        }
        continue;
      }
      final uid = await _accountCreator.createAccount(email);
      if (uid == null) {
        skipped.add(email);
        continue;
      }
      await _users.doc(uid).set({
        ...Student(
          uid: uid,
          name: student.name.isEmpty ? email.split('@').first : student.name,
          email: email,
          phone: student.phone,
          groupIds: [groupId],
          active: true,
        ).toMap(),
        'locale': 'ar',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _accountCreator.sendWelcomeEmail(email);
      created++;
    }
    return AddStudentsResult(created: created, linked: linked, skipped: skipped);
  }

  @override
  Future<void> removeStudentFromGroup(String uid, String groupId) => _users.doc(uid).update({
    'groupIds': FieldValue.arrayRemove([groupId]),
  });

  @override
  Future<void> setStudentActive(String uid, bool active) => _users.doc(uid).update({'active': active});

  @override
  Stream<List<Instructor>> watchInstructors() => _instructors.snapshots().map((s) => _map(s, Instructor.fromMap));

  @override
  Future<Instructor> saveInstructor(Instructor instructor) async {
    final doc = instructor.id.isEmpty ? _instructors.doc() : _instructors.doc(instructor.id);
    await doc.set(instructor.toMap());
    return instructor.copyWith(id: doc.id);
  }

  @override
  Future<void> deleteInstructor(String id) => _instructors.doc(id).delete();

  @override
  Stream<List<Course>> watchCourses() => _courses.snapshots().map((s) => _map(s, Course.fromMap));

  @override
  Future<Course> saveCourse(Course course) async {
    final doc = course.id.isEmpty ? _courses.doc() : _courses.doc(course.id);
    await doc.set(course.toMap());
    return course.copyWith(id: doc.id);
  }

  @override
  Future<void> deleteCourse(String id) => _courses.doc(id).delete();
}
