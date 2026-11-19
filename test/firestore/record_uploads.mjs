import { doc, runTransaction, serverTimestamp } from 'firebase/firestore';

export function compressedPhotoPath(userId = 'alice', recordId = 'first', hash = 'a'.repeat(64)) {
  return `users/${userId}/glucose_records/${recordId}/compressed/${hash}`;
}

function jstDay(date) {
  return new Date(date.getTime() + 9 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

export function reserveUpload(db, recordId, photoPaths = [], userId = 'alice') {
  const quota = doc(db, `users/${userId}/record_limits/current`);
  const upload = doc(db, `users/${userId}/record_uploads/${recordId}`);
  return runTransaction(db, async transaction => {
    const previous = (await transaction.get(quota)).data();
    const count = previous && jstDay(previous.updatedAt.toDate()) === jstDay(new Date())
      ? previous.count
      : 0;
    transaction.set(quota, { count: count + 1, lastRecordId: recordId, updatedAt: serverTimestamp() });
    transaction.set(upload, { photoPaths, createdAt: serverTimestamp() });
  });
}
