// دورة حياة الطلب — كل تحوّلات الحالة الحسّاسة تمرّ من هنا مع تدقيق كامل.
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { ORDER_TRANSITIONS, type Order, type OrderStatus } from '../types';

const db = () => getFirestore();

function shortCode(): string {
  return 'DY' + Math.random().toString(36).slice(2, 7).toUpperCase();
}

// إنشاء طلب موثّق: السعر يُعاد احتسابه من الخادم (لا يُوثَق بسعر العميل).
export const createOrder = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  // scheduledFor: جدولة التوصيل (اختياري) — ISO timestamp بالمللي ثانية
  const { storeId, items, type, address, couponCode, tip = 0, scheduledFor } = req.data;
  if (!storeId || !Array.isArray(items) || items.length === 0) {
    throw new HttpsError('invalid-argument', 'storeId and items required');
  }

  const storeSnap = await db().doc(`stores/${storeId}`).get();
  if (!storeSnap.exists) throw new HttpsError('not-found', 'store not found');
  const store = storeSnap.data()!;
  if (store.status !== 'approved' || store.isOpen === false) {
    throw new HttpsError('failed-precondition', 'store unavailable');
  }

  // إعادة احتساب الأسعار من قائمة المتجر الحقيقية
  let subtotal = 0;
  const verified = [] as Order['items'];
  for (const it of items) {
    const menuSnap = await db().doc(`stores/${storeId}/menu/${it.itemId}`).get();
    if (!menuSnap.exists) throw new HttpsError('not-found', `item ${it.itemId}`);
    const m = menuSnap.data()!;
    if (m.available === false) throw new HttpsError('failed-precondition', `item ${m.name} unavailable`);
    const optsTotal = (it.options || []).reduce((s: number, o: any) => s + (o.price || 0), 0);
    const lineTotal = (m.price + optsTotal) * it.qty;
    subtotal += lineTotal;
    verified.push({ itemId: it.itemId, name: m.name, qty: it.qty, unitPrice: m.price, options: it.options || [], lineTotal });
  }

  if (subtotal < (store.minOrder || 0)) {
    throw new HttpsError('failed-precondition', 'below minimum order');
  }

  const configSnap = await db().doc('config/app').get();
  const serviceFee = configSnap.data()?.serviceFee ?? 0;
  const deliveryFee = type === 'pickup' ? 0 : (store.deliveryFee || 0);

  let discount = 0;
  if (couponCode) {
    const cSnap = await db().collection('coupons').where('code', '==', couponCode).limit(1).get();
    const c = cSnap.docs[0]?.data();
    if (c && c.active && subtotal >= (c.minOrder || 0) && (c.usedCount || 0) < (c.usageLimit || Infinity)) {
      discount = c.type === 'pct'
        ? Math.min(Math.round(subtotal * c.value / 100), c.maxDiscount || Infinity)
        : c.value;
      await cSnap.docs[0].ref.update({ usedCount: FieldValue.increment(1) });
    }
  }

  const total = Math.max(0, subtotal + deliveryFee + serviceFee + tip - discount);
  const now = Timestamp.now();
  const order: Partial<Order> = {
    code: shortCode(), customerUid: uid, storeId, items: verified,
    status: 'pending', type, address,
    pricing: { subtotal, deliveryFee, serviceFee, discount, tip, total },
    payment: { method: req.data.paymentMethod || 'cash', status: 'pending' },
    timeline: [{ status: 'pending', at: now, by: uid }],
    ...(scheduledFor ? { scheduledFor: Timestamp.fromMillis(Number(scheduledFor)) } : {}),
    createdAt: now, updatedAt: now,
  };
  const ref = await db().collection('orders').add(order);
  return { orderId: ref.id, code: order.code, total };
});

// تغيير حالة الطلب مع فرض state machine + صلاحيات الدور.
export const updateOrderStatus = onCall(async (req) => {
  const uid = req.auth?.uid;
  const role = req.auth?.token.role;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { orderId, status } = req.data as { orderId: string; status: OrderStatus };

  const ref = db().doc(`orders/${orderId}`);
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'order not found');
    const order = snap.data() as Order;

    const allowed = ORDER_TRANSITIONS[order.status] || [];
    if (!allowed.includes(status)) {
      throw new HttpsError('failed-precondition', `cannot go ${order.status} → ${status}`);
    }
    // صلاحيات: من يملك الحق في هذا التحوّل
    const partnerStatuses: OrderStatus[] = ['accepted', 'preparing', 'ready', 'rejected'];
    const driverStatuses: OrderStatus[] = ['picked_up', 'on_the_way', 'delivered'];
    const ok =
      role === 'admin' ||
      (role === 'partner' && partnerStatuses.includes(status)) ||
      (role === 'driver' && order.driverUid === uid && driverStatuses.includes(status)) ||
      (status === 'cancelled' && order.customerUid === uid && order.status === 'pending');
    if (!ok) throw new HttpsError('permission-denied', 'not allowed for this transition');

    tx.update(ref, {
      status,
      timeline: FieldValue.arrayUnion({ status, at: Timestamp.now(), by: uid }),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // عند التسليم: احتساب أرباح السائق والعمولة
    if (status === 'delivered' && order.driverUid) {
      const store = (await tx.get(db().doc(`stores/${order.storeId}`))).data();
      const commission = Math.round(order.pricing.subtotal * (store?.commissionPct ?? 0) / 100);
      const driverEarn = order.pricing.deliveryFee + order.pricing.tip;
      tx.update(db().doc(`drivers/${order.driverUid}`), {
        'earnings.today': FieldValue.increment(driverEarn),
        'earnings.week': FieldValue.increment(driverEarn),
        'earnings.total': FieldValue.increment(driverEarn),
        activeOrderId: FieldValue.delete(),
      });
      tx.set(db().collection('transactions').doc(), {
        orderId, uid: order.driverUid, type: 'payout', amount: driverEarn,
        createdAt: Timestamp.now(),
      });
      tx.set(db().collection('transactions').doc(), {
        orderId, uid: store?.ownerUid, type: 'commission', amount: -commission,
        createdAt: Timestamp.now(),
      });
    }
  });
  return { ok: true };
});

// تعيين سائق يدويًا (من اللوحة) — التعيين الذكي في drivers/assignment.ts
export const assignDriver = onCall(async (req) => {
  if (req.auth?.token.role !== 'admin') throw new HttpsError('permission-denied', 'admin only');
  const { orderId, driverUid } = req.data;
  await db().doc(`orders/${orderId}`).update({
    driverUid, status: 'assigned',
    timeline: FieldValue.arrayUnion({ status: 'assigned', at: Timestamp.now(), by: req.auth.uid }),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db().doc(`drivers/${driverUid}`).update({ activeOrderId: orderId });
  return { ok: true };
});

// تقييم الطلب بعد التسليم
export const rateOrder = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { orderId, stars, comment } = req.data;
  const snap = await db().doc(`orders/${orderId}`).get();
  const order = snap.data() as Order;
  if (!snap.exists || order.customerUid !== uid) throw new HttpsError('permission-denied', 'not your order');
  if (order.status !== 'delivered') throw new HttpsError('failed-precondition', 'order not delivered');

  await snap.ref.update({ rating: { stars, comment: comment || '' } });
  await db().collection('reviews').add({
    orderId, customerUid: uid, storeId: order.storeId, driverUid: order.driverUid || null,
    stars, comment: comment || '', createdAt: Timestamp.now(),
  });
  // تحديث متوسط تقييم المتجر
  const storeRef = db().doc(`stores/${order.storeId}`);
  await db().runTransaction(async (tx) => {
    const s = (await tx.get(storeRef)).data()!;
    const count = (s.ratingCount || 0) + 1;
    const avg = ((s.rating || 0) * (s.ratingCount || 0) + stars) / count;
    tx.update(storeRef, { rating: Math.round(avg * 10) / 10, ratingCount: count });
  });
  return { ok: true };
});
