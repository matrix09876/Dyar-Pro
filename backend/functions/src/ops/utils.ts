// أدوات تشغيلية مشتركة: مسافة جغرافية، سجل تدقيق، طابور بريد بقوالب.
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

const db = () => getFirestore();

export function distanceKm(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
): number {
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const la1 = (a.lat * Math.PI) / 180;
  const la2 = (b.lat * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(la1) * Math.cos(la2) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

/** سجل التدقيق — بصيغة اللوحة الحالية: entity/action/by/at[/until]. */
export async function logAction(opts: {
  category: 'business' | 'menu' | 'users' | 'zones' | 'timings' | 'discounts' | 'orders';
  action: string;
  by: string;
  entity?: string;
  until?: Timestamp;
}): Promise<void> {
  await db().collection('logs').add({
    category: opts.category,
    action: opts.action,
    entity: opts.entity ?? null,
    by: opts.by,
    until: opts.until ?? null,
    createdAt: Timestamp.now(),
  });
}

/**
 * طابور بريد متوافق مع Firebase Trigger Email extension (مجموعة `mail`).
 * القوالب من config/emails مع استبدال {var}.
 */
export async function queueMail(
  to: string,
  templateKey: 'newUserRegistration' | 'driverOnboarding' | 'orderReceipt',
  vars: Record<string, string>,
): Promise<void> {
  const cfg = await db().doc('config/emails').get();
  const tpl = cfg.data()?.templates?.[templateKey] as
    | { subject?: string; html?: string }
    | undefined;
  if (!tpl?.html) return; // لا قالب مضبوطًا بعد — تجاهل بهدوء

  const render = (s: string) =>
    s.replace(/\{(\w+)\}/g, (_, k) => vars[k] ?? '');

  await db().collection('mail').add({
    to,
    message: {
      subject: render(tpl.subject ?? 'Dyar'),
      html: render(tpl.html),
    },
    createdAt: Timestamp.now(),
  });
}
