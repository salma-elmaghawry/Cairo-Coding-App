// Attendance, recording views, last-seen stamps and announcements: what students may write about themselves.
import { describe, test } from 'node:test';

import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  arrayRemove,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

import { asAdmin, asStudent, minutesFromNow, seed, useRulesEnv } from './helpers.js';

useRulesEnv();

const session = (startsInMinutes, overrides = {}) => ({
  groupId: 'g1',
  number: 7,
  startsAt: minutesFromNow(startsInMinutes),
  durationMin: 120,
  status: 'scheduled',
  ...overrides,
});

const seedSession = (id, data) => seed((db) => setDoc(doc(db, 'groups/g1/sessions', id), data));
const join = (uid, id = 'live', who = uid) =>
  updateDoc(doc(asStudent(uid), 'groups/g1/sessions', id), { attendees: arrayUnion(who) });

describe('attendance', () => {
  test('a student marks themselves present while the session runs, and joining twice is fine', async () => {
    await seedSession('live', session(-10));
    await assertSucceeds(join('s1'));
    await assertSucceeds(join('s1'));
    await assertSucceeds(join('s2'));
  });

  test('from 30 minutes before the start, not earlier and not after the end', async () => {
    await seedSession('soon', session(20));
    await seedSession('later', session(45));
    await seedSession('over', session(-130));
    await assertSucceeds(join('s1', 'soon'));
    await assertFails(join('s1', 'later'));
    await assertFails(join('s1', 'over'));
  });

  test('nobody else can be added, removed or changed along with it', async () => {
    await seedSession('live', session(-10, { attendees: ['s2'] }));
    await assertFails(join('s1', 'live', 's2b'));
    await assertFails(
      updateDoc(doc(asStudent('s2'), 'groups/g1/sessions/live'), { attendees: arrayRemove('s2') }),
    );
    await assertFails(
      updateDoc(doc(asStudent('s1'), 'groups/g1/sessions/live'), { attendees: arrayUnion('s1'), topic: 'x' }),
    );
  });

  test('not for a cancelled session, another group, or a deactivated student', async () => {
    await seedSession('cancelled', session(-10, { status: 'cancelled' }));
    await seedSession('live', session(-10));
    await assertFails(join('s1', 'cancelled'));
    await assertFails(join('s3', 'live'));
    await assertFails(join('s4', 'live'));
  });

  test('the admin sets attendance for any session', async () => {
    await seedSession('over', session(-300));
    await assertSucceeds(updateDoc(doc(asAdmin(), 'groups/g1/sessions/over'), { attendees: ['s1', 's2'] }));
  });
});

describe('recording views', () => {
  test('a student adds only themselves to the viewers', async () => {
    await seed((db) => setDoc(doc(db, 'groups/g1/recordings/r1'), { title: 'Loops', viewers: ['s2'] }));
    const ref = (uid) => doc(asStudent(uid), 'groups/g1/recordings/r1');
    await assertSucceeds(updateDoc(ref('s1'), { viewers: arrayUnion('s1') }));
    await assertFails(updateDoc(ref('s1'), { viewers: arrayUnion('s9') }));
    await assertFails(updateDoc(ref('s1'), { viewers: arrayRemove('s2') }));
    await assertFails(updateDoc(ref('s1'), { viewers: arrayUnion('s1'), title: 'Mine' }));
    await assertFails(updateDoc(ref('s3'), { viewers: arrayUnion('s3') }));
  });
});

describe('last seen', () => {
  test('a student stamps their own profile with the server time and nothing else', async () => {
    const own = doc(asStudent('s1'), 'users/s1');
    await assertSucceeds(updateDoc(own, { lastSeenAt: serverTimestamp() }));
    await assertFails(updateDoc(own, { lastSeenAt: minutesFromNow(-60) }));
    await assertFails(updateDoc(own, { lastSeenAt: serverTimestamp(), name: 'Somebody else' }));
    await assertFails(updateDoc(doc(asStudent('s1'), 'users/s2'), { lastSeenAt: serverTimestamp() }));
  });

  test('the admin can still edit a student who has a last-seen stamp', async () => {
    await seed((db) => updateDoc(doc(db, 'users/s1'), { lastSeenAt: minutesFromNow(-5) }));
    await assertSucceeds(updateDoc(doc(asAdmin(), 'users/s1'), { name: 'Mariam Adel' }));
  });
});

describe('announcements', () => {
  const announcement = { title: 'Welcome', body: 'Hi', groupIds: ['g1'], createdAt: serverTimestamp() };

  test('the admin posts one per group, and only the group reads it', async () => {
    await assertSucceeds(setDoc(doc(asAdmin(), 'groups/g1/announcements/a1'), announcement));
    await assertFails(setDoc(doc(asAdmin(), 'groups/g2/announcements/a1'), announcement));
    await assertFails(setDoc(doc(asAdmin(), 'groups/g1/announcements/a2'), { ...announcement, title: '' }));
    await assertSucceeds(getDocs(collection(asStudent('s1'), 'groups/g1/announcements')));
    await assertFails(getDocs(collection(asStudent('s3'), 'groups/g1/announcements')));
    await assertFails(getDocs(collection(asStudent('s4'), 'groups/g1/announcements')));
  });

  test('students can neither post nor delete', async () => {
    await assertFails(setDoc(doc(asStudent('s1'), 'groups/g1/announcements/a1'), announcement));
    await seed((db) => setDoc(doc(db, 'groups/g1/announcements/a1'), { ...announcement, createdAt: minutesFromNow(0) }));
    await assertFails(deleteDoc(doc(asStudent('s1'), 'groups/g1/announcements/a1')));
    await assertSucceeds(deleteDoc(doc(asAdmin(), 'groups/g1/announcements/a1')));
  });
});
