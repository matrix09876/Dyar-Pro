// الطرود: إنشاء شحنة برمز تسليم OTP (ميزة "حماية ديار") + تأكيد التسليم.
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

const db = () => getFirestore();

function otp(): string {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

// التعرفة حسب المسار (packageRoutes): أساس + لكل كغ + لكل م³ —
// مطابق للوحة الحالية (مسار إسرائيل: 1000كغ/6م³، Base 50 /kg 100 /m³ 100).
export const createParcel = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { sender, recipient, weightKg = 1, volumeM3 = 0, routeId } = req.data;
  if (!sender?.name || !recipient?.name) {
    throw new HttpsError('invalid-argument', 'sender/recipient required');
  }

  let total: number;
  let routeName: string | null = null;
  let route: FirebaseFirestore.DocumentData | undefined;
  if (routeId) {
    const snap = await db().doc(`packageRoutes/${routeId}`).get();
    route = snap.exists ? snap.data() : undefined;
  } else {
    const snap = await db().collection('packageRoutes')
      .where('active', '==', true).limit(1).get();
    route = snap.docs[0]?.data();
  }

  if (route) {
    if (weightKg > (route.maxWeightKg ?? 1000)) {
      throw new HttpsError('invalid-argument', `max ${route.maxWeightKg}kg`);
    }
    if (volumeM3 > (route.maxVolumeM3 ?? 6)) {
      throw new HttpsError('invalid-argument', `max ${route.maxVolumeM3}m3`);
    }
    const r = route.rates ?? {};
    total = Math.round(
      (r.base ?? 0) + weightKg * (r.perKg ?? 0) + volumeM3 * (r.perM3 ?? 0),
    );
    routeName = route.name ?? null;
  } else {
    // لا مسارات مضبوطة بعد — تعرفة افتراضية
    if (weightKg > 1000) throw new HttpsError('invalid-argument', 'max 1000kg');
    total = 1500 + Math.round(weightKg * 30);
  }
  const code = otp();
  const now = Timestamp.now();
  const ref = await db().collection('parcels').add({
    senderUid: uid, sender, recipient,
    route: routeName,
    size: { weightKg, volumeM3 },
    status: 'pending',
    pricing: { total },
    deliveryOtp: code, // يُعرض للمستلم فقط عبر تطبيق المرسل
    payment: { method: req.data.paymentMethod ?? 'cash', status: 'pending' },
    createdAt: now, updatedAt: now,
  });
  return { parcelId: ref.id, total, deliveryOtp: code };
});

// السائق يؤكد التسليم برمز الـ OTP من المستلم
export const confirmParcelDelivery = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { parcelId, otp: code } = req.data;
  const ref = db().doc(`parcels/${parcelId}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'parcel not found');
  const p = snap.data()!;
  if (p.driverUid !== uid) throw new HttpsError('permission-denied', 'not your parcel');
  if (p.deliveryOtp !== code) throw new HttpsError('failed-precondition', 'wrong OTP');
  await ref.update({ status: 'delivered', deliveredAt: Timestamp.now() });
  await db().doc(`drivers/${uid}`).update({ activeOrderId: null });
  return { ok: true };
});
