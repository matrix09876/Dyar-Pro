// إدارة أدوار المستخدمين عبر Custom Claims. الدور هو مصدر الصلاحيات في
// firestore.rules. لا يُسمح للعميل بتعيين دوره بنفسه.
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { beforeUserCreated } from 'firebase-functions/v2/identity';
import type { Role } from '../types';

const VALID_ROLES: Role[] = ['customer', 'driver', 'partner', 'admin'];

// الإدارة فقط تستطيع ترقية/تغيير دور مستخدم آخر.
export const setUserRole = onCall(async (req) => {
  if (req.auth?.token.role !== 'admin') {
    throw new HttpsError('permission-denied', 'admin only');
  }
  const { uid, role } = req.data as { uid: string; role: Role };
  if (!uid || !VALID_ROLES.includes(role)) {
    throw new HttpsError('invalid-argument', 'uid and valid role required');
  }
  await getAuth().setCustomUserClaims(uid, { role });
  await getFirestore().doc(`users/${uid}`).set(
    { role, updatedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );
  return { ok: true, uid, role };
});

// كل مستخدم جديد يبدأ كـ customer افتراضيًا.
export const onUserCreate = beforeUserCreated(async () => {
  return { customClaims: { role: 'customer' as Role } };
});
