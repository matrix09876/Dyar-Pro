// بوابة EasycardNG (البطاقات VISA + Bit) — كل التوصيلات جاهزة؛
// يلزم فقط حقن السرّين عند الإطلاق:
//   firebase functions:secrets:set EASYCARD_TERMINAL_ID
//   firebase functions:secrets:set EASYCARD_API_KEY
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { logAction } from '../ops/utils';

const EASYCARD_TERMINAL_ID = defineSecret('EASYCARD_TERMINAL_ID');
const EASYCARD_API_KEY = defineSecret('EASYCARD_API_KEY');
const EASYCARD_API = 'https://api.e-c.co.il'; // بيئة الإنتاج

const db = () => getFirestore();

/**
 * إنشاء عملية دفع (بطاقة أو Bit) لطلب موجود — المبلغ من الخادم حصراً.
 * يعيد paymentUrl لفتحه داخل التطبيق (WebView/Browser) وتُؤكَّد النتيجة
 * عبر الـ webhook أدناه.
 */
export const createEasycardPayment = onCall(
  { secrets: [EASYCARD_TERMINAL_ID, EASYCARD_API_KEY] },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'login required');
    const { orderId, method } = req.data as {
      orderId: string;
      method: 'card' | 'bit';
    };

    const snap = await db().doc(`orders/${orderId}`).get();
    if (!snap.exists) throw new HttpsError('not-found', 'order not found');
    const order = snap.data()!;
    if (order.customerUid !== uid) {
      throw new HttpsError('permission-denied', 'not your order');
    }
    if (order.payment?.status === 'paid') {
      throw new HttpsError('failed-precondition', 'already paid');
    }

    const terminalId = EASYCARD_TERMINAL_ID.value();
    const apiKey = EASYCARD_API_KEY.value();
    if (!terminalId || !apiKey) {
      throw new HttpsError(
        'failed-precondition',
        'payment gateway not configured yet',
      );
    }

    // EasycardNG: إنشاء PaymentIntent/redirect — راجع توثيق NG لديك.
    const res = await fetch(`${EASYCARD_API}/api/paymentIntent`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        terminalID: terminalId,
        // المبلغ بالشيكل (NG يستقبل عشريًا) — مخزّن لدينا بالأغورة
        paymentRequestAmount: order.pricing.total / 100,
        currency: 'ILS',
        // Bit يُمرَّر كوسيلة مفضّلة عند طلبه
        ...(method === 'bit' ? { pinPadPreferredMethod: 'Bit' } : {}),
        dealDescription: `Dyar order ${order.code}`,
        externalId: orderId,
      }),
    });
    if (!res.ok) {
      throw new HttpsError('internal', `gateway error ${res.status}`);
    }
    const data = (await res.json()) as {
      entityUID?: string;
      additionalData?: { url?: string };
      url?: string;
    };

    await snap.ref.update({
      'payment.intentId': data.entityUID ?? null,
      'payment.gateway': 'easycardng',
      'payment.method': method,
    });
    return { paymentUrl: data.url ?? data.additionalData?.url ?? null };
  },
);

/** Webhook تأكيد الدفع من EasycardNG — يُسجَّل رابطه في لوحة EasyCard. */
export const easycardWebhook = onRequest(
  { secrets: [EASYCARD_API_KEY] },
  async (req, res) => {
    // تحقّق بسيط بالمفتاح المشترك في الترويسة (حسب إعداد NG لديك)
    const auth = req.headers.authorization ?? '';
    if (!auth.includes(EASYCARD_API_KEY.value().slice(0, 12))) {
      res.status(401).send('unauthorized');
      return;
    }
    const { externalId, status } = req.body ?? {};
    if (!externalId) {
      res.status(400).send('missing externalId');
      return;
    }
    const ref = db().doc(`orders/${externalId}`);
    if (status === 'success' || status === 'approved') {
      await ref.update({
        'payment.status': 'paid',
        'payment.paidAt': Timestamp.now(),
      });
      const order = (await ref.get()).data();
      await db().collection('transactions').add({
        orderId: externalId,
        uid: order?.customerUid,
        type: 'order',
        amount: order?.pricing?.total ?? 0,
        gateway: 'easycardng',
        createdAt: Timestamp.now(),
      });
      await logAction({
        category: 'orders',
        action: `payment confirmed (easycard) for ${externalId}`,
        by: 'gateway',
        entity: externalId,
      });
    } else {
      await ref.update({ 'payment.status': 'failed' });
    }
    res.json({ received: true });
  },
);
