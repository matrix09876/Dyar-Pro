// بث الإشعارات الجماعية — sendBroadcast: للإدارة (أو staff بصلاحية
// 'broadcast'). يرسل عبر مواضيع FCM `role-{audience}` التي تشترك بها
// التطبيقات عند الإقلاع، أو إلى tokens مستخدم واحد (uid مفرد).
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logAction } from '../ops/utils';

const db = () => getFirestore();

type Audience = 'customers' | 'drivers' | 'partners' | 'uid';
const AUDIENCES: Audience[] = ['customers', 'drivers', 'partners', 'uid'];

export const sendBroadcast = onCall(async (req) => {
  const role = req.auth?.token.role;
  const perms = (req.auth?.token.perms as string[] | undefined) ?? [];
  const allowed =
    role === 'admin' || (role === 'staff' && perms.includes('broadcast'));
  if (!req.auth || !allowed) {
    throw new HttpsError('permission-denied', 'admin only');
  }

  const { title, body, audience, uid } = req.data as {
    title?: string; body?: string; audience?: Audience; uid?: string;
  };
  if (!title || !body) {
    throw new HttpsError('invalid-argument', 'title and body required');
  }
  if (!audience || !AUDIENCES.includes(audience)) {
    throw new HttpsError('invalid-argument', 'invalid audience');
  }

  let sentCount = 0;
  if (audience === 'uid') {
    if (!uid) throw new HttpsError('invalid-argument', 'uid required');
    const tokens =
      ((await db().doc(`users/${uid}`).get()).data()?.fcmTokens as string[]) ?? [];
    const results = await Promise.all(
      tokens.map((token) =>
        getMessaging()
          .send({ token, notification: { title, body } })
          .then(() => 1)
          .catch(() => 0) // تجاهل الـ tokens الميتة
      )
    );
    sentCount = results.reduce((s, n) => s + n, 0);
    // أرشفة داخل التطبيق أيضًا (جرس الإشعارات)
    await db().collection('notifications').add({
      uid, title, body, data: { broadcast: true },
      read: false, createdAt: Timestamp.now(),
    });
  } else {
    await getMessaging().send({
      topic: `role-${audience}`,
      notification: { title, body },
    });
    sentCount = 1; // موضوع واحد — FCM يوزّع على كل المشتركين
  }

  const ref = await db().collection('broadcasts').add({
    title, body, audience, uid: uid ?? null,
    sentBy: req.auth.uid, sentCount, createdAt: Timestamp.now(),
  });
  await logAction({
    category: 'business',
    action: `broadcast "${title}" → ${audience === 'uid' ? uid : audience}`,
    by: req.auth.uid,
    entity: ref.id,
  });
  return { ok: true, id: ref.id, sentCount };
});
