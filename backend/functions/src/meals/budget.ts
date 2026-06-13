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
