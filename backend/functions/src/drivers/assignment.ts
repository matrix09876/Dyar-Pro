// التعيين الذكي للسائق: عند جاهزية الطلب، يبحث عن أقرب سائق متاح أونلاين.
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import type { GeoPoint } from '../types';

const db = () => getFirestore();

// مسافة هافرساين بالكيلومتر
function distanceKm(a: GeoPoint, b: GeoPoint): number {
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const lat1 = (a.lat * Math.PI) / 180;
  const lat2 = (b.lat * Math.PI) / 180;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

export const autoAssignNearestDriver = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  // فقط عند الانتقال إلى ready وبدون سائق معيّن
  if (!(before.status !== 'ready' && after.status === 'ready' && !after.driverUid)) return;

  // مفتاح "Assignment" من لوحة التحكم — إيقافه يحوّل للإسناد اليدوي
  const cfg = await db().doc('config/app').get();
  if (cfg.data()?.autoAssign === false) return;

  const storeSnap = await db().doc(`stores/${after.storeId}`).get();
  const storeLoc = storeSnap.data()?.location as GeoPoint | undefined;
  if (!storeLoc) return;

  const driversSnap = await db().collection('drivers')
    .where('isOnline', '==', true)
    .where('status', '==', 'approved')
    .get();

  const candidates = driversSnap.docs
    .filter((d) => !d.data().activeOrderId && d.data().currentLocation)
    .map((d) => ({ id: d.id, dist: distanceKm(storeLoc, d.data().currentLocation) }))
    .sort((a, b) => a.dist - b.dist);

  if (candidates.length === 0) return; // لا سائق متاح — تبقى في ready للإسناد اليدوي
  const best = candidates[0];

  await db().doc(`orders/${event.params.orderId}`).update({
    driverUid: best.id, status: 'assigned',
    timeline: FieldValue.arrayUnion({ status: 'assigned', at: Timestamp.now(), by: 'auto' }),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db().doc(`drivers/${best.id}`).update({ activeOrderId: event.params.orderId });
});
