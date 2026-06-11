// التاكسي: طلب مشوار بتسعير من الخادم (أساس + لكل كم + معامل ذروة Surge).
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import type { GeoPoint } from '../types';

const db = () => getFirestore();

function distanceKm(a: GeoPoint, b: GeoPoint): number {
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const h = Math.sin(dLat / 2) ** 2 +
    Math.cos((a.lat * Math.PI) / 180) * Math.cos((b.lat * Math.PI) / 180) *
    Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

// تعرفة بالأغورة: أساس + لكل كم، حسب الفئة
const TIERS: Record<string, { base: number; perKm: number }> = {
  standard: { base: 1200, perKm: 350 },
  comfort: { base: 1800, perKm: 520 },
  xl: { base: 2400, perKm: 650 },
};

// معامل الذروة: نسبة المشاوير الباحثة إلى السائقين المتاحين
async function surgeFactor(): Promise<number> {
  const cfg = await db().doc('config/app').get();
  if (cfg.data()?.surgeEnabled === false) return 1;
  const [searching, online] = await Promise.all([
    db().collection('rides').where('status', '==', 'searching').count().get(),
    db().collection('drivers').where('isOnline', '==', true).count().get(),
  ]);
  const demand = searching.data().count;
  const supply = Math.max(1, online.data().count);
  const ratio = demand / supply;
  if (ratio > 2) return 1.5;
  if (ratio > 1) return 1.25;
  return 1;
}

export const requestRide = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { pickup, dropoff, tier = 'standard' } = req.data as {
    pickup: GeoPoint & { address?: string };
    dropoff: GeoPoint & { address?: string };
    tier: string;
  };
  if (!pickup?.lat || !dropoff?.lat) {
    throw new HttpsError('invalid-argument', 'pickup/dropoff required');
  }
  const t = TIERS[tier] ?? TIERS.standard;
  const km = distanceKm(pickup, dropoff);
  const surge = await surgeFactor();
  const total = Math.round((t.base + t.perKm * km) * surge);

  const now = Timestamp.now();
  const ref = await db().collection('rides').add({
    customerUid: uid,
    pickup, dropoff, tier,
    status: 'searching',
    pricing: { base: t.base, perKm: t.perKm, surge, total },
    distanceKm: Math.round(km * 100) / 100,
    payment: { method: req.data.paymentMethod ?? 'cash', status: 'pending' },
    createdAt: now, updatedAt: now,
  });
  return { rideId: ref.id, total, surge, distanceKm: km };
});

// قبول السائق للمشوار
export const acceptRide = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid || req.auth?.token.role !== 'driver') {
    throw new HttpsError('permission-denied', 'drivers only');
  }
  const { rideId } = req.data;
  await db().runTransaction(async (tx) => {
    const ref = db().doc(`rides/${rideId}`);
    const snap = await tx.get(ref);
    if (!snap.exists || snap.data()!.status !== 'searching') {
      throw new HttpsError('failed-precondition', 'ride unavailable');
    }
    tx.update(ref, { driverUid: uid, status: 'accepted', updatedAt: Timestamp.now() });
    tx.update(db().doc(`drivers/${uid}`), { activeOrderId: `ride:${rideId}` });
  });
  return { ok: true };
});
