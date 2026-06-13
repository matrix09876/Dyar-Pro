// دورة حياة الطلب — كل تحوّلات الحالة الحسّاسة تمرّ من هنا مع تدقيق كامل.
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { ORDER_TRANSITIONS, type Order, type OrderStatus } from '../types';
import { resolveCommissionPct } from '../ops/commission';
import { distanceKm, logAction, queueMail } from '../ops/utils';

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

  // 🛡️ Rate-limit: حماية من إغراق الطلبات (≤3 خلال 60 ثانية)
  const minuteAgo = Timestamp.fromMillis(Date.now() - 60_000);
  const recent = await db().collection('orders')
    .where('customerUid', '==', uid)
    .where('createdAt', '>=', minuteAgo)
    .limit(3).get();
  if (recent.size >= 3) {
    throw new HttpsError('resource-exhausted', 'too many orders, slow down');
  }

  // 🚫 عناوين محظورة (مكافحة الاحتيال) — blockedAddresses من اللوحة:
  // أي عنوان يحتوي سطرًا محظورًا (بعد trim+lowercase) يُرفض فورًا.
  const addrLine = String(
    (address as { line?: string } | undefined)?.line ?? ''
  ).trim().toLowerCase();
  if (addrLine) {
    const blockedSnap = await db().collection('blockedAddresses').get();
    const blocked = blockedSnap.docs.some((d) => {
      const line = String(d.data().line ?? '').trim().toLowerCase();
      return line !== '' && addrLine.includes(line);
    });
    if (blocked) throw new HttpsError('failed-precondition', 'blocked-address');
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

  // رسوم التوصيل حسب منطقة المتجر (zones: مركز/نصف قطر/رسوم) —
  // أقرب منطقة مطابقة تفوز؛ وإلا رسوم المتجر الافتراضية.
  let deliveryFee = type === 'pickup' ? 0 : (store.deliveryFee || 0);
  const dest = address as { lat?: number; lng?: number } | undefined;
  if (type !== 'pickup' && dest?.lat && dest?.lng && store.location?.lat) {
    const zonesSnap = await db()
      .collection(`stores/${storeId}/zones`)
      .where('active', '==', true)
      .get();
    let bestRadius = Infinity;
    for (const z of zonesSnap.docs) {
      const zd = z.data();
      const center = zd.center ?? store.location;
      const dKm = distanceKm(
        { lat: center.lat, lng: center.lng },
        { lat: dest.lat, lng: dest.lng },
      );
      const radiusM = zd.radiusM ?? 0;
      if (dKm * 1000 <= radiusM && radiusM < bestRadius) {
        bestRadius = radiusM;
        deliveryFee = zd.deliveryFee ?? deliveryFee;
      }
    }
    // خارج كل المناطق المفعّلة؟ المتجر لا يوصّل إلى هذا العنوان
    if (zonesSnap.size > 0 && bestRadius === Infinity) {
      throw new HttpsError('failed-precondition', 'address outside delivery zones');
    }
  }

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
  // 🧠 ETA متعلَّم من تسليمات المتجر السابقة (يَصدُق قبل الدفع — درس Wolt)
  const etaMins = Math.round(
    store.etaStats?.avgMins ?? ((store.prepTimeMins || 20) + 12));
  const now = Timestamp.now();
  const order: Partial<Order> = {
    code: shortCode(), customerUid: uid, storeId, items: verified,
    status: 'pending', type, address,
    pricing: { subtotal, deliveryFee, serviceFee, discount, tip, total },
    payment: { method: req.data.paymentMethod || 'cash', status: 'pending' },
    timeline: [{ status: 'pending', at: now, by: uid }],
    etaMins,
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

    // قراءات العمولة قبل أي كتابة (قيود الـ transaction): المتجر +
    // config/app + مدينة المتجر لمحرك العمولات الذكية.
    let store: FirebaseFirestore.DocumentData | undefined;
    let cfg: FirebaseFirestore.DocumentData = {};
    let cityCountry: string | undefined;
    if (status === 'delivered' && order.driverUid) {
      store = (await tx.get(db().doc(`stores/${order.storeId}`))).data();
      cfg = (await tx.get(db().doc('config/app'))).data() ?? {};
      if (store?.cityId) {
        cityCountry = (await tx.get(db().doc(`cities/${store.cityId}`)))
          .data()?.country;
      }
    }

    tx.update(ref, {
      status,
      timeline: FieldValue.arrayUnion({ status, at: Timestamp.now(), by: uid }),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // عند التسليم: احتساب أرباح السائق والعمولة (محرك العمولات الذكية —
    // override المتجر ← خدمات ← قواعد commissionRules/الذروة ← الافتراضي)
    if (status === 'delivered' && order.driverUid) {
      const pct = resolveCommissionPct({
        store: {
          id: order.storeId,
          type: store?.type,
          cityId: store?.cityId,
          commissionPct: typeof store?.commissionPct === 'number'
            ? store.commissionPct : undefined,
        },
        city: store?.cityId
          ? { id: store.cityId, country: cityCountry } : null,
        at: new Date(),
        rules: cfg.commissionRules ?? [],
        tiers: cfg.commissionTiers,
        servicePct: cfg.serviceProvidersPct,
        defaultPct: cfg.defaultCommissionPct,
      });
      const commission = Math.round(order.pricing.subtotal * pct / 100);
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

  // 🧠 التعلم عند التسليم: زمن فعلي → إحصاء المتجر والسائق +
  // مكافأة سرعة (تحفيز) + موقع تسليم متعلَّم (خندق HAAT لكن أذكى)
  if (status === 'delivered') {
    const after = (await ref.get()).data() as Order & {
      etaMins?: number; address?: { lat?: number; lng?: number; line?: string };
      customerUid: string; driverUid?: string; storeId: string;
      createdAt: Timestamp;
    };
    const actualMins = Math.max(1, Math.round(
      (Date.now() - after.createdAt.toMillis()) / 60_000));

    // متوسط متحرك للمتجر (وزن 80/20)
    const stRef = db().doc(`stores/${after.storeId}`);
    const st = (await stRef.get()).data();
    const prevAvg = st?.etaStats?.avgMins ?? actualMins;
    const prevCnt = st?.etaStats?.count ?? 0;
    await stRef.set({
      etaStats: {
        avgMins: Math.round(prevAvg * 0.8 + actualMins * 0.2),
        count: prevCnt + 1,
      },
    }, { merge: true });

    // ⏱️ توقيت كل مرحلة من الخط الزمني + تعلّم AI-lite (EMA 80/20) حسب
    // المتجر/السائق/نوع الطلب — أساس التتبع الحي والتحسين المستمر.
    const tl = (after.timeline ?? []) as Array<{ status: string; at?: Timestamp }>;
    const atOf = (s: string) => tl.find((x) => x.status === s)?.at?.toMillis();
    const t0 = after.createdAt.toMillis();
    const span = (a?: number, b?: number) =>
      a != null && b != null && b >= a ? Math.round((b - a) / 60_000) : null;
    const tAcc = atOf('accepted');
    const tReady = atOf('ready');
    const tPick = atOf('picked_up') ?? atOf('on_the_way');
    const tDel = atOf('delivered') ?? Date.now();
    const stageMins = {
      accept: span(t0, tAcc),    // الطلب → قبول المتجر
      prep: span(tAcc, tReady),  // قبول → جاهز للاستلام
      pickup: span(tReady, tPick), // جاهز → استلام السائق
      deliver: span(tPick, tDel), // استلام → تسليم الزبون
      total: actualMins,
    };
    await ref.update({ stageMins });

    // EMA لكل مرحلة على وثيقة — يتجاهل المراحل المفقودة (null)
    const ema = (prev: number | undefined, v: number) =>
      Math.round((prev ?? v) * 0.8 + v * 0.2);
    const stageStatsUpdate = (prev: Record<string, number> | undefined) => {
      const out: Record<string, number> = { ...(prev ?? {}) };
      for (const k of ['accept', 'prep', 'pickup', 'deliver', 'total'] as const) {
        const v = stageMins[k];
        if (v != null) out[k] = ema(prev?.[k], v);
      }
      out.count = (prev?.count ?? 0) + 1;
      return out;
    };
    // تعلّم المتجر (مراحل التحضير) + نوع الطلب (تعلّم حسب النوع)
    await stRef.set({ stageStats: stageStatsUpdate(st?.stageStats) }, { merge: true });
    const typeRef = db().doc(`learning/byType_${after.type ?? 'order'}`);
    const typePrev = (await typeRef.get()).data()?.stageStats;
    await typeRef.set({
      type: after.type ?? 'order',
      stageStats: stageStatsUpdate(typePrev),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    // 🎁 نظام النقاط (config/loyalty): نقاط ولاء للزبون عند كل تسليم
    const loyalty = (await db().doc('config/loyalty').get()).data();
    if (loyalty?.enabled) {
      const pts = Math.round(
        (after.pricing.total / 100) * (loyalty.earnPerShekel ?? 0));
      if (pts > 0) {
        await db().doc(`users/${after.customerUid}`).set(
          { points: FieldValue.increment(pts) }, { merge: true });
      }
    }

    if (after.driverUid) {
      const drRef = db().doc(`drivers/${after.driverUid}`);
      const dr = (await drRef.get()).data();
      const dAvg = dr?.stats?.avgDeliveryMins ?? actualMins;
      const deliveredCount = (dr?.stats?.deliveredCount ?? 0) + 1;
      await drRef.set({
        stats: {
          avgDeliveryMins: Math.round(dAvg * 0.8 + actualMins * 0.2),
          deliveries: (dr?.stats?.deliveries ?? 0) + 1,
          deliveredCount,
          // متوسطات متحركة لمرحلتي السائق (الاستلام والتوصيل) — هوية أدائه
          ...(stageMins.pickup != null
            ? { avgPickupMins: ema(dr?.stats?.avgPickupMins, stageMins.pickup) }
            : {}),
          ...(stageMins.deliver != null
            ? { avgDeliverMins: ema(dr?.stats?.avgDeliverMins, stageMins.deliver) }
            : {}),
        },
      }, { merge: true });

      // 🏆 جوائز المندوبين (driverPrizes): بلوغ هدف جائزة نشطة → مكافأة
      const prizesSnap = await db().collection('driverPrizes')
        .where('active', '==', true).get();
      for (const p of prizesSnap.docs) {
        const prize = p.data();
        const bonus = Number(prize.bonus) || 0;
        if (Number(prize.targetDeliveries) === deliveredCount && bonus > 0) {
          await db().collection('transactions').add({
            uid: after.driverUid, type: 'prize_bonus', amount: bonus,
            meta: { prizeId: p.id, title: prize.title ?? '', deliveredCount },
            createdAt: Timestamp.now(),
          });
          await drRef.update({
            'earnings.total': FieldValue.increment(bonus),
          });
          await logAction({
            category: 'business',
            action: `prize "${prize.title}" (${prize.targetDeliveries} deliveries) → driver ${after.driverUid}`,
            by: 'system',
            entity: p.id,
          });
        }
      }

      // 🏆 مكافأة سرعة: التسليم ضمن الـ ETA الموعود → ₪2 تحفيز
      if (after.etaMins && actualMins <= after.etaMins) {
        await db().collection('transactions').add({
          uid: after.driverUid, type: 'payout', amount: 200,
          meta: { speedBonus: true, orderId, actualMins },
          createdAt: Timestamp.now(),
        });
        await db().doc(`drivers/${after.driverUid}`).update({
          'earnings.today': FieldValue.increment(200),
          'earnings.week': FieldValue.increment(200),
          'earnings.total': FieldValue.increment(200),
        });
      }
    }

    // 📍 الموقع المتعلَّم: تأكيد إحداثيات الزبون بعد كل تسليم ناجح
    const a = after.address;
    if (a?.lat && a?.lng) {
      await db().doc(`learnedLocations/${after.customerUid}`).set({
        lat: a.lat, lng: a.lng, line: a.line ?? '',
        confirmations: FieldValue.increment(1),
        updatedAt: Timestamp.now(),
      }, { merge: true });
    }
  }

  // تدقيق + إيصال رقمي بعد نجاح الحركة (خارج الـ transaction)
  await logAction({
    category: 'orders',
    action: `order ${orderId} → ${status}`,
    by: uid,
    entity: orderId,
  });
  if (status === 'delivered') {
    const after = (await ref.get()).data() as Order & { customerUid: string };
    const customer = await db().doc(`users/${after.customerUid}`).get();
    const email = customer.data()?.email as string | undefined;
    if (email) {
      await queueMail(email, 'orderReceipt', {
        userName: customer.data()?.name ?? '',
        orderCode: after.code,
        total: (after.pricing.total / 100).toFixed(2),
      });
    }
  }
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
