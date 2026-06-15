// صور حقيقية منسّقة (Unsplash CDN) بدل العشوائية — مظهر تطبيق طعام حقيقي
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
initializeApp({ projectId: 'demo-dyar' });
const db = getFirestore();
const U = (id, w=900) =>
  `https://images.unsplash.com/${id}?auto=format&fit=crop&w=${w}&q=70`;

// أغلفة المتاجر
await db.doc('stores/noodles33').set({
  coverUrl: U('photo-1555126634-323283e090fa'),        // نودلز
  logoUrl: U('photo-1569718212165-3a8278d5f624', 200),
}, { merge: true });
await db.doc('stores/pizzaroma').set({
  coverUrl: U('photo-1565299624946-b28f40a0ae38'),     // بيتزا
}, { merge: true });
await db.doc('stores/flowershop').set({
  coverUrl: U('photo-1487530811176-3780de880c2d'),     // ورود
}, { merge: true });

// أطباق نودلز 33
const dishes = [
  'photo-1569718212165-3a8278d5f624', // shrimp noodles
  'photo-1552611052-33e04de081de',    // wings noodles
  'photo-1512058564366-18510be2db19', // meal deal
  'photo-1585032226651-759b368d7246', // pasta bowl
];
const menu = await db.collection('stores/noodles33/menu').get();
let i = 0;
for (const d of menu.docs) {
  await d.ref.set({ imageUrl: U(dishes[i++ % dishes.length], 400) }, { merge: true });
}
console.log('real photos set');
