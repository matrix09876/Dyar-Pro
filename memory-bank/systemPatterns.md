# System Patterns

## RTL أولاً
`EdgeInsetsDirectional` / `AlignmentDirectional` / `start`/`end` (لا left/right).
كل واجهة تُختبر بالعربية. الأرقام/الأسعار LTR-isolated (`MoneyText`).

## التعريب (i18n)
كل نص ظاهر عبر `stringsProvider` → `s('key')` مع `[ar, he, en]` في
`packages/dyar_core/lib/src/i18n/strings.dart`. لا نصوص مكتوبة مباشرة
(الإيموجي مستثنى). إضافة مفتاح = تعديل `strings.dart` + استبدال الحرفي.

## الأيقونات
طبقة `LucideIcons` في `dyar_ui/icons.dart` فوق Material rounded. أي
`LucideIcons.X` مستخدم يجب أن يكون معرّفًا هناك (وإلا فشل تصريف). للتحقّق:
قارن المستخدم `grep -rhoE "LucideIcons\.[a-zA-Z0-9_]+"` بالمعرّف في icons.dart.

## التصميم
القيم من tokens في `dyar_ui` فقط (`DyarTokens`, `DyarTheme`) — لا قيم سحرية.

## الحالة (Riverpod)
المزوّدات المشتركة في `dyar_core/providers.dart`. الأقسام تظهر عبر
`vis()` ← `featureFlagsProvider`/`cityConfigProvider` (تتحكّم بها اللوحة).
المزوّدات التي تلمس Firestore تتدرّج لقيم فارغة آمنة عند الخطأ (`.value ?? empty`).

## الأمان
لا أسرار في الكود/git. tokens في `flutter_secure_storage`. العمليات الحسّاسة
عبر Cloud Functions. `demo-key` في firebase_boot للمحاكي/المعاينة فقط.

## البناء (CI)
APK عبر GitHub Actions: `flutter create` (android/) → ضبط applicationId/minSdk →
[نسخة كاملة: حقن google-services + إضافة Gradle] → `flutter build apk`.
Flutter مثبّت 3.44.2. النسخة الكاملة تحتاج سرّ `GOOGLE_SERVICES_JSON`.
