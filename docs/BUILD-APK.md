# بناء APK لتطبيق المستخدم (Dyar User) عبر GitHub Actions

تبني الـ APK سحابياً (لا حاجة لتثبيت Flutter محلياً) وتنزّله على هاتفك.

## خطوة لمرة واحدة

### 1) سجّل تطبيق Android في Firebase
- افتح [Firebase Console](https://console.firebase.google.com) ← مشروعك ← ⚙️ Project settings.
- Your apps ← Add app ← Android.
- **Android package name:** `com.dyar.user` (مهم — يجب أن يطابق هذا الاسم بالضبط).
- نزّل ملف **`google-services.json`**.

### 2) أضِف الملف كـ Secret في GitHub
- GitHub ← المستودع ← **Settings** ← **Secrets and variables** ← **Actions**.
- **New repository secret**:
  - Name: `GOOGLE_SERVICES_JSON`
  - Secret: الصق **كامل محتوى** ملف `google-services.json`.

## كل مرة تريد APK

1. تبويب **Actions** ← workflow **"Build User APK"** ← **Run workflow**.
   - اختر `release` (موصى به) أو `debug`.
2. انتظر انتهاء البناء (~5–10 دقائق).
3. افتح صفحة التشغيل ← قسم **Artifacts** ← نزّل **`dyar-user-apk`** (ملف zip فيه الـ APK).
4. على الهاتف: فك الضغط، ثبّت الـ APK (فعّل **«تثبيت من مصادر غير معروفة»** للمتصفح/الملفات).

## ملاحظات

- **اسم الحزمة ثابت** `com.dyar.user` — لو سجّلت اسماً مختلفاً في Firebase، عدّل `APP_ID`
  في `.github/workflows/build-apk.yml`.
- الـ APK موقّع بمفتاح debug (يُثبّت ويُجرّب)، **ليس للنشر على Google Play** — النشر يحتاج
  keystore حقيقي + توقيع release.
- الخرائط (Google Maps) ستظهر فارغة حتى يُضاف **Maps API key** — بقية الميزات تعمل.
- أول تشغيل يحتاج إنترنت (يتصل بـ Firebase). الدخول عبر الهاتف/OTP يحتاج تفعيل
  **Phone Auth** في Firebase + إضافة بصمة SHA لاحقاً.
