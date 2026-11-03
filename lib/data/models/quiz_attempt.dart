import 'package:equatable/equatable.dart';

enum AttemptStatus { inProgress, submitted, graded }

class QuizAttempt extends Equatable {
  const QuizAttempt({
    required this.quizId,
    required this.uid,
    required this.number,
    required this.studentName,
    required this.groupIds,
    this.status = AttemptStatus.inProgress,
    required this.startedAt,
    required this.lastAnswerAt,
    this.submittedAt,
    required this.durationMin,
    required this.closesAt,
    required this.questionCount,
    this.answers = const {},
    this.score,
    this.correctCount,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    DateTime? date(String field) {
      final millis = map[field] as int?;
      return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
    }

    final answers = Map<String, dynamic>.from(map['answers'] as Map? ?? const {});
    return QuizAttempt(
      quizId: map['quizId'] as String,
      uid: map['uid'] as String,
      number: map['number'] as int,
      studentName: map['studentName'] as String? ?? '',
      groupIds: List<String>.from(map['groupIds'] as List? ?? const []),
      status: AttemptStatus.values.asNameMap()[map['status']] ?? AttemptStatus.inProgress,
      startedAt: date('startedAt') ?? DateTime.now(),
      lastAnswerAt: date('lastAnswerAt') ?? date('startedAt') ?? DateTime.now(),
      submittedAt: date('submittedAt'),
      durationMin: map['durationMin'] as int? ?? 0,
      closesAt: date('closesAt') ?? DateTime.now(),
      questionCount: map['questionCount'] as int? ?? 0,
      // Rules only check that an answer is new, so anything that isn't an option counts as no answer.
      answers: {for (final entry in answers.entries) entry.key: entry.value is int ? entry.value as int : noAnswer},
      score: map['score'] as int?,
      correctCount: map['correctCount'] as int?,
    );
  }

  /// A fixed id is what stops a student from having two attempts with the same number.
  static String idOf(String quizId, String uid, int number) => '${quizId}_${uid}_$number';

  /// Saved for a question whose own timer ran out, so it can't be answered later.
  static const int noAnswer = -1;

  final String quizId;
  final String uid;
  final int number;
  final String studentName;

  /// The groups whose leaderboards this attempt counts on.
  final List<String> groupIds;
  final AttemptStatus status;
  final DateTime startedAt;
  final DateTime lastAnswerAt;
  final DateTime? submittedAt;
  final int durationMin;
  final DateTime closesAt;
  final int questionCount;
  final Map<String, int> answers;
  final int? score;
  final int? correctCount;

  String get id => idOf(quizId, uid, number);

  bool get isInProgress => status == AttemptStatus.inProgress;

  bool get isGraded => status == AttemptStatus.graded;

  /// When answers stop being accepted: the time limit, or the quiz closing if that comes first.
  DateTime get deadline {
    if (durationMin == 0) return closesAt;
    final limit = startedAt.add(Duration(minutes: durationMin));
    return limit.isBefore(closesAt) ? limit : closesAt;
  }

  bool isExpired(DateTime now) => isInProgress && !now.isBefore(deadline);

  int get answeredCount => answers.values.where((option) => option != noAnswer).length;

  int get wrongCount => answeredCount - (correctCount ?? 0);

  /// Time from the start to the last answer, so reopening the app days later doesn't count against the student.
  Duration get timeTaken => lastAnswerAt.difference(startedAt);

  Map<String, dynamic> toMap() => {
    'quizId': quizId,
    'uid': uid,
    'number': number,
    'studentName': studentName,
    'groupIds': groupIds,
    'status': status.name,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'lastAnswerAt': lastAnswerAt.millisecondsSinceEpoch,
    'submittedAt': ?submittedAt?.millisecondsSinceEpoch,
    'durationMin': durationMin,
    'closesAt': closesAt.millisecondsSinceEpoch,
    'questionCount': questionCount,
    'answers': answers,
    'score': ?score,
    'correctCount': ?correctCount,
  };

  QuizAttempt copyWith({
    AttemptStatus? status,
    DateTime? startedAt,
    DateTime? lastAnswerAt,
    DateTime? submittedAt,
    Map<String, int>? answers,
    int? score,
    int? correctCount,
  }) => QuizAttempt(
    quizId: quizId,
    uid: uid,
    number: number,
    studentName: studentName,
    groupIds: groupIds,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    lastAnswerAt: lastAnswerAt ?? this.lastAnswerAt,
    submittedAt: submittedAt ?? this.submittedAt,
    durationMin: durationMin,
    closesAt: closesAt,
    questionCount: questionCount,
    answers: answers ?? this.answers,
    score: score ?? this.score,
    correctCount: correctCount ?? this.correctCount,
  );

  @override
  List<Object?> get props => [
    quizId,
    uid,
    number,
    studentName,
    groupIds,
    status,
    startedAt,
    lastAnswerAt,
    submittedAt,
    durationMin,
    closesAt,
    questionCount,
    answers,
    score,
    correctCount,
  ];
}
