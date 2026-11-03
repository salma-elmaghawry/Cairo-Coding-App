// Who can see a quiz and who can start one.
import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

import {
  asAdmin,
  asStudent,
  attemptId,
  baseQuiz,
  closesAt,
  key,
  minutesFromNow,
  newAttempt,
  opensAt,
  seed,
  start,
  submit,
  useRulesEnv,
} from './helpers.js';

useRulesEnv();

describe('seeing a quiz', () => {
  test('a student reads their own group\'s published copy, not another group\'s', async () => {
    await assertSucceeds(getDoc(doc(asStudent('s1'), 'groups/g1/quizzes/q1')));
    await assertSucceeds(getDocs(collection(asStudent('s1'), 'groups/g1/quizzes')));
    await assertFails(getDoc(doc(asStudent('s3'), 'groups/g1/quizzes/q1')));
    await assertFails(getDocs(collection(asStudent('s3'), 'groups/g1/quizzes')));
  });

  test('a deactivated student reads nothing', async () => {
    await assertFails(getDoc(doc(asStudent('s4'), 'groups/g1/quizzes/q1')));
  });

  test('the master quiz, its questions and its key stay hidden before starting', async () => {
    const db = asStudent('s1');
    await assertFails(getDoc(doc(db, 'quizzes/q1')));
    await assertFails(getDocs(collection(db, 'quizzes')));
    await assertFails(getDoc(doc(db, 'quizzes/q1/content/paper')));
    await assertFails(getDoc(doc(db, 'quizzes/q1/content/key')));
  });

  test('students can never change a quiz or its copies', async () => {
    const db = asStudent('s1');
    await assertFails(setDoc(doc(db, 'quizzes/q9'), baseQuiz));
    await assertFails(updateDoc(doc(db, 'groups/g1/quizzes/q1'), { title: 'x' }));
    await assertFails(setDoc(doc(db, 'quizzes/q1/content/key'), key));
    await assertFails(deleteDoc(doc(db, 'quizzes/q1')));
  });

  test('admins manage everything', async () => {
    const db = asAdmin();
    await assertSucceeds(getDoc(doc(db, 'quizzes/q1/content/key')));
    await assertSucceeds(setDoc(doc(db, 'quizzes/q9'), { ...baseQuiz, status: 'draft' }));
    await assertSucceeds(setDoc(doc(db, 'quizzes/q9/content/key'), key));
    await assertSucceeds(setDoc(doc(db, 'groups/g1/quizzes/q9'), baseQuiz));
    await assertSucceeds(deleteDoc(doc(db, 'groups/g1/quizzes/q1')));
  });
});

describe('starting an attempt', () => {
  test('an eligible student starts, and the questions unlock but the key does not', async () => {
    const db = asStudent('s1');
    await assertSucceeds(start(db));
    await assertSucceeds(getDoc(doc(db, 'quizzes/q1/content/paper')));
    await assertFails(getDoc(doc(db, 'quizzes/q1/content/key')));
  });

  test('starting twice is refused', async () => {
    const db = asStudent('s1');
    await start(db);
    await assertFails(start(db));
  });

  test('students outside the quiz\'s groups, or deactivated, can\'t start', async () => {
    await assertFails(start(asStudent('s3'), 's3', 1, { studentName: 'Nour', groupIds: ['g1'] }));
    await assertFails(start(asStudent('s3'), 's3', 1, { studentName: 'Nour', groupIds: ['g2'] }));
    await assertFails(start(asStudent('s4'), 's4', 1, { studentName: 'Karim' }));
  });

  test('a draft, an unopened or a closed quiz can\'t be started', async () => {
    for (const change of [
      { status: 'draft' },
      { opensAt: minutesFromNow(5) },
      { closesAt: minutesFromNow(-5) },
    ]) {
      await seed((db) => updateDoc(doc(db, 'quizzes/q1'), change));
      const attempt = change.closesAt ? { closesAt: change.closesAt } : {};
      await assertFails(start(asStudent('s1'), 's1', 1, attempt));
      await seed((db) => setDoc(doc(db, 'quizzes/q1'), baseQuiz));
    }
  });

  test('a student can\'t lie about the start, the time limit or who they are', async () => {
    const db = asStudent('s1');
    await assertFails(start(db, 's1', 1, { startedAt: minutesFromNow(30) }));
    await assertFails(start(db, 's1', 1, { durationMin: 999 }));
    await assertFails(start(db, 's1', 1, { closesAt: minutesFromNow(600) }));
    await assertFails(start(db, 's1', 1, { questionCount: 99 }));
    await assertFails(start(db, 's1', 1, { studentName: 'Someone else' }));
    await assertFails(start(db, 's1', 1, { answers: { a: 0 } }));
    await assertFails(start(db, 's1', 1, { status: 'graded' }));
    await assertFails(start(db, 's1', 1, { score: 100 }));
    await assertFails(start(db, 's2'));
  });

  test('the attempt id has to match the attempt', async () => {
    const db = asStudent('s1');
    await assertFails(setDoc(doc(db, 'quizAttempts', 'anything'), newAttempt()));
    await assertFails(setDoc(doc(db, 'quizAttempts', attemptId('s1', 5)), newAttempt()));
  });

  test('a retake needs the previous attempt finished, and stops at the limit', async () => {
    const db = asStudent('s1');
    await assertFails(start(db, 's1', 2));
    await start(db);
    await assertFails(start(db, 's1', 2));
    await submit(db);
    await assertSucceeds(start(db, 's1', 2));
    await submit(db, 's1', 2);
    await assertFails(start(db, 's1', 3));
  });
});

describe('attempt queries', () => {
  test('a student lists only their own attempts', async () => {
    const db = asStudent('s1');
    await start(db);
    await assertSucceeds(getDocs(query(collection(db, 'quizAttempts'), where('uid', '==', 's1'))));
    await assertFails(getDocs(query(collection(db, 'quizAttempts'), where('uid', '==', 's2'))));
    await assertFails(getDocs(query(collection(db, 'quizAttempts'), where('quizId', '==', 'q1'))));
    await assertFails(getDocs(collection(db, 'quizAttempts')));
  });

  test('an admin lists a quiz\'s attempts', async () => {
    await assertSucceeds(getDocs(query(collection(asAdmin(), 'quizAttempts'), where('quizId', '==', 'q1'))));
  });
});
