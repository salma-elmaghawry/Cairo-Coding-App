// What the student's Profile reads (their course) and what only the admin writes (tasks and certificates).
import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { arrayUnion, collection, doc, getDoc, getDocs, setDoc, updateDoc } from 'firebase/firestore';

import { asAdmin, asStudent, minutesFromNow, seed, useRulesEnv } from './helpers.js';

useRulesEnv();

describe('courses', () => {
  test('an active student reads a course by id, but cannot list them or write one', async () => {
    await seed((db) => setDoc(doc(db, 'courses/cpp'), { name: 'C++', sessionTitles: [], instructorIds: [] }));
    await assertSucceeds(getDoc(doc(asStudent('s1'), 'courses/cpp')));
    await assertFails(getDocs(collection(asStudent('s1'), 'courses')));
    await assertFails(updateDoc(doc(asStudent('s1'), 'courses/cpp'), { name: 'Mine' }));
    await assertSucceeds(getDocs(collection(asAdmin(), 'courses')));
  });

  test('a deactivated student or a stranger cannot read one', async () => {
    await seed((db) => setDoc(doc(db, 'courses/cpp'), { name: 'C++', sessionTitles: [], instructorIds: [] }));
    await assertFails(getDoc(doc(asStudent('s4'), 'courses/cpp')));
    await assertFails(getDoc(doc(asStudent('nobody'), 'courses/cpp')));
  });
});

describe('certificates', () => {
  const certificate = { title: 'C++', url: 'https://drive.google.com/file/d/x/view', issuedOn: '2026-11-11' };

  test('the admin adds certificates and the student reads them on their own profile', async () => {
    await assertSucceeds(updateDoc(doc(asAdmin(), 'users/s1'), { certificates: [certificate] }));
    const own = await getDoc(doc(asStudent('s1'), 'users/s1'));
    if (own.data().certificates?.[0]?.title !== 'C++') throw new Error('certificate not saved');
    await assertFails(updateDoc(doc(asAdmin(), 'users/s1'), { certificates: 'C++' }));
  });

  test('a student cannot give themselves one', async () => {
    await assertFails(updateDoc(doc(asStudent('s1'), 'users/s1'), { certificates: [certificate] }));
  });
});

describe('tasks', () => {
  const session = { groupId: 'g1', number: 3, startsAt: minutesFromNow(-10), durationMin: 120, status: 'scheduled' };

  test('only the admin ticks who handed in a task, even while the session runs', async () => {
    await seed((db) => setDoc(doc(db, 'groups/g1/sessions/live'), session));
    const asMember = doc(asStudent('s1'), 'groups/g1/sessions/live');
    await assertFails(updateDoc(asMember, { taskDoneBy: arrayUnion('s1') }));
    await assertFails(updateDoc(asMember, { attendees: arrayUnion('s1'), taskDoneBy: ['s1'] }));
    await assertSucceeds(updateDoc(doc(asAdmin(), 'groups/g1/sessions/live'), { taskDoneBy: ['s1', 's2'] }));
  });
});
