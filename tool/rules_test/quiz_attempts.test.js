// Answers lock, time limits hold, and only the true score can be written.
import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

import {
  answer,
  asAdmin,
  asStudent,
  attemptId,
  closesAt,
  grade,
  key,
  minutesFromNow,
  newAttempt,
  seed,
  start,
  submit,
  submittedAttempt,
  useRulesEnv,
} from './helpers.js';

useRulesEnv();

describe('answering', () => {
  test('answers are added one at a time and lock once written', async () => {
    const db = asStudent('s1');
    await start(db);
    await assertSucceeds(answer(db, 'a', 1));
    await assertFails(answer(db, 'a', 0));
    await assertFails(
      updateDoc(doc(db, 'quizAttempts', attemptId('s1')), {
        answers: { a: 1, b: 1, c: 2 },
        lastAnswerAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db, 'quizAttempts', attemptId('s1')), { answers: {}, lastAnswerAt: serverTimestamp() }),
    );
  });

  test('every option of one question can\'t be stuffed in under different ids past the question count', async () => {
    const db = asStudent('s1');
    await start(db);
    await answer(db, 'a', 0);
    await answer(db, 'b', 0);
    await answer(db, 'c', 0);
    await assertFails(answer(db, 'd', 0));
  });

  test('the answer time has to be the server\'s', async () => {
    const db = asStudent('s1');
    await start(db);
    await assertFails(
      updateDoc(doc(db, 'quizAttempts', attemptId('s1')), { 'answers.a': 0, lastAnswerAt: minutesFromNow(-1) }),
    );
    await assertFails(updateDoc(doc(db, 'quizAttempts', attemptId('s1')), { 'answers.a': 0 }));
  });

  test('another student can\'t touch or read my attempt', async () => {
    await start(asStudent('s1'));
    await assertFails(answer(asStudent('s2'), 'a', 0, 's1'));
    await assertFails(submit(asStudent('s2'), 's1'));
    await assertFails(getDoc(doc(asStudent('s2'), 'quizAttempts', attemptId('s1'))));
  });

  test('answers after the time limit are refused, but submitting still works', async () => {
    await seed((db) =>
      setDoc(doc(db, 'quizAttempts', attemptId('s1')), newAttempt('s1', 1, {
        startedAt: minutesFromNow(-11),
        lastAnswerAt: minutesFromNow(-11),
      })),
    );
    const db = asStudent('s1');
    await assertFails(answer(db, 'a', 0));
    await assertSucceeds(submit(db));
  });

  test('answers within the grace period still count', async () => {
    await seed((db) =>
      setDoc(doc(db, 'quizAttempts', attemptId('s1')), newAttempt('s1', 1, {
        startedAt: Timestamp.fromMillis(Date.now() - 10 * 60000 - 5000),
        lastAnswerAt: minutesFromNow(-10),
      })),
    );
    await assertSucceeds(answer(asStudent('s1'), 'a', 0));
  });

  test('answers after the quiz closes are refused, even with time left', async () => {
    await seed((db) =>
      setDoc(doc(db, 'quizAttempts', attemptId('s1')), newAttempt('s1', 1, {
        startedAt: minutesFromNow(-1),
        lastAnswerAt: minutesFromNow(-1),
        closesAt: minutesFromNow(-1),
      })),
    );
    await assertFails(answer(asStudent('s1'), 'a', 0));
  });

  test('a quiz without a time limit runs until it closes', async () => {
    await seed((db) =>
      setDoc(doc(db, 'quizAttempts', attemptId('s1')), newAttempt('s1', 1, {
        durationMin: 0,
        startedAt: minutesFromNow(-50),
        lastAnswerAt: minutesFromNow(-50),
      })),
    );
    await assertSucceeds(answer(asStudent('s1'), 'a', 0));
  });
});

describe('submitting and grading', () => {
  test('a score can\'t be written before submitting', async () => {
    const db = asStudent('s1');
    await start(db);
    await assertFails(grade(db, 8, 3));
    await assertFails(updateDoc(doc(db, 'quizAttempts', attemptId('s1')), { score: 8 }));
  });

  test('the key opens only after submitting, and answers freeze', async () => {
    const db = asStudent('s1');
    await start(db);
    await answer(db, 'a', 0);
    await assertFails(getDoc(doc(db, 'quizzes/q1/content/key')));
    await assertSucceeds(submit(db));
    await assertSucceeds(getDoc(doc(db, 'quizzes/q1/content/key')));
    await assertFails(answer(db, 'b', 1));
    await assertFails(submit(db));
  });

  test('submitting has to use the server\'s time and change nothing else', async () => {
    const db = asStudent('s1');
    await start(db);
    await assertFails(
      updateDoc(doc(db, 'quizAttempts', attemptId('s1')), { status: 'submitted', submittedAt: minutesFromNow(-1) }),
    );
    await assertFails(
      updateDoc(doc(db, 'quizAttempts', attemptId('s1')), {
        status: 'submitted',
        submittedAt: serverTimestamp(),
        'answers.a': 0,
      }),
    );
  });

  test('only the true score passes, weighted by points', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    await assertFails(grade(db, 8, 3));
    await assertFails(grade(db, 3, 3));
    await assertFails(grade(db, 8, 2));
    await assertFails(grade(db, 2, 2));
    await assertSucceeds(grade(db, 3, 2));
  });

  test('a graded attempt never changes again', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    await grade(db, 3, 2);
    await assertFails(grade(db, 8, 3));
    await assertFails(updateDoc(doc(db, 'quizAttempts', attemptId('s1')), { score: 8 }));
    await assertFails(updateDoc(doc(db, 'quizAttempts', attemptId('s1')), { status: 'inProgress' }));
  });

  test('students can\'t delete an attempt to take it again', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    await assertFails(deleteDoc(doc(db, 'quizAttempts', attemptId('s1'))));
    await assertSucceeds(deleteDoc(doc(asAdmin(), 'quizAttempts', attemptId('s1'))));
  });
});
