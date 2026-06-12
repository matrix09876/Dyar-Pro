// إدارة أدوار المستخدمين عبر Custom Claims. الدور هو مصدر الصلاحيات في
// firestore.rules. لا يُسمح للعميل بتعيين دوره بنفسه.
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { beforeUserCreated } from 'firebase-functions/v2/identity';
import { SUPPORT_HOOK_SECRET } from '../ai/supportHooks';
import type { Role } from '../types';

const VALID_ROLES: Role[] = ['customer', 'driver', 'partner', 'staff', 'admin'];

// الإدارة فقط تستطيع ترقية/تغيير دور مستخدم آخر + ضبط صلاحيات عامل المكتب.
export const setUserRole = onCall(async (req) => {
  if (req.auth?.token.role !== 'admin') {
    throw new HttpsError('permission-denied', 'admin only');
  }
  const { uid, role, permissions } = req.data as {
    uid: string; role: Role; permissions?: string[];
  };
  if (!uid || !VALID_ROLES.includes(role)) {
    throw new HttpsError('invalid-argument', 'uid and valid role required');
  }
  // صلاحيات staff الدقيقة تُحقن في الـ claims ليفرضها الخادم
  const perms = role === 'staff' ? permissions ?? [] : [];
  await getAuth().setCustomUserClaims(uid, { role, perms });
  await getFirestore().doc(`users/${uid}`).set(
    { role, permissions: perms, updatedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );
  return { ok: true, uid, role, permissions: perms };
});

// كل مستخدم جديد يبدأ كـ customer افتراضيًا.
export const onUserCreate = beforeUserCreated(async () => {
  return { customClaims: { role: 'customer' as Role } };
});

/**
 * تمهيد أول مدير (مرة واحدة) — يحل مشكلة البيضة والدجاجة:
 * setUserRole يتطلب مديرًا، ولا مدير بعد. محمي بسرّ SUPPORT_HOOK_SECRET
 * ويُقفل ذاتيًا بعد أول نجاح (config/bootstrap.adminClaimed).
 * الاستخدام: curl -X POST .../claimFirstAdmin \
 *   -H "x-dyar-hook: $SECRET" -H "Content-Type: application/json" \
 *   -d '{"uid":"<UID>"}'
 */
export const claimFirstAdmin = onRequest(
  { secrets: [SUPPORT_HOOK_SECRET] },
  async (req, res) => {
    if (req.headers['x-dyar-hook'] !== SUPPORT_HOOK_SECRET.value()) {
      res.status(401).json({ error: 'unauthorized' });
      return;
    }
    const uid = (req.body ?? {}).uid as string | undefined;
    if (!uid) {
      res.status(400).json({ error: 'uid required' });
      return;
    }
    const db = getFirestore();
    const flag = db.doc('config/bootstrap');
    try {
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(flag);
        if (snap.data()?.adminClaimed === true) {
          throw new Error('already-claimed');
        }
        tx.set(flag, { adminClaimed: true, by: uid, at: FieldValue.serverTimestamp() }, { merge: true });
      });
    } catch {
      res.status(409).json({ error: 'admin already claimed — use setUserRole from the dashboard' });
      return;
    }
    await getAuth().setCustomUserClaims(uid, { role: 'admin' });
    await db.doc(`users/${uid}`).set({ role: 'admin' }, { merge: true });
    res.json({ ok: true, uid, role: 'admin', note: 'sign out & in to refresh the token' });
  },
);
