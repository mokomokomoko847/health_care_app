import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';
import { doc, setDoc } from 'firebase/firestore';

let environment;
const path = `users/alice/glucose_records/first/photos/${'a'.repeat(64)}`;
const bytes = new Uint8Array([137, 80, 78, 71]);
const owner = () => environment.authenticatedContext('alice', { email_verified: true });
const upload = (context, objectPath = path, data = bytes, contentType = 'image/png') =>
  uploadBytes(ref(context.storage(), objectPath), data, { contentType });

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-health-care',
    storage: { rules: readFileSync(new URL('../../storage.rules', import.meta.url), 'utf8') },
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => {
  // clearStorage()はルート直下しか削除しないため、記録ごとのprefixも巡回する。
  await environment.withSecurityRulesDisabled(async (admin) => {
    async function clear(directory) {
      const { items, prefixes } = await directory.listAll();
      await Promise.all(items.map((item) => item.delete()));
      await Promise.all(prefixes.map(clear));
    }
    await clear(admin.storage().ref());
  });
  await environment.clearFirestore();
});
after(async () => environment?.cleanup());

test('確認済み本人が画像を保存・取得でき未確定の写真を削除できる', async () => {
  const context = owner();
  await assertSucceeds(upload(context));
  await assertSucceeds(getBytes(ref(context.storage(), path)));
  await assertSucceeds(deleteObject(ref(context.storage(), path)));
});

test('未認証・未確認・別ユーザーは写真を保存・取得・削除できない', async () => {
  await assertSucceeds(upload(owner()));
  for (const context of [
    environment.unauthenticatedContext(),
    environment.authenticatedContext('alice', { email_verified: false }),
    environment.authenticatedContext('alice'),
    environment.authenticatedContext('bob', { email_verified: true }),
  ]) {
    await assertFails(getBytes(ref(context.storage(), path)));
    await assertFails(upload(context, path.replace('first', 'second')));
    await assertFails(deleteObject(ref(context.storage(), path)));
  }
});

test('画像以外・空ファイル・10MB超過・不正パスを拒否し10MBの境界を許可する', async () => {
  const context = owner();
  await assertFails(upload(context, path, bytes, 'text/plain'));
  await assertFails(upload(context, path, new Uint8Array()));
  await assertFails(upload(context, path, new Uint8Array(10 * 1024 * 1024 + 1)));
  await assertFails(upload(context, 'users/alice/unexpected/photo'));
  await assertFails(upload(context, path.replace('a'.repeat(64), 'bad')));
  await assertSucceeds(upload(context, path, new Uint8Array(10 * 1024 * 1024)));
});

test('確定済み記録の写真の上書き・削除を拒否し未参照の写真は回収できる', async () => {
  const context = owner();
  await assertSucceeds(upload(context));
  await environment.withSecurityRulesDisabled(async (admin) => {
    await setDoc(doc(admin.firestore(), 'users/alice/glucose_records/first'), { photoPaths: [path] });
  });
  await assertFails(upload(context));
  await assertFails(deleteObject(ref(context.storage(), path)));
  const unused = path.replace('a'.repeat(64), 'b'.repeat(64));
  await assertSucceeds(upload(context, unused));
  await assertSucceeds(deleteObject(ref(context.storage(), unused)));
});
