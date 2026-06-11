import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
initializeApp({ projectId: 'demo-dyar' });
const db = getFirestore();
const img = (seed, w=800, h=450) => `https://picsum.photos/seed/${seed}/${w}/${h}`;
await db.doc('stores/noodles33').set({ coverUrl: img('noodles'), logoUrl: img('nlogo',200,200) }, { merge: true });
const menu = await db.collection('stores/noodles33/menu').get();
let i = 0; for (const d of menu.docs) await d.ref.set({ imageUrl: img('dish'+(i++),400,300) }, { merge: true });
await db.doc('stores/pizzaroma').set({
  ownerUid: 'demo', name: 'بيتزا روما', type: 'restaurant',
  description: 'بيتزا إيطالية على الحطب', cityId: 'galilee',
  location: { lat: 32.9, lng: 35.3, address: 'Karmiel' },
  isOpen: true, status: 'approved', rating: 4.8, ratingCount: 124,
  deliveryFee: 800, minOrder: 4000, prepTimeMins: 30, commissionPct: 12,
  coverUrl: img('pizza'), createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
}, { merge: true });
await db.doc('stores/flowershop').set({
  ownerUid: 'demo', name: 'ورود الجليل', type: 'flowers',
  description: 'باقات فاخرة ليوم مميز', cityId: 'galilee',
  location: { lat: 32.91, lng: 35.31, address: 'Karmiel' },
  isOpen: true, status: 'approved', rating: 4.9, ratingCount: 87,
  deliveryFee: 1200, minOrder: 5000, prepTimeMins: 40, commissionPct: 10,
  coverUrl: img('flowers'), createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
}, { merge: true });
console.log('enriched');
