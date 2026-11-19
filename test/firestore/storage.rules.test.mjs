import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getBytes, deleteObject, listAll } from 'firebase/storage';
import { doc, setDoc, Timestamp } from 'firebase/firestore';
import { compressedPhotoPath, reserveUpload } from './record_uploads.mjs';

let environment;
const path = compressedPhotoPath();
const bytes = new Uint8Array([255, 216, 255, 217]);
const owner = () => environment.authenticatedContext('alice', { email_verified: true });
const upload = (context, objectPath = path, data = bytes, contentType = 'image/jpeg') =>
  uploadBytes(ref(context.storage(), objectPath), data, { contentType });
const reserve = (context, photos = [path]) => reserveUpload(context.firestore(), 'first', photos);

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
  await assertSucceeds(reserve(context));
  await assertSucceeds(upload(context));
  await assertSucceeds(getBytes(ref(context.storage(), path)));
  await assertSucceeds(deleteObject(ref(context.storage(), path)));
});

test('未認証・未確認・別ユーザーは写真を保存・取得・削除できない', async () => {
  await assertSucceeds(reserve(owner()));
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
  await assertFails(listAll(ref(owner().storage(), 'users/alice/glucose_records/first/compressed')));
});

test('JPEG以外・空ファイル・256KiB超過・予約外のパスを拒否し、容量の境界を許可する', async () => {
  const context = owner();
  await assertFails(upload(context));
  await assertSucceeds(reserve(context));
  await assertFails(upload(context, path, bytes, 'text/plain'));
  await assertFails(upload(context, path, bytes, 'image/png'));
  await assertFails(upload(context, path, new Uint8Array()));
  await assertFails(upload(context, path, new Uint8Array(256 * 1024 + 1)));
  await assertFails(upload(context, 'users/alice/unexpected/photo'));
  await assertFails(upload(context, path.replace('a'.repeat(64), 'bad')));
  await assertFails(upload(context, compressedPhotoPath('alice', 'first', 'b'.repeat(64))));
  await assertFails(uploadBytes(ref(context.storage(), path), bytes, {
    contentType: 'image/jpeg', customMetadata: { extra: 'injected' },
  }));
  await assertSucceeds(upload(context, path, new Uint8Array(256 * 1024)));
});

test('確定済み記録の写真の追加・上書き・削除を拒否する', async () => {
  const context = owner();
  const unused = compressedPhotoPath('alice', 'first', 'b'.repeat(64));
  await assertSucceeds(reserve(context, [path, unused]));
  await assertSucceeds(upload(context));
  await environment.withSecurityRulesDisabled(async (admin) => {
    await setDoc(doc(admin.firestore(), 'users/alice/glucose_records/first'), { photoPaths: [path] });
  });
  await assertFails(upload(context));
  await assertFails(deleteObject(ref(context.storage(), path)));
  await assertFails(upload(context, unused));
});

test('旧形式の写真は本人の取得を許可し、新規作成を拒否する', async () => {
  const legacy = path.replace('/compressed/', '/photos/');
  await environment.withSecurityRulesDisabled(admin => upload(admin, legacy, bytes, 'image/png'));
  await assertSucceeds(getBytes(ref(owner().storage(), legacy)));
  await assertFails(getBytes(ref(environment.unauthenticatedContext().storage(), legacy)));
  await assertFails(upload(owner(), legacy.replace('first', 'second'), bytes, 'image/png'));
});

test('前日の予約で追加アップロードはできず、未確定の写真は回収できる', async () => {
  const context = owner();
  const unused = compressedPhotoPath('alice', 'first', 'b'.repeat(64));
  await assertSucceeds(reserve(context, [path, unused]));
  await assertSucceeds(upload(context));
  await environment.withSecurityRulesDisabled(admin =>
    setDoc(doc(admin.firestore(), 'users/alice/record_uploads/first'), {
      photoPaths: [path, unused],
      createdAt: Timestamp.fromMillis(Date.now() - 86400000),
    }));
  await assertFails(upload(context, unused));
  await assertSucceeds(deleteObject(ref(context.storage(), path)));
});
