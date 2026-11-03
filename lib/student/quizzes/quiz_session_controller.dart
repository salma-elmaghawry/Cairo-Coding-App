import 'dart:async';

import 'package:cairo_coding_app/core/error_handling/failures.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizSession {
  const QuizSession({
    required this.attempt,
    required this.questions,
    required this.index,
    required this.questionStartedAt,
    this.selected,
    this.reviewing = false,
    this.finishing = false,
    this.timedOut = false,
    this.failure,
    this.finished,
  });

  final QuizAttempt attempt;
  final List<QuizQuestion> questions;
  final int index;
  final DateTime questionStartedAt;

  /// The option the student has tapped but not locked yet.
  final int? selected;

  /// On the screen that confirms the final submit.
  final bool reviewing;
  final bool finishing;
  final bool timedOut;
  final Failure? failure;
  final QuizAttempt? finished;

  QuizQuestion get current => questions[index];

  bool isLocked(QuizQuestion question) => attempt.answers.containsKey(question.id);

  int get unansweredCount => questions.length - attempt.answeredCount;

  /// The next question after [after] still open. Skipped ones behind it wait for the confirm screen.
  int? nextOpen(int after) {
    for (var i = after + 1; i < questions.length; i++) {
      if (!isLocked(questions[i])) return i;
    }
    return null;
  }

  QuizSession copyWith({
    QuizAttempt? attempt,
    int? index,
    DateTime? questionStartedAt,
    int? Function()? selected,
    bool? reviewing,
    bool? finishing,
    bool? timedOut,
    Failure? Function()? failure,
    QuizAttempt? finished,
  }) => QuizSession(
    attempt: attempt ?? this.attempt,
    questions: questions,
    index: index ?? this.index,
    questionStartedAt: questionStartedAt ?? this.questionStartedAt,
    selected: selected == null ? this.selected : selected(),
    reviewing: reviewing ?? this.reviewing,
    finishing: finishing ?? this.finishing,
    timedOut: timedOut ?? this.timedOut,
    failure: failure == null ? this.failure : failure(),
    finished: finished ?? this.finished,
  );
}

final quizSessionProvider = AsyncNotifierProvider.autoDispose.family<QuizSessionController, QuizSession, String>(
  QuizSessionController.new,
  retry: (_, _) => null,
);

class QuizSessionController extends AsyncNotifier<QuizSession> {
  QuizSessionController(this.quizId);

  final String quizId;

  final List<Future<void>> _pendingSaves = [];

  DateTime _now() => ref.read(clockProvider)().add(ref.read(quizClockSkewProvider));

  QuizSession get _session => state.requireValue;

  void _emit(QuizSession session) => state = AsyncData(session);

  @override
  Future<QuizSession> build() async {
    final attempts = await ref.read(myAttemptsProvider.future);
    final attempt = attempts.where((a) => a.quizId == quizId && a.isInProgress).firstOrNull;
    if (attempt == null) throw NotAuthorizedFailure('quizzes.errors.no_attempt'.tr());

    final paper = await ref.read(quizRepositoryProvider).getPaper(quizId);
    final questions = switch (paper) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };

    final timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.onDispose(timer.cancel);

    final firstOpen = questions.indexWhere((q) => !attempt.answers.containsKey(q.id));
    return QuizSession(
      attempt: attempt,
      questions: questions,
      index: firstOpen < 0 ? 0 : firstOpen,
      reviewing: firstOpen < 0,
      // After reopening the app, a question's timer carries on from the last answer instead of starting over.
      questionStartedAt: attempt.lastAnswerAt,
    );
  }

  void _tick() {
    final session = state.value;
    if (session == null || session.finishing || session.finished != null) return;
    final now = _now();
    if (!now.isBefore(session.attempt.deadline)) {
      _timeUp();
      return;
    }
    if (session.reviewing) return;
    final question = session.current;
    if (!question.hasTimeLimit) return;
    final limit = session.questionStartedAt.add(Duration(seconds: question.timeLimitSec));
    if (!now.isBefore(limit)) _lock(question, session.selected ?? QuizAttempt.noAnswer);
  }

  /// The whole quiz ran out: an option the student has tapped still counts, thanks to the rules' grace period.
  void _timeUp() {
    final session = _session;
    if (!session.reviewing && session.selected != null && !session.isLocked(session.current)) {
      _save(session.current, session.selected!);
    }
    _emit(_session.copyWith(timedOut: true));
    submit();
  }

  void select(int option) {
    final session = _session;
    if (session.reviewing || session.finishing || session.isLocked(session.current)) return;
    _emit(session.copyWith(selected: () => option));
  }

  /// Locks the tapped option and moves on. There's no way back to a locked question.
  void confirm() {
    final session = _session;
    if (session.selected == null || session.finishing) return;
    _lock(session.current, session.selected!);
  }

  /// Leaves the question open for later, from the confirm screen.
  void skip() {
    final session = _session;
    if (session.finishing) return;
    _moveOn(session.copyWith(selected: () => null));
  }

  /// Goes back to a skipped question from the confirm screen.
  void openQuestion(int index) {
    final session = _session;
    if (session.finishing || session.isLocked(session.questions[index])) return;
    _emit(session.copyWith(index: index, reviewing: false, selected: () => null, questionStartedAt: _now()));
  }

  void _lock(QuizQuestion question, int option) {
    _save(question, option);
    _moveOn(_session.copyWith(selected: () => null));
  }

  void _moveOn(QuizSession session) {
    final next = session.nextOpen(session.index);
    if (next == null) {
      _emit(session.copyWith(reviewing: true));
    } else {
      _emit(session.copyWith(index: next, questionStartedAt: _now()));
    }
  }

  /// Saved in the background so a slow connection never holds the student up. Firestore keeps it in its
  /// queue while offline. A refusal means the server's deadline has passed, so the quiz ends here too.
  void _save(QuizQuestion question, int option) {
    final session = _session;
    _emit(
      session.copyWith(attempt: session.attempt.copyWith(answers: {...session.attempt.answers, question.id: option})),
    );
    final save = ref.read(quizRepositoryProvider).saveAnswer(session.attempt, question.id, option).then((result) {
      if (result case Err(failure: NotAuthorizedFailure()) when ref.mounted && !_session.finishing) _timeUp();
    });
    _pendingSaves.add(save);
    unawaited(save.whenComplete(() => _pendingSaves.remove(save)));
  }

  Future<void> submit() async {
    final session = _session;
    if (session.finishing || session.finished != null) return;
    _emit(session.copyWith(finishing: true, failure: () => null));
    // Answers go first, so the submit that freezes the attempt doesn't overtake them.
    await Future.wait(_pendingSaves.toList()).timeout(const Duration(seconds: 8), onTimeout: () => const []);
    final result = await ref.read(quizRepositoryProvider).finishAttempt(session.attempt.id);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        _emit(_session.copyWith(finished: value, finishing: false));
      case Err(:final failure):
        _emit(_session.copyWith(failure: () => failure, finishing: false, reviewing: true));
    }
  }
}
