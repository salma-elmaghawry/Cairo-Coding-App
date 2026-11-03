// Leaderboards stay honest and stay inside their group.
import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
} from 'firebase/firestore';

import {
  answer,
  asStudent,
  assertEqual,
  attemptId,
  boardEntry,
  grade,
  gradeAndPost,
  start,
  submit,
  submittedAttempt,
  useRulesEnv,
} from './helpers.js';

useRulesEnv();

describe('the group leaderboard', () => {
  test('grading and posting together succeeds, and classmates can read it', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    await assertSucceeds(gradeAndPost(db));
    await assertSucceeds(getDoc(doc(asStudent('s2'), 'groups/g1/quizBoards/q1')));
  });

  test('a second student adds their row without touching the first', async () => {
    const first = asStudent('s1');
    await submittedAttempt(first);
    await gradeAndPost(first);

    const second = asStudent('s2');
    await start(second, 's2', 1, { studentName: 'Omar' });
    await submit(second, 's2');
    await assertSucceeds(gradeAndPost(second, { score: 0, correctCount: 0, uid: 's2' }));
    const board = await getDoc(doc(second, 'groups/g1/quizBoards/q1'));
    assertEqual(Object.keys(board.data()).sort(), ['s1', 's2']);
  });

  test('another group can\'t see the ranking', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    await gradeAndPost(db);
    await assertFails(getDoc(doc(asStudent('s3'), 'groups/g1/quizBoards/q1')));
    await assertFails(getDocs(collection(asStudent('s3'), 'groups/g1/quizBoards')));
  });

  test('nothing can be posted to a board before grading', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    await assertFails(
      setDoc(doc(db, 'groups/g1/quizBoards/q1'), { s1: { name: 'Mariam', score: 3, correctCount: 2, durationMs: 1 } }),
    );
  });

  test('a board row has to copy the graded attempt exactly', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    const attempt = (await getDoc(doc(db, 'quizAttempts', attemptId('s1')))).data();
    const durationMs = attempt.lastAnswerAt.toMillis() - attempt.startedAt.toMillis();
    const honest = { name: 'Mariam', score: 3, correctCount: 2, durationMs };
    await assertFails(gradeAndPost(db, { entry: { ...honest, score: 8 } }));
    await assertFails(gradeAndPost(db, { entry: { ...honest, correctCount: 3 } }));
    await assertFails(gradeAndPost(db, { entry: { ...honest, durationMs: durationMs + 1 } }));
    await assertFails(gradeAndPost(db, { entry: { ...honest, name: 'Hacker' } }));
    await assertFails(gradeAndPost(db, { entry: { ...honest, photo: 'x' } }));
    await assertSucceeds(gradeAndPost(db, { entry: honest }));
  });

  test('a student can\'t post to a group the attempt isn\'t in', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    await assertFails(gradeAndPost(db, { groupId: 'g2' }));
  });

  test('a student can\'t rewrite their own row or anyone else\'s', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    await gradeAndPost(db);
    const entry = await boardEntry(db);

    await assertFails(setDoc(doc(db, 'groups/g1/quizBoards/q1'), { s1: { ...entry, score: 8 } }, { merge: true }));
    await assertFails(setDoc(doc(db, 'groups/g1/quizBoards/q1'), { s1: entry }, { merge: true }));
    await assertFails(setDoc(doc(db, 'groups/g1/quizBoards/q1'), { s2: entry }, { merge: true }));
    await assertFails(setDoc(doc(asStudent('s2'), 'groups/g1/quizBoards/q1'), { s1: entry }, { merge: true }));
    await assertFails(deleteDoc(doc(db, 'groups/g1/quizBoards/q1')));
  });

  test('a retake can\'t replace the first attempt\'s row', async () => {
    const db = asStudent('s1');
    await submittedAttempt(db);
    await gradeAndPost(db);
    const entry = await boardEntry(db);

    await start(db, 's1', 2);
    await answer(db, 'a', 0, 's1', 2);
    await answer(db, 'b', 1, 's1', 2);
    await answer(db, 'c', 2, 's1', 2);
    await submit(db, 's1', 2);
    await assertSucceeds(grade(db, 8, 3, 's1', 2));
    await assertFails(setDoc(doc(db, 'groups/g1/quizBoards/q1'), { s1: { ...entry, score: 8 } }, { merge: true }));
  });
});
