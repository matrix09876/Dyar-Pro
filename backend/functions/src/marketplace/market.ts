// سوق C2C (بيع وشراء) — البيع النهائي يمرّ من هنا: لا يُوثَق بالعميل في
// تغيير الحالة إلى sold ولا في احتساب عمولة المنصّة.
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logAction } from '../ops/utils';

const db = () => getFirestore();

/**
 * تعليم منتج السوق كمُباع (البائع أو admin) + قيد عمولة البيع:
 * commission = price * config/app.marketplaceCommissionPct (افتراضي 5) / 100
 * تُسجَّل بالسالب على البائع في `transactions` (type: 'commission').
 */
export const markProductSold = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { productId } = req.data as { productId?: string };
  if (!productId) throw new HttpsError('invalid-argument', 'productId required');

  const isAdmin = req.auth?.token.role === 'admin';
  const ref = db().doc(`marketProducts/${productId}`);

  const commission = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'product not found');
    const p = snap.data()!;
    if (!isAdmin && p.sellerUid !== uid) {
      throw new HttpsError('permission-denied', 'not your product');
    }
    if (p.status === 'sold') {
      throw new HttpsError('failed-precondition', 'already sold');
    }
    if (!isAdmin && p.status !== 'approved') {
      throw new HttpsError('failed-precondition', 'product not approved');
    }

    const cfg = await tx.get(db().doc('config/app'));
    const pct = cfg.data()?.marketplaceCommissionPct ?? 5;
    const fee = Math.round((p.price || 0) * pct / 100);

    tx.update(ref, { status: 'sold', soldAt: Timestamp.now() });
    tx.set(db().collection('transactions').doc(), {
      uid: p.sellerUid,
      type: 'commission',
      amount: -fee,
      marketProductId: productId,
      createdAt: Timestamp.now(),
    });
    return fee;
  });

  await logAction({
    category: 'business',
    action: `market product ${productId} sold (commission ${commission})`,
    by: uid,
    entity: productId,
  });
  return { ok: true, commission };
});
