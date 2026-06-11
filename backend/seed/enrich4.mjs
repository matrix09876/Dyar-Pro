// مقدمو خدمات (stores type=service + serviceCategory) لشاشة "خدمات":
//   FIRESTORE_EMULATOR_HOST=localhost:8080 node seed/enrich4.mjs
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
initializeApp({ projectId: 'demo-dyar' });
const db = getFirestore();
const U = (id, w = 900) =>
  `https://images.unsplash.com/${id}?auto=format&fit=crop&w=${w}&q=70`;

// كهربائي — نور للكهرباء
await db.doc('stores/noor-electric').set({
  ownerUid: 'demo', name: 'نور للكهرباء', type: 'service',
  serviceCategory: 'electrician',
  description: 'تمديدات وصيانة كهرباء منازل ومحلات — خدمة 24 ساعة',
  cityId: 'galilee', phone: '+972500000111',
  location: { lat: 32.88, lng: 35.36, address: 'Karmiel' },
  isOpen: true, status: 'approved', rating: 4.9, ratingCount: 58,
  deliveryFee: 0, minOrder: 0, prepTimeMins: 30, commissionPct: 6,
  coverUrl: U('photo-1621905251918-48416bd8575a'), // electrician at work
  createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
}, { merge: true });

// محاسب — مكتب الأمين
await db.doc('stores/alamin-accounting').set({
  ownerUid: 'demo', name: 'مكتب الأمين', type: 'service',
  serviceCategory: 'accountant',
  description: 'محاسبة وضرائب للأفراد والشركات — استشارة أولى مجانًا',
  cityId: 'galilee', phone: '+972500000222',
  location: { lat: 32.87, lng: 35.37, address: "Bi'ina" },
  isOpen: true, status: 'approved', rating: 5, ratingCount: 23,
  deliveryFee: 0, minOrder: 0, prepTimeMins: 45, commissionPct: 6,
  coverUrl: U('photo-1554224155-6726b3ff858f'), // accounting desk
  createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
}, { merge: true });

console.log('✓ service providers seeded: noor-electric (electrician), alamin-accounting (accountant)');
