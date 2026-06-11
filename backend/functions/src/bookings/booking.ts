// الحجوزات — طاولة مطعم أو موعد خدمة (حلاق/صالون/طبيب/محامٍ/محاسب..):
// الإنشاء وتحوّلات الحالة الحسّاسة تمرّ من هنا بنفس نمط orders/lifecycle.ts.
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { BOOKING_TRANSITIONS, type Booking, type BookingStatus } from '../types';
import { logAction } from '../ops/utils';

const db = () => getFirestore();

// إنشاء حجز موثّق: المتجر approved، الموعد مستقبلي، والرسوم من إعدادات
// المتجر (store.dineOut.reservationCost) — لا يُوثَق برسوم العميل.
export const createBooking = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { storeId, type, slot, partySize = 1, tableId, notes, reminder = true } = req.data;
  if (!storeId || !slot) {
    throw new HttpsError('invalid-argument', 'storeId and slot required');
  }
  if (type !== 'table' && type !== 'service') {
    throw new HttpsError('invalid-argument', 'type must be table or service');
  }
  const size = Number(partySize);
  if (!Number.isInteger(size) || size < 1 || size > 50) {
    throw new HttpsError('invalid-argument', 'invalid partySize');
  }
  // slot: epoch ms — يجب أن يكون مستقبليًا
  const slotMs = Number(slot);
  if (!Number.isFinite(slotMs) || slotMs <= Date.now()) {
    throw new HttpsError('invalid-argument', 'slot must be in the future');
  }

  const storeSnap = await db().doc(`stores/${storeId}`).get();
  if (!storeSnap.exists) throw new HttpsError('not-found', 'store not found');
  const store = storeSnap.data()!;
  if (store.status !== 'approved') {
    throw new HttpsError('failed-precondition', 'store unavailable');
  }

  const fee = (store.dineOut?.reservationCost ?? 0) as number;

  const now = Timestamp.now();
  const booking: Partial<Booking> = {
    customerUid: uid, storeId, type,
    partySize: size,
    ...(tableId ? { tableId } : {}),
    ...(notes ? { notes: String(notes) } : {}),
    slot: Timestamp.fromMillis(slotMs),
    reminder: reminder !== false, // التذكير قبل 30 دقيقة افتراضيًا
    fee,
    status: 'pending',
    createdAt: now, updatedAt: now,
  };
  const ref = await db().collection('bookings').add(booking);
  return { bookingId: ref.id, fee };
});

// تغيير حالة الحجز مع فرض state machine + صلاحيات الدور (نمط الطلبات):
// التاجر صاحب المتجر/الإدارة يديران الحجز، والزبون يلغي حجزه فقط.
export const updateBookingStatus = onCall(async (req) => {
  const uid = req.auth?.uid;
  const role = req.auth?.token.role;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { bookingId, status } = req.data as { bookingId: string; status: BookingStatus };

  const ref = db().doc(`bookings/${bookingId}`);
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'booking not found');
    const booking = snap.data() as Booking;

    const allowed = BOOKING_TRANSITIONS[booking.status] || [];
    if (!allowed.includes(status)) {
      throw new HttpsError('failed-precondition', `cannot go ${booking.status} → ${status}`);
    }
    // صلاحيات: من يملك الحق في هذا التحوّل
    const partnerStatuses: BookingStatus[] =
      ['confirmed', 'seated', 'completed', 'cancelled', 'no_show'];
    let ownsStore = false;
    if (role === 'partner') {
      const store = (await tx.get(db().doc(`stores/${booking.storeId}`))).data();
      ownsStore = store?.ownerUid === uid;
    }
    const ok =
      role === 'admin' ||
      (role === 'partner' && ownsStore && partnerStatuses.includes(status)) ||
      (status === 'cancelled' && booking.customerUid === uid);
    if (!ok) throw new HttpsError('permission-denied', 'not allowed for this transition');

    tx.update(ref, { status, updatedAt: FieldValue.serverTimestamp() });
  });

  // تدقيق بعد نجاح الحركة (خارج الـ transaction)
  await logAction({
    category: 'orders',
    action: `booking ${bookingId} → ${status}`,
    by: uid,
    entity: bookingId,
  });
  return { ok: true };
});
