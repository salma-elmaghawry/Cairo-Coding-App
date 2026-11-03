// Shared setup for the quiz security rules tests, run against the Firestore emulator: `npm test` from this folder.
// With no server on the Spark plan, these rules are the only thing keeping answers hidden and scores honest.
// The test files share one emulator and clear it between tests, so `npm test` runs them one at a time.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach } from 'node:test';

import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

export const minutesFromNow = (minutes) => Timestamp.fromMillis(Date.now() + minutes * 60000);
export const opensAt = minutesFromNow(-60);
export const closesAt = minutesFromNow(60);

export const baseQuiz = {
  title: 'Loops',
  groupIds: ['g1'],
  durationMin: 10,
  opensAt,
  closesAt,
  maxAttempts: 2,
  status: 'published',
  questionCount: 3,
  totalPoints: 8,
};

// a is worth 1, b is worth 2, c is worth 5.
export const key = { p1: { a: 0 }, p2: { b: 1 }, p3: {}, p5: { c: 2 }, p10: {}, p20: {} };

let env;
export const asStudent = (uid) => env.authenticatedContext(uid).firestore();
export const asAdmin = () => env.authenticatedContext('admin').firestore();

export const seed = (write) => env.withSecurityRulesDisabled((context) => write(context.firestore()));

export const attemptId = (uid, number = 1, quizId = 'q1') => `${quizId}_${uid}_${number}`;

export const newAttempt = (uid = 's1', number = 1, overrides = {}) => ({
  quizId: 'q1',
  uid,
  number,
  studentName: 'Mariam',
  groupIds: ['g1'],
  status: 'inProgress',
  startedAt: serverTimestamp(),
  lastAnswerAt: serverTimestamp(),
  durationMin: 10,
  closesAt,
  questionCount: 3,
  answers: {},
  ...overrides,
});

export const start = (db, uid = 's1', number = 1, overrides = {}) =>
  setDoc(doc(db, 'quizAttempts', attemptId(uid, number)), newAttempt(uid, number, overrides));

export const answer = (db, questionId, option, uid = 's1', number = 1) =>
  updateDoc(doc(db, 'quizAttempts', attemptId(uid, number)), {
    [`answers.${questionId}`]: option,
    lastAnswerAt: serverTimestamp(),
  });

export const submit = (db, uid = 's1', number = 1) =>
  updateDoc(doc(db, 'quizAttempts', attemptId(uid, number)), { status: 'submitted', submittedAt: serverTimestamp() });

export const grade = (db, score, correctCount, uid = 's1', number = 1) =>
  updateDoc(doc(db, 'quizAttempts', attemptId(uid, number)), { status: 'graded', score, correctCount });

// s1 answers a and b correctly and c wrongly, so the true score is 3 with 2 correct.
export async function submittedAttempt(db) {
  await start(db);
  await answer(db, 'a', 0);
  await answer(db, 'b', 1);
  await answer(db, 'c', 0);
  await submit(db);
}

export async function boardEntry(db, uid = 's1') {
  const attempt = (await getDoc(doc(db, 'quizAttempts', attemptId(uid)))).data();
  return {
    name: attempt.studentName,
    score: attempt.score,
    correctCount: attempt.correctCount,
    durationMs: attempt.lastAnswerAt.toMillis() - attempt.startedAt.toMillis(),
  };
}

// Grades and posts to the board in one batch, the way the app does.
export async function gradeAndPost(db, { score = 3, correctCount = 2, entry, groupId = 'g1', uid = 's1' } = {}) {
  const attempt = (await getDoc(doc(db, 'quizAttempts', attemptId(uid)))).data();
  const batch = writeBatch(db);
  batch.update(doc(db, 'quizAttempts', attemptId(uid)), { status: 'graded', score, correctCount });
  batch.set(
    doc(db, 'groups', groupId, 'quizBoards', 'q1'),
    {
      [uid]: entry ?? {
        name: attempt.studentName,
        score,
        correctCount,
        durationMs: attempt.lastAnswerAt.toMillis() - attempt.startedAt.toMillis(),
      },
    },
    { merge: true },
  );
  return batch.commit();
}

// Call once at the top of each test file: it starts the environment and reseeds it before every test.
export function useRulesEnv() {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: 'demo-cairo-coding',
      firestore: { rules: readFileSync('../../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8085 },
    });
  });

  after(() => env.cleanup());

  beforeEach(async () => {
    await env.clearFirestore();
    await seed(async (db) => {
      await setDoc(doc(db, 'admins/admin'), {});
      const student = (name, groupIds, active = true) => ({ name, email: `${name}@x.com`, groupIds, active });
      await setDoc(doc(db, 'users/s1'), student('Mariam', ['g1']));
      await setDoc(doc(db, 'users/s2'), student('Omar', ['g1']));
      await setDoc(doc(db, 'users/s3'), student('Nour', ['g2']));
      await setDoc(doc(db, 'users/s4'), student('Karim', ['g1'], false));
      await setDoc(doc(db, 'quizzes/q1'), baseQuiz);
      await setDoc(doc(db, 'quizzes/q1/content/paper'), { questions: [{ id: 'a', text: 'Q?' }] });
      await setDoc(doc(db, 'quizzes/q1/content/key'), key);
      await setDoc(doc(db, 'groups/g1'), { name: 'G1' });
      await setDoc(doc(db, 'groups/g1/quizzes/q1'), baseQuiz);
      await setDoc(doc(db, 'groups/g2'), { name: 'G2' });
    });
  });
}

export function assertEqual(actual, expected) {
  const [a, b] = [JSON.stringify(actual), JSON.stringify(expected)];
  if (a !== b) throw new Error(`expected ${b}, got ${a}`);
}
