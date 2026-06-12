// هوكات وكيل الدعم الصوتي (ElevenLabs Tools → خادم ديار) — تمكّن
// «تاليا» من خدمة حقيقية لا كلامًا: حالة الطلب الفعلية، فتح تذكرة
// لفريق خدمة العملاء في اللوحة، وتسجيل طلب استرداد (بلا حركة مال —
// الموافقة بيد الموظف). الحماية: ترويسة x-dyar-hook بسرّ مشترك.
//   firebase functions:secrets:set SUPPORT_HOOK_SECRET
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { onRequest, type Request } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import type { Response } from 'express';
import { logAction } from '../ops/utils';

const SUPPORT_HOOK_SECRET = defineSecret('SUPPORT_HOOK_SECRET');
const db = () => getFirestore();

/** حالات الطلب بالعربية — لتنطقها تاليا طبيعيًا. */
const STATUS_AR: Record<string, string> = {
  pending: 'قيد المراجعة',
  accepted: 'مقبول وجاري تجهيزه',
  preparing: 'قيد التحضير',
  ready: 'جاهز وبانتظار المندوب',
  assigned: 'مع المندوب',
  picked_up: 'استلمه المندوب',
  on_the_way: 'في الطريق إليك',
  delivered: 'تم التوصيل',
  cancelled: 'ملغي',
  rejected: 'مرفوض',
};

function guard(req: Request, res: Response): boolean {
  const secret = SUPPORT_HOOK_SECRET.value();
  if (!secret || req.headers['x-dyar-hook'] !== secret) {
    res.status(401).json({ error: 'unauthorized' });
    return false;
  }
  return true;
}

/** يجد طلبًا برمزه مع تحقق خفيف بآخر 3 أرقام من هاتف الزبون. */
async function findOrder(code: string, phoneTail?: string) {
  const q = await db()
    .collection('orders')
    .where('code', '==', code.toUpperCase().replace(/^#/, ''))
    .limit(1)
    .get();
  if (q.empty) return null;
  const doc = q.docs[0];
  const order = doc.data();
  if (phoneTail && order.customerPhone) {
    if (!String(order.customerPhone).endsWith(phoneTail)) return null;
  }
  return { id: doc.id, ...order } as { id: string } & Record<string, unknown>;
}

/**
 * أداة الوكيل: حالة وتتبع الطلب — تعيد ما يلزم النطق فقط (بلا PII).
 * Body: { orderCode: string, phoneTail?: string }
 */
export const hookOrderStatus = onRequest(
  { secrets: [SUPPORT_HOOK_SECRET] },
  async (req, res) => {
    if (!guard(req, res)) return;
    const { orderCode, phoneTail } = (req.body ?? {}) as {
      orderCode?: string;
      phoneTail?: string;
    };
    if (!orderCode) {
      res.status(400).json({ error: 'orderCode required' });
      return;
    }
    const order = await findOrder(orderCode, phoneTail);
    if (!order) {
      res.json({
        found: false,
        say: 'ما لقيت طلب بهالرقم — ممكن تتأكد من رقم الطلب من شاشة طلباتي؟',
      });
      return;
    }
    const status = String(order.status ?? 'pending');
    const eta = order.etaMins as number | undefined;
    res.json({
      found: true,
      status,
      statusText: STATUS_AR[status] ?? status,
      etaMins: eta ?? null,
      hasDriver: Boolean(order.driverUid),
      totalShekel: Number((((order.pricing as { total?: number })?.total ?? 0) / 100).toFixed(2)),
      say:
        `طلبك ${STATUS_AR[status] ?? status}` +
        (eta && !['delivered', 'cancelled', 'rejected'].includes(status)
          ? `، والوصول المتوقع خلال ${eta} دقيقة تقريبًا.`
          : '.'),
    });
  },
);

/**
 * أداة الوكيل: فتح تذكرة لفريق خدمة العملاء — تظهر فورًا في اللوحة
 * (الدعم) مع الشارة الحمراء بالقائمة الجانبية.
 * Body: { topic: string, summary: string, phone?: string, orderCode?: string, uid?: string }
 */
export const hookCreateTicket = onRequest(
  { secrets: [SUPPORT_HOOK_SECRET] },
  async (req, res) => {
    if (!guard(req, res)) return;
    const { topic, summary, phone, orderCode, uid } = (req.body ?? {}) as Record<
      string,
      string | undefined
    >;
    if (!topic || !summary) {
      res.status(400).json({ error: 'topic and summary required' });
      return;
    }
    const ref = await db().collection('support').add({
      uid: uid ?? null,
      phone: phone ?? null,
      orderCode: orderCode ?? null,
      topic,
      lastMessage: summary,
      via: 'voice-agent',
      status: 'open',
      createdAt: Timestamp.now(),
    });
    await logAction({
      category: 'orders',
      action: `voice-agent ticket: ${topic}`,
      by: 'voice-agent',
      entity: ref.id,
    });
    res.json({
      ticketId: ref.id,
      say: 'فتحتلك تذكرة عند فريق خدمة العملاء، رح يتواصلوا معك بأقرب وقت. في إشي ثاني بقدر أساعدك فيه؟',
    });
  },
);

/**
 * أداة الوكيل: طلب استرداد — تذكرة موسومة refund لموافقة الموظف
 * (لا حركة أموال تلقائية — الأمان أولًا).
 * Body: { orderCode: string, reason: string, phone?: string, phoneTail?: string }
 */
export const hookRefundRequest = onRequest(
  { secrets: [SUPPORT_HOOK_SECRET] },
  async (req, res) => {
    if (!guard(req, res)) return;
    const { orderCode, reason, phone, phoneTail } = (req.body ?? {}) as Record<
      string,
      string | undefined
    >;
    if (!orderCode || !reason) {
      res.status(400).json({ error: 'orderCode and reason required' });
      return;
    }
    const order = await findOrder(orderCode, phoneTail);
    if (!order) {
      res.json({
        found: false,
        say: 'ما قدرت أأكد الطلب بهالبيانات — ممكن رقم الطلب الصحيح؟',
      });
      return;
    }
    const ref = await db().collection('support').add({
      uid: (order.customerUid as string) ?? null,
      phone: phone ?? null,
      orderCode,
      topic: 'refund',
      lastMessage: `طلب استرداد للطلب #${orderCode}: ${reason}`,
      via: 'voice-agent',
      status: 'open',
      createdAt: Timestamp.now(),
    });
    await logAction({
      category: 'orders',
      action: `voice-agent refund request for #${orderCode}`,
      by: 'voice-agent',
      entity: ref.id,
    });
    res.json({
      ticketId: ref.id,
      say: 'سجلتلك طلب الاسترداد وحوّلته لفريق خدمة العملاء — بيراجعوه وبيرجع المبلغ لمحفظتك بعد الموافقة. تمام؟',
    });
  },
);
