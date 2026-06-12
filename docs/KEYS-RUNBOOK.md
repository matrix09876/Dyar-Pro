# 🔑 دليل إدخال المفاتيح — الخطوة الأخيرة قبل الإطلاق

كل الكود جاهز ويستهلك هذه القيم تلقائيًا. نفّذ بالترتيب.

## 1) Firebase (الأساس — كل شيء خلفه)
> ✅ **حالة 12/06/2026 — مشروع `dyar-ai`**: ‏Auth (Email+Phone) ✓ ·
> ‏Storage في ME-WEST1 ✓ · خطة Blaze ✓ · ‏Web config مركّب في
> ‏`dashboard/.env(.example)` ✓ · سكربت نشر جاهز: `scripts/deploy-prod.sh`
> ⏳ **متبقٍ واحد**: قاعدة Firestore ‏`(default)` في `nam5` — يجب
> حذفها (قرار المالك، تدميري) وإنشاؤها في **me-west1** قبل أول نشر.
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
> ✅ **التكامل مجرَّب حيًا بطرفية الاختبار (12/06/2026)**: توكن
> ‏identity ‏200 ✓ ثم PaymentIntent ‏201 برابط Checkout ✓ —
> أدخل مفاتيح **الإنتاج** بنفس الخطوات وستعمل من أول مرة.
```bash
firebase functions:secrets:set EASYCARD_TERMINAL_ID   # من لوحة EasyCard
firebase functions:secrets:set EASYCARD_API_KEY       # المفتاح الخاص (Reset Private Key)
firebase functions:secrets:set EASYCARD_WEBHOOK_SECRET # قيمة عشوائية قوية تختارها
firebase deploy --only functions:createEasycardPayment,functions:easycardWebhook
```
ثم اطلب من فريق EasyCard (يُضبط من طرفهم حاليًا) تسجيل webhook
على الطرفية بحدث **PaymentTransaction** إلى:
`https://<region>-<PROJECT_ID>.cloudfunctions.net/easycardWebhook`
مع ترويسة أمان مخصصة: الاسم `X-Dyar-Secret` والقيمة نفس
`EASYCARD_WEBHOOK_SECRET`. الـwebhook عندنا لا يثق بالحمولة —
يتحقق من كل معاملة بالاستعلام المباشر `GET /api/transactions/{id}`.
(بديل/إضافي: `STRIPE_SECRET` + `STRIPE_WEBHOOK` بنفس الطريقة.)

## 4) Google Maps
- مفتاح Android في `apps/driver/android/app/src/main/AndroidManifest.xml`
  (meta-data `com.google.android.geo.API_KEY`).
- مفتاح iOS في `AppDelegate`. مفتاح Web (اختياري للوحة المناطق).

## 5) البريد (اختياري لكنه جاهز)
ثبّت Firebase Extension **Trigger Email** على مجموعة `mail` بحساب SMTP —
قوالبنا تُحقن تلقائيًا من `config/emails`.

## 6) الصوت — ElevenLabs (اختياري، مجرَّب حيًا ✓)
> دالة `speak` جاهزة: نطق عربي/عبري/إنجليزي (multilingual_v2) لردود
> Dyar Bot وإعلانات السائق الصوتية. جُرّبت بمفتاحك (12/06): ‏200 ✓.
```bash
firebase functions:secrets:set ELEVENLABS_API_KEY
# اختياري — صوت مخصص بدل الافتراضي:
firebase functions:secrets:set ELEVENLABS_VOICE_ID
firebase deploy --only functions:speak,functions:liveSupportUrl
```
> 🎙️ **الوكيل الصوتي الحي**: محادثة فورية كبشري لخدمة العملاء —
> أنشئه مرة واحدة حسب `docs/VOICE-AGENT.md` والصق Agent ID في
> اللوحة → الإعدادات → صوت ديار.
> ⚠️ المفتاح الذي أُرسل في الدردشة (sk_…) صار مكشوفًا — **دوّره** من
> لوحة ElevenLabs قبل الإطلاق وأدخل الجديد بالأمر أعلاه فقط.

## 7) النشر للمتاجر
```bash
cd apps/user && flutter build appbundle   # ثم Google Play Console
open ios/Runner.xcworkspace               # Archive ثم App Store Connect
```
المعرّفات: `com.dyar.user` · `com.dyar.partner` · `com.dyar.driver`.

> ✅ بعد البند 1 تعمل المنظومة كاملة على الإنتاج (الدفع نقدًا).
> بعد البند 3 يتفعّل VISA/Bit. لا يوجد أي مكان آخر يحتاج مفاتيح.


## 8) App Check (درع ضد البوتات وإساءة الاستخدام)
في Firebase Console → App Check: فعّل **Play Integrity** (أندرويد)،
**App Attest** (iOS)، **reCAPTCHA v3** (الويب)، ثم Enforce على
Firestore وFunctions. التطبيقات جاهزة — أضف سطر التفعيل في
`firebase_boot.dart` بعد initializeApp:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```
(حزمة firebase_app_check تُضاف مع flutterfire configure.)
