// ديار Meals — بدل وجبات الشركات (نمط 10bis/Cibus، أكبر فجوة بالسوق
// الإسرائيلي). شركة تموّل ميزانية يومية/شهرية لموظفيها، تُصرف داخل ديار
// (توصيل/استلام/دفع بالمطعم) بحدود السياسة. الرصيد use-it-or-lose-it.
//
// العقد:
//   organizations/{orgId}: { name, active, budget:{amount, period:'daily'|'monthly'},
//                            members:[uid], allowedDietary?:[..], policy?:{...} }
//   mealAccounts/{uid}:     { orgId, balance(agorot), period, lastResetAt, ledger? }
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logAction } from '../ops/utils';

const db = () => getFirestore();

/**
 * الدفع من ميزانية الوجبات لطلب — خادميًا بالكامل، transaction واحدة:
 * تحقق الرصيد + خصمه + وسم الطلب paid. الفائض (إن المبلغ > الرصيد)
 * يُرفض هنا (يُدفع الفرق بوسيلة أخرى في تدفّق العميل).
 */
export const payWithMealBudget = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const orderId = String(req.data?.orderId ?? '');
  if (!orderId) throw new HttpsError('invalid-argument', 'orderId required');

  const result = await db().runTransaction(async (tx) => {
    const oRef = db().doc(`orders/${orderId}`);
    const oSnap = await tx.get(oRef);
    if (!oSnap.exists) throw new HttpsError('not-found', 'order not found');
    const order = oSnap.data()!;
    if (order.customerUid !== uid) {
      throw new HttpsError('permission-denied', 'not your order');
    }
    if (order.payment?.status === 'paid') {
      throw new HttpsError('failed-precondition', 'already paid');
    }
    const total = (order.pricing?.total ?? 0) as number;

    const aRef = db().doc(`mealAccounts/${uid}`);
    const aSnap = await tx.get(aRef);
    if (!aSnap.exists) throw new HttpsError('failed-precondition', 'no meal account');
    const acc = aSnap.data()!;
    const balance = (acc.balance ?? 0) as number;
    if (balance < total) {
      throw new HttpsError('failed-precondition', 'insufficient meal budget');
    }

    tx.update(aRef, {
      balance: FieldValue.increment(-total),
      ledger: FieldValue.arrayUnion({
        orderId, amount: -total, at: Timestamp.now(),
      }),
    });
    tx.update(oRef, {
      'payment.method': 'meal_budget',
      'payment.status': 'paid',
      'payment.orgId': acc.orgId ?? null,
      'payment.paidAt': Timestamp.now(),
    });
    tx.set(db().collection('transactions').doc(), {
      uid, orderId, type: 'meal_budget', amount: total,
      meta: { orgId: acc.orgId ?? null },
      createdAt: Timestamp.now(),
    });
    return { total, remaining: balance - total };
  });

  await logAction({
    category: 'business',
    action: `meal budget paid (-${(result.total / 100).toFixed(2)}) for ${orderId}`,
    by: uid, entity: orderId,
  });
  return { ok: true, ...result };
});

/**
 * منح/تجديد ميزانيات الوجبات — مجدول يوميًا. use-it-or-lose-it:
 * يضبط الرصيد = مبلغ السياسة (لا يجمع). الشهري يُجدَّد يوم 1 فقط.
 */
export const grantMealBudgets = onSchedule(
  { schedule: '5 0 * * *', timeZone: 'Asia/Jerusalem' },
  async () => {
    const today = new Date();
    const isFirst = today.getDate() === 1;
    const orgs = await db().collection('organizations')
      .where('active', '==', true).get();

    for (const org of orgs.docs) {
      const o = org.data();
      const period = o.budget?.period ?? 'daily';
      if (period === 'monthly' && !isFirst) continue; // الشهري يوم 1 فقط
      const amount = (o.budget?.amount ?? 0) as number;
      const members: string[] = Array.isArray(o.members) ? o.members : [];

      // دفعات batched (≤450 كتابة لكل دفعة)
      let batch = db().batch();
      let n = 0;
      for (const uid of members) {
        batch.set(db().doc(`mealAccounts/${uid}`), {
          orgId: org.id,
          balance: amount, // use-it-or-lose-it: ضبط لا جمع
          period,
          lastResetAt: Timestamp.now(),
        }, { merge: true });
        if (++n % 450 === 0) { await batch.commit(); batch = db().batch(); }
      }
      if (n % 450 !== 0) await batch.commit();
    }
  },
);

/**
 * ديار Meals — الدفع بالمطعم (scan-to-pay، نمط 10bis):
 * الزبون يولّد رمزًا قصيرًا (صالح دقيقتين)، والتاجر يصرفه بإدخاله + المبلغ.
 */
function randomCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/** الزبون يولّد رمز POS لميزانية وجباته (صالح 2 دقيقة). */
export const generateMealPosCode = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const acc = (await db().doc(`mealAccounts/${uid}`).get()).data();
  if (!acc || (acc.balance ?? 0) <= 0) {
    throw new HttpsError('failed-precondition', 'no meal budget');
  }
  const code = randomCode();
  await db().doc(`posCodes/${code}`).set({
    uid, orgId: acc.orgId ?? null, status: 'active',
    createdAt: Timestamp.now(),
    expiresAt: Timestamp.fromMillis(Date.now() + 2 * 60_000),
  });
  return { code, balance: acc.balance ?? 0, expiresInSec: 120 };
});

/** التاجر يصرف رمز POS بمبلغ — يخصم من ميزانية الزبون (transaction). */
export const redeemMealPosCode = onCall(async (req) => {
  const merchant = req.auth?.uid;
  const role = req.auth?.token?.role;
  if (!merchant || (role !== 'partner' && role !== 'admin')) {
    throw new HttpsError('permission-denied', 'merchant only');
  }
  const code = String(req.data?.code ?? '').trim();
  const amount = Math.round(Number(req.data?.amount ?? 0)); // أغورة
  const storeId = req.data?.storeId ? String(req.data.storeId) : null;
  if (!code || amount <= 0) {
    throw new HttpsError('invalid-argument', 'code and amount required');
  }

  const result = await db().runTransaction(async (tx) => {
    const cRef = db().doc(`posCodes/${code}`);
    const cSnap = await tx.get(cRef);
    if (!cSnap.exists) throw new HttpsError('not-found', 'invalid code');
    const c = cSnap.data()!;
    if (c.status !== 'active') throw new HttpsError('failed-precondition', 'code used');
    if ((c.expiresAt as Timestamp).toMillis() < Date.now()) {
      throw new HttpsError('failed-precondition', 'code expired');
    }
    const aRef = db().doc(`mealAccounts/${c.uid}`);
    const aSnap = await tx.get(aRef);
    const balance = (aSnap.data()?.balance ?? 0) as number;
    if (balance < amount) throw new HttpsError('failed-precondition', 'insufficient budget');

    tx.update(aRef, {
      balance: FieldValue.increment(-amount),
      ledger: FieldValue.arrayUnion({ posCode: code, amount: -amount, storeId, at: Timestamp.now() }),
    });
    tx.update(cRef, { status: 'used', usedBy: merchant, amount, usedAt: Timestamp.now() });
    tx.set(db().collection('transactions').doc(), {
      uid: c.uid, type: 'meal_pos', amount, gateway: 'meal_budget',
      meta: { orgId: c.orgId ?? null, storeId, merchant }, createdAt: Timestamp.now(),
    });
    return { uid: c.uid, remaining: balance - amount };
  });

  await logAction({
    category: 'business',
    action: `meal POS redeemed (-${(amount / 100).toFixed(2)}) by ${merchant}`,
    by: merchant,
  });
  return { ok: true, ...result };
});
