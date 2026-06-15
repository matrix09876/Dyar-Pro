// بوابة EasycardNG (VISA + Bit) — تدفق رسمي موثّق ومجرَّب حيًا ضد
// بيئة الاختبار (12/06/2026): توكن identity ✓ ثم PaymentIntent ✓.
// الأسرار تُحقن عند الإطلاق فقط:
//   firebase functions:secrets:set EASYCARD_TERMINAL_ID
//   firebase functions:secrets:set EASYCARD_API_KEY
//   firebase functions:secrets:set EASYCARD_WEBHOOK_SECRET   (اختياري لكنه موصى)
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { logAction } from '../ops/utils';

const EASYCARD_TERMINAL_ID = defineSecret('EASYCARD_TERMINAL_ID');
const EASYCARD_API_KEY = defineSecret('EASYCARD_API_KEY');
const EASYCARD_WEBHOOK_SECRET = defineSecret('EASYCARD_WEBHOOK_SECRET');

const EC_IDENTITY = 'https://identity.e-c.co.il';
const EC_API = 'https://api.e-c.co.il';

const db = () => getFirestore();

// توكن Bearer صالح 24 ساعة — يُخزَّن على مستوى الـinstance ويُجدَّد
// قبل انتهائه بدقيقة (Authorization.md: grant_type=terminal_rest_api).
let cachedToken: { value: string; expiresAt: number } | null = null;

async function ecToken(): Promise<string> {
  if (cachedToken && Date.now() < cachedToken.expiresAt) return cachedToken.value;
  const res = await fetch(`${EC_IDENTITY}/connect/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: 'terminal',
      grant_type: 'terminal_rest_api',
      authorizationKey: EASYCARD_API_KEY.value(),
    }),
  });
  if (!res.ok) throw new HttpsError('internal', `gateway auth ${res.status}`);
  const data = (await res.json()) as { access_token: string; expires_in: number };
  cachedToken = {
    value: data.access_token,
    expiresAt: Date.now() + (data.expires_in - 60) * 1000,
  };
  return cachedToken.value;
}

/**
 * إنشاء عملية دفع (بطاقة أو Bit) لطلب موجود — المبلغ من الخادم حصراً.
 * يعيد paymentUrl (صفحة Checkout المستضافة) لفتحه داخل التطبيق،
 * والتأكيد النهائي يصل عبر الـwebhook أدناه.
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
    if (!terminalId || !EASYCARD_API_KEY.value()) {
      throw new HttpsError(
        'failed-precondition',
        'payment gateway not configured yet',
      );
    }

    // PaymentIntent&PaymentRequest.md — POST /api/paymentIntent:
    // المبلغ عشري بالشيكل (مخزّن لدينا بالأغورة)، والمرجع الخارجي
    // dealReference = orderId ليعود إلينا في الـwebhook.
    const token = await ecToken();
    const res = await fetch(`${EC_API}/api/paymentIntent`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        paymentIntent: true,
        terminalID: terminalId,
        currency: 'ILS',
        paymentRequestAmount: Number((order.pricing.total / 100).toFixed(2)),
        // صلاحية الرابط 30 دقيقة — تكفي لإتمام الدفع داخل التطبيق
        dueDate: new Date(Date.now() + 30 * 60_000).toISOString(),
        ...(method === 'bit' ? { pinPadPreferredMethod: 'Bit' } : {}),
        dealDetails: {
          dealReference: orderId,
          dealDescription: `Dyar order ${order.code}`,
          items: (order.items ?? []).map(
            (it: { name: string; qty: number; lineTotal: number }) => ({
              itemName: it.name,
              quantity: it.qty,
              amount: Number((it.lineTotal / 100).toFixed(2)),
            }),
          ),
        },
      }),
    });
    if (!res.ok) {
      throw new HttpsError('internal', `gateway error ${res.status}`);
    }
    const data = (await res.json()) as {
      entityUID?: string;
      entityReference?: string;
      additionalData?: { url?: string };
    };

    await snap.ref.update({
      'payment.intentId': data.entityUID ?? data.entityReference ?? null,
      'payment.gateway': 'easycardng',
      'payment.method': method,
    });
    return { paymentUrl: data.additionalData?.url ?? null };
  },
);

/**
 * Webhook من EasycardNG (Webhooks.md) — يُسجَّل في لوحة EasyCard مع
 * ترويسة أمان مخصصة X-Dyar-Secret. لا نثق بالحمولة: عند TransactionCreated
 * نستعلم المعاملة من الـAPI (GET /api/transactions/{entityReference})
 * ونعتمد حالتها وقيمتها من المصدر.
 */
export const easycardWebhook = onRequest(
  { secrets: [EASYCARD_TERMINAL_ID, EASYCARD_API_KEY, EASYCARD_WEBHOOK_SECRET] },
  async (req, res) => {
    // ترويسة الأمان المشتركة (تُضبط في لوحة EasyCard مع تسجيل الرابط)
    const secret = EASYCARD_WEBHOOK_SECRET.value();
    if (secret && req.headers['x-dyar-secret'] !== secret) {
      res.status(401).send('unauthorized');
      return;
    }

    const body = (req.body ?? {}) as {
      eventName?: string;
      entityType?: string;
      entityReference?: string;
      entityExternalReference?: string;
      isFailureEvent?: boolean;
      terminalID?: string;
    };

    if (!body.entityReference || body.entityType !== 'PaymentTransaction') {
      // أحداث أخرى (فواتير/بطاقات...) — نستلمها بصمت
      res.json({ received: true });
      return;
    }
    if (body.terminalID && body.terminalID !== EASYCARD_TERMINAL_ID.value()) {
      res.status(401).send('terminal mismatch');
      return;
    }

    // التحقق الموثوق: حالة المعاملة من الـAPI لا من الحمولة
    const token = await ecToken();
    const txRes = await fetch(
      `${EC_API}/api/transactions/${body.entityReference}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (!txRes.ok) {
      res.status(502).send('verify failed');
      return;
    }
    const tx = (await txRes.json()) as {
      status?: string;
      dealDetails?: { dealReference?: string };
    };
    const orderId =
      tx.dealDetails?.dealReference ?? body.entityExternalReference;
    if (!orderId) {
      res.status(400).send('missing order reference');
      return;
    }

    const ref = db().doc(`orders/${orderId}`);
    const failed =
      body.isFailureEvent === true ||
      body.eventName === 'TransactionRejected' ||
      /reject|fail|cancel/i.test(tx.status ?? '');

    if (!failed) {
      await ref.update({
        'payment.status': 'paid',
        'payment.txId': body.entityReference,
        'payment.paidAt': Timestamp.now(),
      });
      const order = (await ref.get()).data();
      await db().collection('transactions').add({
        orderId,
        uid: order?.customerUid,
        type: 'order',
        amount: order?.pricing?.total ?? 0,
        gateway: 'easycardng',
        createdAt: Timestamp.now(),
      });
      await logAction({
        category: 'orders',
        action: `payment confirmed (easycard) for ${orderId}`,
        by: 'gateway',
        entity: orderId,
      });
    } else {
      await ref.update({ 'payment.status': 'failed' });
    }
    res.json({ received: true });
  },
);
