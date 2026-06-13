// ديار B2B — طلب عرض سعر (RFQ، نمط Alibaba/سوق الجملة). التاجر (users.merchant)
// يطلب عرضًا لمنتج بكمية، والمورد (صاحب متجر الجملة) يردّ بسعر الوحدة وشروطه.
// حماية العمولة: كل عرض يحمل عمولة ديار محسوبة خادميًا (لا يمكن تجاوزها داخل
// التطبيق) — سجلّ مدقَّق لكل صفقة جملة.
//
// العقد:
//   rfqs/{rfqId}: {
//     merchantUid, storeId, storeName, productName, qty, note,
//     status: 'open'|'quoted'|'accepted'|'declined'|'expired',
//     quote?: { unitPrice, total, commissionPct, commission, validUntil,
//               terms, quotedBy, quotedAt },
//     createdAt, updatedAt }
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logAction } from '../ops/utils';
import { b2bCommission, DEFAULT_B2B_COMMISSION_PCT } from './commission';

const db = () => getFirestore();

/** التاجر يطلب عرض سعر لمنتج بكمية من مورد جملة. */
export const createRfq = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');

  // التحقق أن المستخدم تاجر B2B (users.merchant) — تمنحه الإدارة فقط
  const user = (await db().doc(`users/${uid}`).get()).data();
  if (user?.merchant !== true) {
    throw new HttpsError('permission-denied', 'B2B merchant account required');
  }

  const storeId = String(req.data?.storeId ?? '');
  const productName = String(req.data?.productName ?? '').trim();
  const qty = Math.round(Number(req.data?.qty ?? 0));
  const note = String(req.data?.note ?? '').slice(0, 500);
  if (!storeId || !productName || qty <= 0) {
    throw new HttpsError('invalid-argument', 'storeId, productName, qty required');
  }

  const store = (await db().doc(`stores/${storeId}`).get()).data();
  if (!store || store.status !== 'approved') {
    throw new HttpsError('failed-precondition', 'store not available');
  }

  const ref = await db().collection('rfqs').add({
    merchantUid: uid,
    storeId,
    storeName: store.name ?? '',
    productName,
    qty,
    note,
    status: 'open',
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });
  await logAction({
    category: 'business',
    action: `RFQ created (${productName} ×${qty}) for ${storeId}`,
    by: uid, entity: ref.id,
  });
  return { ok: true, rfqId: ref.id };
});

/** المورد (صاحب متجر الجملة) أو الإدارة يردّ بعرض سعر. */
export const quoteRfq = onCall(async (req) => {
  const uid = req.auth?.uid;
  const role = req.auth?.token?.role;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');

  const rfqId = String(req.data?.rfqId ?? '');
  const unitPrice = Math.round(Number(req.data?.unitPrice ?? 0)); // أغورة/وحدة
  const validHours = Math.min(720, Math.max(1, Math.round(Number(req.data?.validHours ?? 48))));
  const terms = String(req.data?.terms ?? '').slice(0, 500);
  if (!rfqId || unitPrice <= 0) {
    throw new HttpsError('invalid-argument', 'rfqId and unitPrice required');
  }

  const result = await db().runTransaction(async (tx) => {
    const rRef = db().doc(`rfqs/${rfqId}`);
    const rSnap = await tx.get(rRef);
    if (!rSnap.exists) throw new HttpsError('not-found', 'RFQ not found');
    const rfq = rSnap.data()!;
    if (!['open', 'quoted'].includes(rfq.status)) {
      throw new HttpsError('failed-precondition', 'RFQ not quotable');
    }

    // صلاحية: صاحب متجر الجملة المستهدف أو admin
    const store = (await tx.get(db().doc(`stores/${rfq.storeId}`))).data();
    if (role !== 'admin' && !(role === 'partner' && store?.ownerUid === uid)) {
      throw new HttpsError('permission-denied', 'not the supplier');
    }

    const qty = (rfq.qty ?? 0) as number;
    const total = unitPrice * qty;
    const commissionPct = (store?.commissionPct ?? DEFAULT_B2B_COMMISSION_PCT) as number;
    const commission = b2bCommission(total, commissionPct);

    tx.update(rRef, {
      status: 'quoted',
      quote: {
        unitPrice, total, commissionPct, commission,
        terms,
        quotedBy: uid,
        quotedAt: Timestamp.now(),
        validUntil: Timestamp.fromMillis(Date.now() + validHours * 3600_000),
      },
      updatedAt: Timestamp.now(),
    });
    return { total, commission, commissionPct };
  });

  await logAction({
    category: 'business',
    action: `RFQ ${rfqId} quoted (total ${(result.total / 100).toFixed(2)}, ` +
      `commission ${(result.commission / 100).toFixed(2)} @${result.commissionPct}%)`,
    by: uid, entity: rfqId,
  });
  return { ok: true, ...result };
});

/** التاجر يقبل/يرفض العرض. القبول يثبّت الصفقة (العمولة محفوظة خادميًا). */
export const respondRfq = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const rfqId = String(req.data?.rfqId ?? '');
  const accept = req.data?.accept === true;
  if (!rfqId) throw new HttpsError('invalid-argument', 'rfqId required');

  await db().runTransaction(async (tx) => {
    const rRef = db().doc(`rfqs/${rfqId}`);
    const rSnap = await tx.get(rRef);
    if (!rSnap.exists) throw new HttpsError('not-found', 'RFQ not found');
    const rfq = rSnap.data()!;
    if (rfq.merchantUid !== uid) throw new HttpsError('permission-denied', 'not your RFQ');
    if (rfq.status !== 'quoted') throw new HttpsError('failed-precondition', 'no active quote');
    const validUntil = rfq.quote?.validUntil as Timestamp | undefined;
    if (accept && validUntil && validUntil.toMillis() < Date.now()) {
      throw new HttpsError('failed-precondition', 'quote expired');
    }

    tx.update(rRef, {
      status: accept ? 'accepted' : 'declined',
      respondedAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });

    // حماية العمولة: عند القبول نسجّل عمولة ديار كمعاملة مدقَّقة
    if (accept && rfq.quote?.commission) {
      tx.set(db().collection('transactions').doc(), {
        uid: rfq.quote.quotedBy ?? null,
        type: 'b2b_commission',
        amount: rfq.quote.commission,
        meta: { rfqId, storeId: rfq.storeId, merchantUid: uid, total: rfq.quote.total },
        createdAt: Timestamp.now(),
      });
    }
  });

  await logAction({
    category: 'business',
    action: `RFQ ${rfqId} ${accept ? 'accepted' : 'declined'}`,
    by: uid, entity: rfqId,
  });
  return { ok: true, status: accept ? 'accepted' : 'declined' };
});

/** تنظيف العروض المنتهية — مجدول يوميًا (use FieldValue to mark expired). */
export const expireRfqs = onCall(async (req) => {
  // أداة إدارية بسيطة (يمكن تحويلها لمجدول لاحقًا)
  if (req.auth?.token?.role !== 'admin') {
    throw new HttpsError('permission-denied', 'admin only');
  }
  const now = Timestamp.now();
  const snap = await db().collection('rfqs').where('status', '==', 'quoted').limit(450).get();
  let batch = db().batch();
  let n = 0;
  for (const d of snap.docs) {
    const v = d.data().quote?.validUntil as Timestamp | undefined;
    if (v && v.toMillis() < now.toMillis()) {
      batch.update(d.ref, { status: 'expired', updatedAt: now });
      n++;
    }
  }
  if (n > 0) await batch.commit();
  return { ok: true, expired: n };
});
