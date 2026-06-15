// بذر بيانات تجريبية كاملة لمنظومة ديار — تعمل على المحاكي بلا أي مفاتيح:
//   FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
//   node seed/seed.mjs
// تنشئ: مدير + تاجر + سائق + زبون، متجرين بقائمة أصناف، كوبون، إعدادات، وطلب تجريبي.
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

process.env.GCLOUD_PROJECT ||= 'demo-dyar';
initializeApp({ projectId: 'demo-dyar' });
const db = getFirestore();
const auth = getAuth();

async function user(email, password, role, name) {
  const u = await auth.createUser({ email, password, displayName: name });
  await auth.setCustomUserClaims(u.uid, { role });
  await db.doc(`users/${u.uid}`).set({
    role, name, email, walletBalance: 0, status: 'active',
    createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
  });
  console.log(`✓ ${role}: ${email} / ${password}`);
  return u.uid;
}

const admin = await user('admin@dyar.app', 'admin1234', 'admin', 'مدير ديار');
const partner = await user('partner@dyar.app', 'partner1234', 'partner', 'نودلز 33');
const driver = await user('driver@dyar.app', 'driver1234', 'driver', 'سائق ديار');
const customer = await user('customer@dyar.app', 'customer1234', 'customer', 'أمين');

// مدينة + أصناف
await db.doc('cities/galilee').set({ name: 'الجليل', country: 'IL', active: true });
await db.doc('categories/food').set({ name: 'طعام', icon: 'utensils', type: 'restaurant', sortOrder: 1, active: true });

// متجر معتمد بقائمة
const store = db.collection('stores').doc('noodles33');
await store.set({
  ownerUid: partner, name: 'نودلز 33', type: 'restaurant',
  description: 'طعم لا يُنسى في كل لقمة', cityId: 'galilee',
  location: { lat: 32.871, lng: 35.372, address: "Bi'ina, Israel" },
  isOpen: true, status: 'approved', rating: 5, ratingCount: 6,
  deliveryFee: 1000, minOrder: 3000, prepTimeMins: 25, commissionPct: 10,
  createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
});
const menu = [
  ['نودلز شريمبس', 'نودلز آسيوية شهية مع جمبري طازج', 5500],
  ['نودلز أجنحة', 'نودلز آسيوية مع أجنحة دجاج مقرمشة', 5000],
  ['حملة — وجبة + سلطة', 'نودلز باستا أو رافيولي', 8500],
];
for (const [i, [name, description, price]] of menu.entries()) {
  await store.collection('menu').add({
    name, description, price, available: true, sortOrder: i, categoryId: 'food',
  });
}
console.log('✓ store noodles33 + 3 menu items');

// سائق معتمد متصل
await db.doc(`drivers/${driver}`).set({
  vehicle: { type: 'motorcycle', plate: '12-345-67' },
  isOnline: true, status: 'approved',
  currentLocation: { lat: 32.868, lng: 35.37, heading: 0, at: Timestamp.now() },
  earnings: { today: 0, week: 0, total: 0 }, rating: 5,
});
console.log('✓ driver online & approved');

// كوبون + إعدادات + عرض
await db.collection('coupons').add({
  code: 'DYAR10', type: 'pct', value: 10, minOrder: 2000,
  usageLimit: 100, usedCount: 0, active: true,
  expiresAt: Timestamp.fromDate(new Date(Date.now() + 90 * 864e5)),
});
await db.doc('config/app').set({
  serviceFee: 200, defaultCommissionPct: 10, currency: 'ils',
  supportPhone: '+972500000000', referralReward: 1000,
  maintenanceMode: false, surgeEnabled: true,
});
await db.collection('promotions').add({
  title: 'توصيل مجاني فوق ₪80', active: true, sortOrder: 1,
});
console.log('✓ coupon DYAR10 + config + promotion');

// طلب تجريبي حي (pending) ليظهر فورًا في اللوحة وتطبيق التاجر
const items = [{ itemId: 'demo', name: 'نودلز شريمبس', qty: 2, unitPrice: 5500, options: [], lineTotal: 11000 }];
await db.collection('orders').add({
  code: 'DYDEMO', customerUid: customer, storeId: 'noodles33',
  items, status: 'pending', type: 'delivery',
  address: { line: "Bi'ina, Israel", lat: 32.87, lng: 35.37 },
  pricing: { subtotal: 11000, deliveryFee: 1000, serviceFee: 200, discount: 0, tip: 0, total: 12200 },
  payment: { method: 'cash', status: 'pending' },
  timeline: [{ status: 'pending', at: Timestamp.now(), by: customer }],
  createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
});
console.log('✓ demo order DYDEMO (pending)');
console.log('\n🎉 Seed complete — sign in to the dashboard with admin@dyar.app / admin1234');
