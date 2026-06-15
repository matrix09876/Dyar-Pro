// مجموعات خيارات الأصناف (نمط Wolt/Talabat) لمتجر الديمو
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
initializeApp({ projectId: 'demo-dyar' });
const db = getFirestore();

await db.doc('stores/noodles33/options/extras').set({
  name: 'الإضافات',
  active: true,
  sortOrder: 0,
  choices: [
    { name: 'جبنة إضافية', price: 400, active: true },
    { name: 'صوص حار 🌶️', price: 200, active: true },
    { name: 'دجاج مقرمش', price: 800, active: true },
    { name: 'خضار إضافية', price: 300, active: true },
  ],
  showInKiosk: true,
});
console.log('options seeded');
