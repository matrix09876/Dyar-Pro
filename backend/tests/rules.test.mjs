// اختبارات قواعد أمان Firestore — تعمل على المحاكي:
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm test
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-dyar-rules',
  firestore: {
    rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

const as = (uid, role) =>
  env.authenticatedContext(uid, role ? { role } : {}).firestore();

let passed = 0;
const t = async (name, fn) => {
  try { await fn(); passed++; console.log('  ✓', name); }
  catch (e) { console.error('  ✗', name, '\n   ', e.message); process.exitCode = 1; }
};

// بيانات أساس (تجاوز القواعد)
await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users/alice'), { role: 'customer', walletBalance: 500, status: 'active' });
  await setDoc(doc(db, 'users/bob'), { role: 'customer' });
  // pending عمدًا: السيناريو الهجومي = التاجر يحاول اعتماد متجره بنفسه
  await setDoc(doc(db, 'stores/s1'), { ownerUid: 'p1', status: 'pending', commissionPct: 10 });
  await setDoc(doc(db, 'orders/o1'), {
    customerUid: 'alice', storeId: 's1', status: 'pending',
    payment: { method: 'cash', status: 'pending' },
    pricing: { total: 1000 }, items: [],
  });
});

console.log('🔐 Firestore rules tests');

await t('الزبون لا يقرأ ملف مستخدم آخر', () =>
  assertFails(getDoc(doc(as('alice', 'customer'), 'users/bob'))));

await t('الزبون لا يرفع رصيد محفظته بنفسه', () =>
  assertFails(updateDoc(doc(as('alice', 'customer'), 'users/alice'),
    { walletBalance: 999999 })));

await t('الزبون لا يرقّي دوره إلى admin', () =>
  assertFails(updateDoc(doc(as('alice', 'customer'), 'users/alice'),
    { role: 'admin' })));

await t('الزبون لا يمنح نفسه حساب تاجر B2B (merchant)', () =>
  assertFails(updateDoc(doc(as('alice', 'customer'), 'users/alice'),
    { merchant: true })));

await t('الزبون يحدّث اسمه بحرية', () =>
  assertSucceeds(updateDoc(doc(as('alice', 'customer'), 'users/alice'),
    { name: 'Alice' })));

await t('التاجر لا يعتمد متجره بنفسه (status)', () =>
  assertFails(updateDoc(doc(as('p1', 'partner'), 'stores/s1'),
    { status: 'approved', name: 'x' })));

await t('التاجر لا يغيّر عمولته', () =>
  assertFails(updateDoc(doc(as('p1', 'partner'), 'stores/s1'),
    { commissionPct: 0 })));

await t('الزبون لا يعدّل تسعير طلبه', () =>
  assertFails(updateDoc(doc(as('alice', 'customer'), 'orders/o1'),
    { 'pricing.total': 1 })));

await t('لا أحد يكتب transactions من العميل', () =>
  assertFails(setDoc(doc(as('admin1', 'admin'), 'transactions/t1'),
    { amount: 1 })));

await t('الأدمن يقرأ أي مستخدم', () =>
  assertSucceeds(getDoc(doc(as('admin1', 'admin'), 'users/bob'))));

await env.cleanup();
console.log(`\n${passed} passed${process.exitCode ? ' — مع إخفاقات!' : ' — كلها ناجحة ✅'}`);
