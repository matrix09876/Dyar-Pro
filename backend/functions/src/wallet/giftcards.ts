// استرداد بطاقة هدية — خادميًا بالكامل (إغلاق C7 من الـ Audit):
// تحقق + وسم redeemed + زيادة رصيد المحفظة + حركة مالية، في transaction واحدة.
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logAction } from '../ops/utils';

const db = () => getFirestore();

export const redeemGiftCard = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const code = String(req.data?.code ?? '').trim().toUpperCase();
  if (!code) throw new HttpsError('invalid-argument', 'code required');

  const amount = await db().runTransaction(async (tx) => {
    const q = await tx.get(
      db().collection('giftcards')
        .where('code', '==', code)
        .where('status', '==', 'active')
        .limit(1),
    );
    if (q.empty) throw new HttpsError('not-found', 'invalid gift card');
    const card = q.docs[0];
    const balance = (card.data().balance ?? card.data().amount ?? 0) as number;
    if (balance <= 0) throw new HttpsError('failed-precondition', 'empty card');

    tx.update(card.ref, {
      status: 'redeemed',
      redeemedBy: uid,
      redeemedAt: Timestamp.now(),
      balance: 0,
    });
    tx.update(db().doc(`users/${uid}`), {
      walletBalance: FieldValue.increment(balance),
    });
    tx.set(db().collection('transactions').doc(), {
      uid, type: 'topup', amount: balance,
      meta: { giftcard: card.id },
      createdAt: Timestamp.now(),
    });
    return balance;
  });

  await logAction({
    category: 'users',
    action: `gift card redeemed (+${(amount / 100).toFixed(2)})`,
    by: uid,
  });
  return { ok: true, amount };
});
