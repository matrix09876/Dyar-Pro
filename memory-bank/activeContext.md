# Active Context

## الفرع
`claude/project-inspection-tools-dquhn1` — فرع العمل الموحّد (يحوي المشروع الكامل
+ المهارات + الفاحص).

## الهدف الحالي [2026-06-18]
بناء **APK كامل** لتطبيق المستخدم وتجربته على الهاتف.

## الحالة
- ✅ APK **معاينة** (واجهة فقط، `DYAR_DEMO`) بُني ونجح — متاح كـ artifact
  `dyar-user-apk-demo`.
- ✅ خط بناء **النسخة الكاملة** مُتحقَّق منه بالكامل (تشغيل اختباري بملف Firebase
  وهمي نجح: حقن google-services + إضافة Gradle + `flutter build apk --release`).
- ⛔ **عائق وحيد**: السرّ `GOOGLE_SERVICES_JSON` غير مضاف بعد في GitHub →
  `build-apk.yml` يفشل عند خطوة السرّ. يحتاج خطوتين من المالك:
  1) تسجيل تطبيق Android بحزمة `com.dyar.user` في Firebase + تنزيل google-services.json
  2) إضافته كـ GitHub Secret باسم `GOOGLE_SERVICES_JSON`.

## قيود البيئة
- لا Flutter/Android SDK في حاوية Claude → البناء عبر GitHub Actions فقط.
- لا صلاحية API لتشغيل workflow (403) → التشغيل عبر دفعة git أو زر Run workflow.
- لا صلاحية لإنشاء أسرار GitHub أو الدخول لـ Firebase (خطوات المالك).

## أسئلة مفتوحة
- هل أُضيف السرّ؟ (يُعرف فقط من نتيجة البناء — الأسرار مخفية).
