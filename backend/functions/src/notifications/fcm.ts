// إشعارات FCM لحظية عند تغيّر حالة الطلب — تصل للزبون والتاجر والسائق.
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import type { OrderStatus } from '../types';

const db = () => getFirestore();

const STATUS_AR: Record<OrderStatus, string> = {
  pending: 'بانتظار التأكيد',
  accepted: 'تم قبول طلبك',
  preparing: 'يتم تحضير طلبك',
  ready: 'طلبك جاهز',
  assigned: 'تم تعيين سائق',
  picked_up: 'استلم السائق طلبك',
  on_the_way: 'طلبك في الطريق',
  delivered: 'تم توصيل طلبك',
  cancelled: 'تم إلغاء الطلب',
  rejected: 'تم رفض الطلب',
};

async function tokensFor(uid?: string): Promise<string[]> {
  if (!uid) return [];
  const u = await db().doc(`users/${uid}`).get();
  return (u.data()?.fcmTokens as string[]) || [];
}

export const onOrderStatusNotify = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;

  const status = after.status as OrderStatus;
  const title = 'ديار';
  const body = `${STATUS_AR[status]} • #${after.code}`;

  // المستلمون حسب الحالة
  const recipients = new Set<string>();
  recipients.add(after.customerUid);
  if (after.driverUid) recipients.add(after.driverUid);
  if (status === 'pending' || status === 'cancelled') {
    const store = await db().doc(`stores/${after.storeId}`).get();
    if (store.data()?.ownerUid) recipients.add(store.data()!.ownerUid);
  }

  const messages: { token: string; uid: string }[] = [];
  for (const uid of recipients) {
    for (const token of await tokensFor(uid)) messages.push({ token, uid });
  }

  await Promise.all(
    messages.map((m) =>
      getMessaging().send({
        token: m.token,
        notification: { title, body },
        data: { orderId: event.params.orderId, status, code: after.code },
      }).catch(() => null) // تجاهل الـ tokens الميتة
    )
  );

  // أرشفة الإشعار في Firestore لكل مستلم
  await Promise.all(
    [...recipients].map((uid) =>
      db().collection('notifications').add({
        uid, title, body, data: { orderId: event.params.orderId, status },
        read: false, createdAt: Timestamp.now(),
      })
    )
  );
});
