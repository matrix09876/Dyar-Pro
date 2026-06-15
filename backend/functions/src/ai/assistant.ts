// ميزات الذكاء الاصطناعي — تتبّع ذكي (ETA) ورد آلي على الدعم بلغة المستخدم.
// المفتاح ANTHROPIC_API_KEY كـ Secret (لا في الكود). يستخدم أحدث موديل Claude.
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import type { GeoPoint } from '../types';

const ANTHROPIC_API_KEY = defineSecret('ANTHROPIC_API_KEY');
const MODEL = 'claude-sonnet-4-6';
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

// تتبّع ذكي: تقدير وقت الوصول من موقع السائق الحي إلى وجهة الطلب.
// حساب فعلي فوري (لا يحتاج مفتاحًا) — أساس دقيق للـ ETA المعروض للمستخدم.
export const aiEta = onCall(async (req) => {
  const { orderId } = req.data as { orderId: string };
  const order = (await db().doc(`orders/${orderId}`).get()).data();
  if (!order?.driverUid) throw new HttpsError('failed-precondition', 'no driver');
  const loc = (await db().doc(`drivers/${order.driverUid}`).get()).data()
    ?.currentLocation as GeoPoint | undefined;
  const dest = order.address as GeoPoint | undefined;
  if (!loc || !dest) throw new HttpsError('failed-precondition', 'missing location');

  const km = distanceKm(loc, dest);
  const avgSpeedKmh = 28; // متوسط حضري واقعي
  const etaMins = Math.max(1, Math.round((km / avgSpeedKmh) * 60));
  await db().doc(`orders/${orderId}`).update({
    eta: Timestamp.fromMillis(Date.now() + etaMins * 60000),
  });
  return { etaMins, distanceKm: Math.round(km * 100) / 100 };
});

// رد آلي ذكي على رسائل الدعم بلغة المستخدم، مع تصعيد للبشر عند الحاجة.
export const aiSupportReply = onDocumentCreated(
  { document: 'support/{ticketId}/messages/{msgId}', secrets: [ANTHROPIC_API_KEY] },
  async (event) => {
    const msg = event.data?.data();
    if (!msg || msg.senderUid === 'ai' || msg.from === 'agent') return;

    let reply =
      'شكراً لتواصلك مع ديار. فريقنا سيتابع طلبك. لمتابعة حالة طلبك افتح «طلباتي».';
    try {
      const res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'x-api-key': ANTHROPIC_API_KEY.value(),
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          model: MODEL,
          max_tokens: 300,
          system:
            'أنت مساعد دعم ديار (سوبر آب توصيل). رد بإيجاز وبنفس لغة رسالة ' +
            'المستخدم (عربي/عبري/إنجليزي). لا تخترع معلومات طلب؛ إن لزم تدخّل ' +
            'بشري قل بوضوح أنك ستحوّل المحادثة لموظف.',
          messages: [{ role: 'user', content: String(msg.text ?? '') }],
        }),
      });
      const data = (await res.json()) as { content?: { text?: string }[] };
      reply = data?.content?.[0]?.text ?? reply;
    } catch {
      // عند غياب المفتاح أو خطأ الشبكة: نبقى على الرد الافتراضي
    }

    await event.data!.ref.parent.add({
      senderUid: 'ai',
      from: 'agent',
      text: reply,
      sentAt: Timestamp.now(),
      readBy: [],
    });
  }
);
