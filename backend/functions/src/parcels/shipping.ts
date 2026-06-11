// الطرود: إنشاء شحنة برمز تسليم OTP (ميزة "حماية ديار") + تأكيد التسليم.
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

const db = () => getFirestore();

function otp(): string {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

// تعرفة بسيطة: أساس 1500 أغورة + 30 لكل كغم (تُضبط من config لاحقًا)
export const createParcel = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { sender, recipient, weightKg = 1 } = req.data;
  if (!sender?.name || !recipient?.name) {
    throw new HttpsError('invalid-argument', 'sender/recipient required');
  }
  if (weightKg > 1000) {
    throw new HttpsError('invalid-argument', 'max 1000kg');
  }
  const total = 1500 + Math.round(weightKg * 30);
  const code = otp();
  const now = Timestamp.now();
  const ref = await db().collection('parcels').add({
    senderUid: uid, sender, recipient,
    size: { weightKg },
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
