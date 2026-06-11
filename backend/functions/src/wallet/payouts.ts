// السحب الفوري للسائق (ميزة "نجفف سائقي HAAT"): حتى 80% من إجمالي
// الأرباح ناقص الطلبات المعلقة — يُنشئ طلب سحب تعتمده الإدارة.
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logAction } from '../ops/utils';

const db = () => getFirestore();

export const requestPayout = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid || req.auth?.token.role !== 'driver') {
    throw new HttpsError('permission-denied', 'drivers only');
  }
  const amount = Math.round(Number(req.data?.amount ?? 0));
  if (amount <= 0) throw new HttpsError('invalid-argument', 'amount required');

  const driver = await db().doc(`drivers/${uid}`).get();
  const total = (driver.data()?.earnings?.total ?? 0) as number;

  const pendingSnap = await db().collection('payoutRequests')
    .where('uid', '==', uid).where('status', '==', 'pending').get();
  const pending = pendingSnap.docs
    .reduce((s, d) => s + ((d.data().amount ?? 0) as number), 0);

  const available = Math.floor(total * 0.8) - pending;
  if (amount > available) {
    throw new HttpsError('failed-precondition', `max ${available}`);
  }

  const ref = await db().collection('payoutRequests').add({
    uid, amount, status: 'pending', createdAt: Timestamp.now(),
  });
  await logAction({
    category: 'users',
    action: `payout requested ₪${(amount / 100).toFixed(2)}`,
    by: uid, entity: ref.id,
  });
  return { ok: true, requestId: ref.id, available: available - amount };
});
