// هوية المينيو (stores.brand) + أقسام مينيو نودلز 33 — يعمل على المحاكي:
//   FIRESTORE_EMULATOR_HOST=localhost:8080 node seed/enrich5.mjs
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
initializeApp({ projectId: 'demo-dyar' });
const db = getFirestore();
const U = (id, w = 400) =>
  `https://images.unsplash.com/${id}?auto=format&fit=crop&w=${w}&q=70`;

// قوالب الهوية لكل متجر (MenuBrand في dyar_ui)
await db.doc('stores/noodles33').set(
  { brand: { template: 'street' } }, { merge: true });   // جريء برتقالي-أحمر
await db.doc('stores/pizzaroma').set(
  { brand: { template: 'elegant' } }, { merge: true });  // داكن ذهبي فاخر
await db.doc('stores/flowershop').set(
  { brand: { template: 'boutique' } }, { merge: true }); // بنفسجي راقٍ

// أقسام مينيو نودلز 33: الأطباق الحالية + قسم إضافات جديد
const menu = db.collection('stores/noodles33/menu');
const existing = await menu.get();
for (const d of existing.docs) {
  await d.ref.set({ categoryId: 'الأطباق' }, { merge: true });
}
const extras = [
  ['بطاطا مقلية', 'مقرمشة مع صوص الثوم', 1500,
    'photo-1573080496219-bb080dd4f877'],
  ['كولا باردة', 'علبة 330 مل', 800,
    'photo-1554866585-cd94860890b7'],
];
for (const [i, [name, description, price, photo]] of extras.entries()) {
  await menu.doc(`extra${i + 1}`).set({
    name, description, price, available: true,
    sortOrder: 100 + i, categoryId: 'الإضافات', imageUrl: U(photo),
  }, { merge: true });
}
console.log('✓ brand identities (street/elegant/boutique) + noodles sections (الأطباق/الإضافات)');
