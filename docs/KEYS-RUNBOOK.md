# 🔑 دليل إدخال المفاتيح — الخطوة الأخيرة قبل الإطلاق

كل الكود جاهز ويستهلك هذه القيم تلقائيًا. نفّذ بالترتيب.

## 1) Firebase (الأساس — كل شيء خلفه)
أنشئ مشروعًا على console.firebase.google.com ثم:
```bash
# اللوحة + الموقع
cd dashboard && cp .env.example .env   # واملأ قيم Web app من إعدادات المشروع

# التطبيقات الثلاثة (يولّد firebase_options.dart + ملفات أندرويد/iOS)
dart pub global activate flutterfire_cli
cd apps/user    && flutterfire configure
cd apps/partner && flutterfire configure
cd apps/driver  && flutterfire configure

# الخلفية
cd backend && firebase use <PROJECT_ID>
firebase deploy --only firestore:rules,firestore:indexes,storage
cd functions && npm i && cd .. && firebase deploy --only functions
```
**لـ OTP والإشعارات:** أضف بصمات SHA-1/SHA-256 لتطبيق أندرويد في إعدادات
المشروع، وارفع مفتاح APNs لآبل. فعّل Phone + Email في Authentication.

## 2) أول مدير
أنشئ المستخدم في Authentication ثم من Cloud Shell/Node بـ Admin SDK:
```js
admin.auth().setCustomUserClaims('<UID>', { role: 'admin' })
```

## 3) الدفع — EasycardNG (يفعّل VISA + Bit فورًا)
```bash
firebase functions:secrets:set EASYCARD_TERMINAL_ID
firebase functions:secrets:set EASYCARD_API_KEY
firebase deploy --only functions:createEasycardPayment,functions:easycardWebhook
```
ثم سجّل رابط الـ webhook في لوحة EasyCard:
`https://<region>-<PROJECT_ID>.cloudfunctions.net/easycardWebhook`
(بديل/إضافي: `STRIPE_SECRET` + `STRIPE_WEBHOOK` بنفس الطريقة.)

## 4) Google Maps
- مفتاح Android في `apps/driver/android/app/src/main/AndroidManifest.xml`
  (meta-data `com.google.android.geo.API_KEY`).
- مفتاح iOS في `AppDelegate`. مفتاح Web (اختياري للوحة المناطق).

## 5) البريد (اختياري لكنه جاهز)
ثبّت Firebase Extension **Trigger Email** على مجموعة `mail` بحساب SMTP —
قوالبنا تُحقن تلقائيًا من `config/emails`.

## 6) النشر للمتاجر
```bash
cd apps/user && flutter build appbundle   # ثم Google Play Console
open ios/Runner.xcworkspace               # Archive ثم App Store Connect
```
المعرّفات: `com.dyar.user` · `com.dyar.partner` · `com.dyar.driver`.

> ✅ بعد البند 1 تعمل المنظومة كاملة على الإنتاج (الدفع نقدًا).
> بعد البند 3 يتفعّل VISA/Bit. لا يوجد أي مكان آخر يحتاج مفاتيح.
