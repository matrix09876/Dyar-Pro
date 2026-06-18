# Progress

## المنجز ✅
- [x] إضافة مهارات الفحص: `llm-council` + حزمة Flutter (code-review, security,
      testing, performance, figma-to-flutter, ux-ui-review, competitor-analysis).
- [x] دمج المشروع الكامل (327 ملف) إلى فرع العمل الموحّد.
- [x] فحص تطبيق المستخدم ↔ تصميم Dyar Ultra UI (مطابق، مترابط، جاهز).
- [x] إصلاح i18n: تعريب 4 نصوص (nearbyPopular, seeAll, playVideo, b2bWholesale).
- [x] **إصلاح خطأ تصريف حقيقي**: أيقونات Lucide ناقصة (sparkles, locate,
      locateFixed) في `dyar_ui/icons.dart` — كانت تمنع البناء.
- [x] وضع المعاينة `DYAR_DEMO` (تهيئة Firebase وهمية) + workflow ديمو.
- [x] بناء APK المعاينة بنجاح.
- [x] التحقّق من خط بناء النسخة الكاملة (بملف وهمي) — نجح end-to-end.
- [x] إضافة skill `memory-bank` (تكييف RooFlow).

## الجاري 🔄
- [ ] بناء APK الكامل — موقوف على إضافة السرّ `GOOGLE_SERVICES_JSON`.

## التالي ⏭️
- [ ] (بعد السرّ) تشغيل `build-apk.yml` ومراقبته حتى يخرج APK كامل.
- [ ] تجهيز نفس خط البناء لـ `driver` و`partner`.
- [ ] فجوات الإطلاق: مفتاح Google Maps · Firebase App Check · صور منتجات حقيقية.
- [ ] تشغيل `flutter analyze` + الاختبارات على بيئة فيها SDK (أو إبقاؤها في CI).
