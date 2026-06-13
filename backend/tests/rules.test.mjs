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

const as = (uid, role, perms) =>
  env.authenticatedContext(uid, role ? { role, ...(perms ? { perms } : {}) } : {}).firestore();

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
  await setDoc(doc(db, 'support/t1'), { uid: 'bob', status: 'open', topic: 'general' });
  await setDoc(doc(db, 'organizations/org1'), { name: 'Acme', active: true, budget: { amount: 2500, period: 'daily' }, members: ['alice'] });
  await setDoc(doc(db, 'mealAccounts/alice'), { orgId: 'org1', balance: 2500 });
  await setDoc(doc(db, 'stories/st1'), { title: 'x', active: true });
  await setDoc(doc(db, 'posCodes/123456'), { uid: 'alice', orgId: 'org1', status: 'active' });
  await setDoc(doc(db, 'rfqs/rfq1'), { merchantUid: 'alice', storeId: 's1', productName: 'دقيق', qty: 100, status: 'open' });
  await setDoc(doc(db, 'orders/o1'), {
    customerUid: 'alice', storeId: 's1', status: 'pending',
    payment: { method: 'cash', status: 'pending' },
    pricing: { total: 1000 }, items: [],
  });
  await setDoc(doc(db, 'blockedAddresses/b1'),
    { line: 'fake street 1', reason: 'fraud' });
  await setDoc(doc(db, 'broadcasts/bc1'),
    { title: 'hello', body: 'world', audience: 'customers' });
  await setDoc(doc(db, 'driverPrizes/pr1'),
    { title: '100 توصيلة', targetDeliveries: 100, bonus: 5000, active: true });
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

await t('التاجر يصرّح بوسوم الحِمية (حلال/نباتي)', () =>
  assertSucceeds(updateDoc(doc(as('p1', 'partner'), 'stores/s1'),
    { dietary: ['halal', 'vegetarian'] })));

await t('التاجر لا يوثّق الحلال/الكوشير بنفسه (dietaryVerified)', () =>
  assertFails(updateDoc(doc(as('p1', 'partner'), 'stores/s1'),
    { dietaryVerified: true })));

await t('الإدارة توثّق الحلال/الكوشير', () =>
  assertSucceeds(updateDoc(doc(as('admin1', 'admin'), 'stores/s1'),
    { dietaryVerified: true })));

await t('الزبون لا يعدّل تسعير طلبه', () =>
  assertFails(updateDoc(doc(as('alice', 'customer'), 'orders/o1'),
    { 'pricing.total': 1 })));

await t('لا أحد يكتب transactions من العميل', () =>
  assertFails(setDoc(doc(as('admin1', 'admin'), 'transactions/t1'),
    { amount: 1 })));

await t('الأدمن يقرأ أي مستخدم', () =>
  assertSucceeds(getDoc(doc(as('admin1', 'admin'), 'users/bob'))));

// ---- ديار Meals + الستوري ----
await t('الموظف يقرأ حساب وجباته فقط', () =>
  assertSucceeds(getDoc(doc(as('alice', 'customer'), 'mealAccounts/alice'))));
await t('زبون آخر لا يقرأ حساب وجبات غيره', () =>
  assertFails(getDoc(doc(as('bob', 'customer'), 'mealAccounts/alice'))));
await t('لا أحد يكتب رصيد الوجبات من العميل (Functions فقط)', () =>
  assertFails(updateDoc(doc(as('alice', 'customer'), 'mealAccounts/alice'), { balance: 999999 })));
await t('الزبون لا ينشئ شركة', () =>
  assertFails(setDoc(doc(as('alice', 'customer'), 'organizations/x'), { name: 'h' })));
await t('الأدمن يدير الشركات', () =>
  assertSucceeds(setDoc(doc(as('admin1', 'admin'), 'organizations/x'), { name: 'h', active: true })));
await t('الستوري قراءة عامة', () =>
  assertSucceeds(getDoc(doc(as('alice', 'customer'), 'stories/st1'))));
await t('الزبون لا يكتب ستوري', () =>
  assertFails(setDoc(doc(as('alice', 'customer'), 'stories/x'), { title: 'h' })));

// ---- ديار Meals: رموز POS (Functions فقط — generate/redeem) ----
await t('الزبون لا يقرأ رمز POS (Functions فقط)', () =>
  assertFails(getDoc(doc(as('alice', 'customer'), 'posCodes/123456'))));
await t('التاجر لا يقرأ رمز POS مباشرة (يصرفه عبر الدالة)', () =>
  assertFails(getDoc(doc(as('p1', 'partner'), 'posCodes/123456'))));
await t('لا أحد يكتب/يزوّر رمز POS من العميل', () =>
  assertFails(setDoc(doc(as('alice', 'customer'), 'posCodes/999999'),
    { uid: 'alice', status: 'active' })));
await t('التاجر لا يصرف رمز POS بالكتابة المباشرة', () =>
  assertFails(updateDoc(doc(as('p1', 'partner'), 'posCodes/123456'),
    { status: 'used' })));

// ---- ديار B2B: طلبات عرض السعر (RFQ) ----
await t('التاجر صاحب الطلب يقرأ RFQ', () =>
  assertSucceeds(getDoc(doc(as('alice', 'customer'), 'rfqs/rfq1'))));
await t('المورد (صاحب متجر الجملة) يقرأ RFQ المستهدف', () =>
  assertSucceeds(getDoc(doc(as('p1', 'partner'), 'rfqs/rfq1'))));
await t('طرف ثالث لا يقرأ RFQ غيره', () =>
  assertFails(getDoc(doc(as('bob', 'customer'), 'rfqs/rfq1'))));
await t('لا أحد يكتب RFQ من العميل (Functions فقط)', () =>
  assertFails(setDoc(doc(as('alice', 'customer'), 'rfqs/x'),
    { merchantUid: 'alice', storeId: 's1', status: 'open' })));
await t('المورد لا يكتب عرضًا بالكتابة المباشرة (Functions فقط)', () =>
  assertFails(updateDoc(doc(as('p1', 'partner'), 'rfqs/rfq1'),
    { status: 'quoted' })));

// ---- دور خدمة العملاء (staff + perms) ----
await t('موظف خدمة العملاء يقرأ تذاكر الدعم', () =>
  assertSucceeds(getDoc(doc(as('cs1', 'staff', ['support.manage']), 'support/t1'))));

await t('موظف بلا صلاحية لا يقرأ تذاكر غيره', () =>
  assertFails(getDoc(doc(as('cs2', 'staff', ['jobs']), 'support/t1'))));

await t('خدمة العملاء تغيّر حالة الطلب (orders.manage)', () =>
  assertSucceeds(updateDoc(doc(as('cs1', 'staff', ['orders.manage']), 'orders/o1'),
    { status: 'accepted' })));

await t('خدمة العملاء لا تعدّل تسعير الطلب', () =>
  assertFails(updateDoc(doc(as('cs1', 'staff', ['orders.manage']), 'orders/o1'),
    { pricing: { total: 1 } })));

await t('الزبون لا يقرأ العناوين المحظورة', () =>
  assertFails(getDoc(doc(as('alice', 'customer'), 'blockedAddresses/b1'))));

await t('الأدمن يقرأ ويدير العناوين المحظورة', () =>
  assertSucceeds(getDoc(doc(as('admin1', 'admin'), 'blockedAddresses/b1'))));

await t('الزبون لا يقرأ سجل البث (broadcasts)', () =>
  assertFails(getDoc(doc(as('alice', 'customer'), 'broadcasts/bc1'))));

await t('حتى الأدمن لا يكتب broadcasts من العميل (Functions فقط)', () =>
  assertFails(setDoc(doc(as('admin1', 'admin'), 'broadcasts/bc2'),
    { title: 'x', body: 'y', audience: 'drivers' })));

await t('السائق يقرأ جوائز المندوبين', () =>
  assertSucceeds(getDoc(doc(as('d1', 'driver'), 'driverPrizes/pr1'))));

await t('السائق لا يعدّل جوائز المندوبين', () =>
  assertFails(updateDoc(doc(as('d1', 'driver'), 'driverPrizes/pr1'),
    { bonus: 999999 })));

await env.cleanup();
console.log(`\n${passed} passed${process.exitCode ? ' — مع إخفاقات!' : ' — كلها ناجحة ✅'}`);
