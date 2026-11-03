import 'dart:math';

import 'package:cairo_coding_app/core/utils/stream_utils.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/sources/firestore_mapping.dart';
import 'package:cairo_coding_app/data/sources/firestore_paths.dart';
import 'package:cairo_coding_app/data/sources/quiz_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreQuizSource implements QuizSource {
  FirestoreQuizSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _quizzes => _db.collection(FirestorePaths.quizzes);
  CollectionReference<Map<String, dynamic>> get _attempts => _db.collection(FirestorePaths.quizAttempts);
  DocumentReference<Map<String, dynamic>> _paper(String quizId) =>
      _quizzes.doc(quizId).collection(FirestorePaths.quizContent).doc(FirestorePaths.quizPaper);
  DocumentReference<Map<String, dynamic>> _key(String quizId) =>
      _quizzes.doc(quizId).collection(FirestorePaths.quizContent).doc(FirestorePaths.quizKey);
  CollectionReference<Map<String, dynamic>> _publishedIn(String groupId) =>
      _db.collection(FirestorePaths.groups).doc(groupId).collection(FirestorePaths.quizzes);
  CollectionReference<Map<String, dynamic>> _boardsOf(String groupId) =>
      _db.collection(FirestorePaths.groups).doc(groupId).collection(FirestorePaths.quizBoards);

  List<Quiz> _quizList(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((doc) => Quiz.fromMap(doc.id, fromFirestore(doc.data()))).toList();

  List<QuizAttempt> _attemptList(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((doc) => QuizAttempt.fromMap(fromFirestore(doc.data()))).toList();

  List<QuizQuestion> _questionsOf(Map<String, dynamic>? data) => (data?['questions'] as List? ?? const [])
      .map((question) => QuizQuestion.fromMap(Map<String, dynamic>.from(question as Map)))
      .toList();

  @override
  Stream<List<Quiz>> watchPublishedQuizzes(List<String> groupIds) =>
      combineLatestLists([for (final groupId in groupIds) _publishedIn(groupId).snapshots().map(_quizList)]);

  @override
  Future<Quiz?> getPublishedQuiz(String groupId, String quizId) async {
    final doc = await _publishedIn(groupId).doc(quizId).get(const GetOptions(source: Source.server));
    final data = doc.data();
    return data == null ? null : Quiz.fromMap(doc.id, fromFirestore(data));
  }

  @override
  Stream<List<QuizAttempt>> watchAttemptsOf(String uid) =>
      _attempts.where('uid', isEqualTo: uid).snapshots().map(_attemptList);

  @override
  Future<QuizAttempt> startAttempt(QuizAttempt attempt) async {
    final doc = _attempts.doc(attempt.id);
    await doc.set({
      ...toFirestore(attempt.toMap()),
      'startedAt': FieldValue.serverTimestamp(),
      'lastAnswerAt': FieldValue.serverTimestamp(),
    });
    return getAttempt(attempt.id);
  }

  @override
  Future<List<QuizQuestion>> getPaper(String quizId) async => _questionsOf((await _paper(quizId).get()).data());

  @override
  Future<QuizAnswerKey> getKey(String quizId) async =>
      QuizAnswerKey.fromMap((await _key(quizId).get(const GetOptions(source: Source.server))).data() ?? const {});

  @override
  Future<void> saveAnswer(QuizAttempt attempt, String questionId, int option) =>
      _attempts.doc(attempt.id).update({'answers.$questionId': option, 'lastAnswerAt': FieldValue.serverTimestamp()});

  @override
  Future<QuizAttempt> getAttempt(String attemptId) async {
    final doc = await _attempts.doc(attemptId).get(const GetOptions(source: Source.server));
    return QuizAttempt.fromMap(fromFirestore(doc.data()!));
  }

  @override
  Future<void> submitAttempt(String attemptId) => _attempts.doc(attemptId).update({
    'status': AttemptStatus.submitted.name,
    'submittedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> saveGrade(QuizAttempt graded) {
    final batch = _db.batch();
    batch.update(_attempts.doc(graded.id), {
      'status': AttemptStatus.graded.name,
      'score': graded.score,
      'correctCount': graded.correctCount,
    });
    // Only the first attempt ranks, in every group of the student's that the quiz was given to.
    if (graded.number == 1) {
      final entry = BoardEntry.fromAttempt(graded);
      for (final groupId in graded.groupIds) {
        batch.set(_boardsOf(groupId).doc(graded.quizId), {graded.uid: entry.toMap()}, SetOptions(merge: true));
      }
    }
    return batch.commit();
  }

  @override
  Stream<QuizBoard> watchBoard(String groupId, String quizId) => _boardsOf(
    groupId,
  ).doc(quizId).snapshots().map((doc) => QuizBoard.fromMap(groupId, quizId, doc.data() ?? const {}));

  @override
  Stream<List<QuizBoard>> watchBoards(String groupId) => _boardsOf(
    groupId,
  ).snapshots().map((s) => s.docs.map((doc) => QuizBoard.fromMap(groupId, doc.id, doc.data())).toList());

  @override
  Stream<List<Quiz>> watchQuizzes() => _quizzes.snapshots().map(_quizList);

  @override
  Future<QuizContent> getContent(String quizId) async {
    final results = await Future.wait([_paper(quizId).get(), _key(quizId).get()]);
    return QuizContent(
      questions: _questionsOf(results[0].data()),
      key: QuizAnswerKey.fromMap(results[1].data() ?? const {}),
    );
  }

  @override
  Future<Quiz> saveQuiz(Quiz quiz, {QuizContent? content, List<String> removedGroupIds = const []}) async {
    final doc = quiz.id.isEmpty ? _quizzes.doc() : _quizzes.doc(quiz.id);
    final saved = quiz.copyWith(id: doc.id);
    final data = toFirestore(saved.toMap());
    final batch = _db.batch();
    batch.set(doc, data);
    if (content != null) {
      batch.set(_paper(doc.id), {'questions': content.questions.map((q) => q.toMap()).toList()});
      batch.set(_key(doc.id), content.key.toMap());
    }
    for (final groupId in removedGroupIds) {
      batch.delete(_publishedIn(groupId).doc(doc.id));
    }
    for (final groupId in saved.groupIds) {
      final copy = _publishedIn(groupId).doc(doc.id);
      saved.isPublished ? batch.set(copy, data) : batch.delete(copy);
    }
    await batch.commit();
    return saved;
  }

  @override
  Future<void> deleteQuiz(Quiz quiz) async {
    final attempts = await _attempts.where('quizId', isEqualTo: quiz.id).get();
    final groupIds = {
      ...quiz.groupIds,
      for (final doc in attempts.docs) ...List<String>.from(doc.data()['groupIds'] as List? ?? const []),
    };
    final refs = <DocumentReference<Map<String, dynamic>>>[
      for (final doc in attempts.docs) doc.reference,
      for (final groupId in groupIds) ...[_publishedIn(groupId).doc(quiz.id), _boardsOf(groupId).doc(quiz.id)],
      _paper(quiz.id),
      _key(quiz.id),
      _quizzes.doc(quiz.id),
    ];
    for (var i = 0; i < refs.length; i += 450) {
      final batch = _db.batch();
      for (final ref in refs.sublist(i, min(i + 450, refs.length))) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  @override
  Stream<List<QuizAttempt>> watchAttemptsForQuiz(String quizId) =>
      _attempts.where('quizId', isEqualTo: quizId).snapshots().map(_attemptList);

  @override
  Future<bool> hasAttempts(String quizId) async =>
      (await _attempts.where('quizId', isEqualTo: quizId).limit(1).get()).docs.isNotEmpty;
}
