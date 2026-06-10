// مدفوعات Stripe. المفاتيح من إعدادات البيئة (لا تُرفع للكود):
//   firebase functions:config:set stripe.secret="sk_..." stripe.webhook="whsec_..."
// أو متغيرات بيئة STRIPE_SECRET / STRIPE_WEBHOOK.
import Stripe from 'stripe';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

const STRIPE_SECRET = defineSecret('STRIPE_SECRET');
const STRIPE_WEBHOOK = defineSecret('STRIPE_WEBHOOK');
const db = () => getFirestore();

function client(): Stripe {
  return new Stripe(STRIPE_SECRET.value(), { apiVersion: '2024-06-20' });
}

// ينشئ PaymentIntent بمبلغ الطلب الموثّق من الخادم.
export const createPaymentIntent = onCall({ secrets: [STRIPE_SECRET] }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login required');
  const { orderId } = req.data as { orderId: string };

  const snap = await db().doc(`orders/${orderId}`).get();
  if (!snap.exists) throw new HttpsError('not-found', 'order not found');
  const order = snap.data()!;
  if (order.customerUid !== uid) throw new HttpsError('permission-denied', 'not your order');
  if (order.payment.status === 'paid') throw new HttpsError('failed-precondition', 'already paid');

  const intent = await client().paymentIntents.create({
    amount: order.pricing.total, // أصغر وحدة عملة
    currency: (await db().doc('config/app').get()).data()?.currency || 'ils',
    metadata: { orderId, uid },
    automatic_payment_methods: { enabled: true },
  });
  await snap.ref.update({ 'payment.intentId': intent.id });
  return { clientSecret: intent.client_secret };
});

// Webhook لتأكيد الدفع — يحدّث حالة الطلب فقط بعد تأكيد Stripe.
export const stripeWebhook = onRequest(
  { secrets: [STRIPE_SECRET, STRIPE_WEBHOOK] },
  async (req, res) => {
    const sig = req.headers['stripe-signature'] as string;
    let event: Stripe.Event;
    try {
      event = client().webhooks.constructEvent(req.rawBody, sig, STRIPE_WEBHOOK.value());
    } catch (err) {
      res.status(400).send(`Webhook Error: ${(err as Error).message}`);
      return;
    }

    if (event.type === 'payment_intent.succeeded') {
      const pi = event.data.object as Stripe.PaymentIntent;
      const orderId = pi.metadata.orderId;
      if (orderId) {
        await db().doc(`orders/${orderId}`).update({
          'payment.status': 'paid',
          'payment.paidAt': Timestamp.now(),
        });
        await db().collection('transactions').add({
          orderId, uid: pi.metadata.uid, type: 'order', amount: pi.amount,
          createdAt: Timestamp.now(),
        });
      }
    } else if (event.type === 'payment_intent.payment_failed') {
      const pi = event.data.object as Stripe.PaymentIntent;
      if (pi.metadata.orderId) {
        await db().doc(`orders/${pi.metadata.orderId}`).update({ 'payment.status': 'failed' });
      }
    }
    res.json({ received: true });
  }
);

// (محجوز) شحن المحفظة
export async function creditWallet(uid: string, amount: number, orderId?: string) {
  await db().doc(`users/${uid}`).update({ walletBalance: FieldValue.increment(amount) });
  await db().collection('transactions').add({
    uid, orderId: orderId || null, type: 'topup', amount, createdAt: Timestamp.now(),
  });
}
