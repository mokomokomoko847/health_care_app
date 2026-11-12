import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, collection, updateDoc, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';

let environment;
const path = 'users/alice/glucose_records/first';
const valid = () => ({
  recordedAt: Timestamp.fromDate(new Date('2026-01-15T00:00:00Z')),
  bloodSugarMgDl: 120,
  mealTiming: 'beforeMeal',
  memo: '',
  photoPaths: [],
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});
const owner = () => environment.authenticatedContext('alice', { email_verified: true }).firestore();

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-health-care',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => environment.clearFirestore());
after(async () => environment?.cleanup());

test('確認済み本人は登録・単体取得・一覧取得できる', async () => {
  const db = owner();
  await assertSucceeds(setDoc(doc(db, path), valid()));
  await assertSucceeds(getDoc(doc(db, path)));
  await assertSucceeds(getDocs(collection(db, 'users/alice/glucose_records')));
});

test('未認証・未確認・別ユーザーは読み書きできない', async () => {
  await assertSucceeds(setDoc(doc(owner(), path), valid()));
  const contexts = [
    environment.unauthenticatedContext(),
    environment.authenticatedContext('alice', { email_verified: false }),
    environment.authenticatedContext('alice'),
    environment.authenticatedContext('bob', { email_verified: true }),
  ];
  for (const context of contexts) {
    const db = context.firestore();
    await assertFails(getDoc(doc(db, path)));
    await assertFails(getDocs(collection(db, 'users/alice/glucose_records')));
    await assertFails(setDoc(doc(db, 'users/alice/glucose_records/new'), valid()));
    await assertFails(updateDoc(doc(db, path), { bloodSugarMgDl: 130 }));
    await assertFails(deleteDoc(doc(db, path)));
  }
});

test('必須項目欠落・型違反・範囲外・未来日時・余分な所有者フィールドを拒否する', async () => {
  const db = owner();
  const invalid = [
    { bloodSugarMgDl: -1 }, { bloodSugarMgDl: 601 },
    { bloodSugarMgDl: 1.5 }, { bloodSugarMgDl: '120' },
    { recordedAt: Timestamp.fromDate(new Date('2099-01-01')) },
    { recordedAt: '2026-01-15' }, { mealTiming: 'other' },
    { memo: 'あ'.repeat(51) }, { memo: 123 },
    { photoPaths: ['/local/photo.jpg'] }, { photoPaths: 'invalid' },
    { ownerId: 'bob' }, { createdAt: Timestamp.fromMillis(0) },
    { updatedAt: Timestamp.fromMillis(0) },
  ];
  for (const change of invalid) {
    await assertFails(setDoc(doc(db, path), { ...valid(), ...change }));
  }
  for (const field of Object.keys(valid())) {
    const data = valid();
    delete data[field];
    await assertFails(setDoc(doc(db, path), data));
  }
});

test('血糖値の境界・メモ50文字を許可し未実装の変更や他のパスを拒否する', async () => {
  const db = owner();
  for (const bloodSugarMgDl of [0, 600]) {
    await assertSucceeds(setDoc(doc(db, `${path}-${bloodSugarMgDl}`), {
      ...valid(), bloodSugarMgDl, memo: 'あ'.repeat(50),
    }));
  }
  await assertSucceeds(setDoc(doc(db, path), valid()));
  await assertFails(updateDoc(doc(db, path), { bloodSugarMgDl: 130 }));
  await assertFails(deleteDoc(doc(db, path)));
  await assertFails(setDoc(doc(db, 'glucose_records/first'), valid()));
  await assertFails(setDoc(doc(db, `${path}/corrections/first`), valid()));
});

test('本人の同じ記録の写真参照を3枚まで許可し他人・別記録・URL・4枚を拒否する', async () => {
  const db = owner();
  const photo = (user = 'alice', record = 'first') => `users/${user}/glucose_records/${record}/photos/${'a'.repeat(64)}`;
  for (const count of [1, 2, 3]) {
    await assertSucceeds(setDoc(doc(db, `${path}-${count}`), {
      ...valid(), photoPaths: Array(count).fill(photo('alice', `first-${count}`)),
    }));
  }
  for (const photoPaths of [
    [photo('bob')], [photo('alice', 'other')], ['https://example.com/photo.jpg'],
    [123], Array(4).fill(photo()), [`${photo()}/extra`],
  ]) {
    await assertFails(setDoc(doc(db, path), { ...valid(), photoPaths }));
  }
});
