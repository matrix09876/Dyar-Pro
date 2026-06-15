// المهام المجدولة: تصفير أرباح السائقين، تذكير الحجوزات قبل 30 دقيقة،
// والتسوية الشهرية عبر محرك العمولات الذكية (ops/commission.ts):
// override المتجر ← خدمات 6% ← قواعد commissionRules ← شرائح 15/13.5/12%.
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  DEFAULT_SERVICE_PCT, DEFAULT_TIERS, resolveCommissionPct,
  type CommissionCity, type CommissionRule, type CommissionTier,
} from './commission';
import { logAction } from './utils';

const db = () => getFirestore();
const TZ = 'Asia/Jerusalem';

/** تصفير أرباح اليوم لكل السائقين منتصف الليل (والأسبوع يوم الاثنين). */
export const resetDriverEarnings = onSchedule(
  { schedule: '0 0 * * *', timeZone: TZ },
  async () => {
    const isMonday = new Date().getDay() === 1;
    const drivers = await db().collection('drivers').get();
    const batch = db().batch();
    for (const d of drivers.docs) {
      batch.update(d.ref, {
        'earnings.today': 0,
        ...(isMonday ? { 'earnings.week': 0 } : {}),
      });
    }
    await batch.commit();
  },
);

/** تذكير الحجوزات: FCM قبل الموعد بـ30 دقيقة (نافذة 25-35 د، كل 5 د). */
export const bookingReminders = onSchedule(
  { schedule: 'every 5 minutes', timeZone: TZ },
  async () => {
    const now = Date.now();
    const from = Timestamp.fromMillis(now + 25 * 60_000);
    const to = Timestamp.fromMillis(now + 35 * 60_000);
    const snap = await db().collection('bookings')
      .where('reminder', '==', true)
      .where('status', 'in', ['pending', 'confirmed'])
      .where('slot', '>=', from)
      .where('slot', '<=', to)
      .get();

    for (const b of snap.docs) {
      if (b.data().reminderSent) continue;
      const user = await db().doc(`users/${b.data().customerUid}`).get();
      const tokens = (user.data()?.fcmTokens as string[]) ?? [];
      await Promise.all(tokens.map((token) =>
        getMessaging().send({
          token,
          notification: {
            title: 'ديار',
            body: 'تذكير: حجزك بعد 30 دقيقة ⏰',
          },
          data: { bookingId: b.id, type: 'booking_reminder' },
        }).catch(() => null)));
      await b.ref.update({ reminderSent: true });
    }
  },
);

/**
 * التسوية الشهرية: عدد طلبات الشهر المنصرم لكل متجر → شريحة العمولة
 * (config/app.commissionTiers أو override المتجر) → transaction + log.
 */
export const monthlySettlement = onSchedule(
  { schedule: '0 3 1 * *', timeZone: TZ },
  async () => {
    const nowD = new Date();
    const monthStart = new Date(nowD.getFullYear(), nowD.getMonth() - 1, 1);
    const monthEnd = new Date(nowD.getFullYear(), nowD.getMonth(), 1);

    const cfg = (await db().doc('config/app').get()).data() ?? {};
    const tiers: CommissionTier[] = cfg.commissionTiers ?? DEFAULT_TIERS;
    const servicePct: number = cfg.serviceProvidersPct ?? DEFAULT_SERVICE_PCT;
    const rules: CommissionRule[] = cfg.commissionRules ?? [];

    // خريطة المدن لمطابقة قواعد city/country في محرك العمولات
    const citiesSnap = await db().collection('cities').get();
    const cities = new Map<string, CommissionCity>(citiesSnap.docs.map((c) =>
      [c.id, { id: c.id, country: c.data().country as string | undefined }]));

    const stores = await db().collection('stores')
      .where('status', '==', 'approved').get();

    for (const st of stores.docs) {
      const s = st.data();
      const orders = await db().collection('orders')
        .where('storeId', '==', st.id)
        .where('status', '==', 'delivered')
        .where('createdAt', '>=', Timestamp.fromDate(monthStart))
        .where('createdAt', '<', Timestamp.fromDate(monthEnd))
        .get();
      if (orders.empty) continue;

      const count = orders.size;
      const gross = orders.docs
        .reduce((sum, o) => sum + (o.data().pricing?.subtotal ?? 0), 0);

      // محرك العمولات الذكية: override ← خدمات ← قواعد ← شرائح الحجم
      const pct = resolveCommissionPct({
        store: {
          id: st.id,
          type: s.type,
          cityId: s.cityId,
          commissionPct:
            typeof s.commissionPct === 'number' ? s.commissionPct : undefined,
        },
        city: s.cityId ? cities.get(s.cityId) ?? null : null,
        at: nowD,
        rules, tiers, servicePct,
        monthlyOrders: count,
      });
      const commission = Math.round((gross * pct) / 100);

      await db().collection('transactions').add({
        uid: s.ownerUid,
        type: 'commission',
        amount: -commission,
        period: `${monthStart.getFullYear()}-${monthStart.getMonth() + 1}`,
        meta: { storeId: st.id, orders: count, gross, pct },
        createdAt: Timestamp.now(),
      });
      await logAction({
        category: 'business',
        action: `monthly settlement: ${count} orders, ${pct}% = ₪${(commission / 100).toFixed(2)}`,
        by: 'system',
        entity: st.id,
      });
    }
  },
);
