# Dyar v10 — سوبر آب التوصيل والخدمات 🚀

منظومة متكاملة تنافس Wolt / HAAT / Talabat / Uber / Careem:
**لوحة تحكم + تطبيق الزبون + تطبيق السائق + تطبيق التاجر** على خلفية Firebase واحدة.
ثلاثي اللغة (عربي/عبري/إنجليزي) مع RTL/LTR تلقائي + وضع ليلي.

## الهيكل

| المسار | المكوّن |
|---|---|
| `dashboard/` | لوحة التحكم (React + Vite + TS + Tailwind) |
| `backend/` | Firebase: قواعد أمان، فهارس، Cloud Functions |
| `apps/user` | تطبيق الزبون (Flutter) |
| `apps/driver` | تطبيق السائق (Flutter) |
| `apps/partner` | تطبيق التاجر (Flutter) |
| `packages/dyar_core` | نماذج + خدمات Firebase + i18n مشتركة |
| `packages/dyar_ui` | نظام تصميم Dyar Ultra UI (ثيم/ويدجتس) |
| `docs/` | عقد البيانات + خارطة الطريق |

## التشغيل السريع

### 1) لوحة التحكم
```bash
cd dashboard
cp .env.example .env       # أدخل مفاتيح Firebase Web
npm install && npm run dev
```

### 2) الخلفية (مرة واحدة لكل مشروع Firebase)
```bash
npm i -g firebase-tools
cd backend
firebase login && firebase use <PROJECT_ID>
firebase deploy --only firestore:rules,firestore:indexes,storage
cd functions && npm install && cd ..
firebase deploy --only functions
# أسرار Stripe:
firebase functions:secrets:set STRIPE_SECRET
firebase functions:secrets:set STRIPE_WEBHOOK
```

### 3) تطبيقات Flutter
```bash
dart pub global activate melos
melos bootstrap
# اربط Firebase لكل تطبيق (يولّد firebase_options.dart):
cd apps/user    && flutterfire configure && flutter run
cd apps/driver  && flutterfire configure && flutter run
cd apps/partner && flutterfire configure && flutter run
```

### 4) إنشاء أول مدير (Admin)
أنشئ مستخدمًا في Firebase Auth ثم من Cloud Shell:
```js
admin.auth().setCustomUserClaims('<UID>', { role: 'admin' })
```

## المفاتيح المطلوبة من المالك
- إعدادات Firebase (Web + Android + iOS)
- Stripe (publishable + secret + webhook)
- Google Maps API key
- حسابات النشر (Apple Developer / Google Play)

> 🔒 لا أسرار داخل الكود إطلاقًا — كل المفاتيح عبر `.env` / Secrets.
