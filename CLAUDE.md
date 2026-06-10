# Dyar — سياق المشروع (Project Context)

> منظومة عقارية/خدمية مبنية بـ **Flutter (Dart)** تستهدف iOS + Android.
> عربية أولاً (RTL) مع دعم الإنجليزية. التصميم في Figma باسم **Dyar Ultra UI**.

## التطبيقات الأربعة (Apps)

| التطبيق | الجمهور | الدور |
|---|---|---|
| `dyar.app` | عام / Super App | الواجهة الرئيسية والتسويق ونقطة الدخول |
| `dyar.user` | المستخدم النهائي | البحث، التصفّح، الحجز/الطلب، الدفع، التقييم |
| `dyar.partner` | المالك / الوكيل / مزوّد الخدمة | إدارة العروض، الطلبات، التوفر، الأرباح |
| `dyar.driver` | السائق / المندوب الميداني | استلام المهام، الخرائط، التتبّع، الإنجاز |

> الأرجح أن المشاريع الأربعة تشترك في حزمة أساسية (core/design system) — يُفضّل
> هيكلة **monorepo + melos** مع package مشترك (`dyar_core`, `dyar_ui`).

## التقنية (Stack)

- **Flutter / Dart** — تطبيق موبايل (iOS + Android).
- إدارة الحالة: *(يُحدّد — يُنصح بـ Riverpod أو Bloc للاتساق عبر 4 تطبيقات).*
- الشبكة: *(Dio + retrofit مقترح).*
- التخزين الآمن: `flutter_secure_storage` للـ tokens، لا تُخزَّن أسرار في `SharedPreferences`.
- الخرائط (مهم لـ driver/user): Google Maps / Mapbox.
- التعريب: `flutter_localizations` + `intl`، مع **دعم RTL إلزامي**.

## قواعد إلزامية (Hard Rules)

1. **RTL أولاً**: كل واجهة تُختبر في الوضع العربي. استخدم `EdgeInsetsDirectional`،
   `AlignmentDirectional`، `start/end` بدل `left/right`.
2. **لا أسرار في الكود**: مفاتيح الـ API والأسرار عبر `--dart-define` / متغيرات بيئة،
   لا تُرفع إلى git أبداً.
3. **الأداء**: حافظ على 60fps. تجنّب إعادة بناء الـ widgets غير الضرورية، استخدم
   `const` constructors، و `ListView.builder` للقوائم الطويلة.
4. **التصميم من Figma فقط**: التزم بـ tokens من *Dyar Ultra UI* (ألوان، مسافات، خطوط).

## المهارات المتاحة (Skills) — في `.claude/skills/`

| المهارة | الاستدعاء | الوظيفة |
|---|---|---|
| `llm-council` | `council this` | مجلس 5 مستشارين لمراجعة القرارات |
| `flutter-code-review` | `راجع الكود` / `review flutter` | مراجعة جودة وصحّة كود Flutter/Dart |
| `flutter-security-audit` | `فحص أمني` / `security audit` | فحص أمان (MASVS): تخزين، tokens، API |
| `flutter-testing` | `اكتب اختبارات` / `add tests` | اختبارات unit/widget/integration/golden |
| `flutter-performance` | `حسّن الأداء` / `optimize perf` | معالجة الـ jank وتحسين الأداء |
| `figma-to-flutter` | `حوّل التصميم` / `figma to flutter` | تحويل Dyar Ultra UI إلى widgets |
| `ux-ui-review` | `راجع التصميم` / `ux review` | مراجعة UX/UI + RTL + إتاحة |
| `competitor-analysis` | `حلل المنافسين` / `competitor analysis` | تحليل منافسي تطبيقات العقارات |

## ملاحظة

المستودع حالياً في مرحلة التأسيس. حدّث هذا الملف فور إضافة الكود الفعلي
(هيكل المجلدات، حزمة إدارة الحالة المختارة، أوامر البناء والاختبار).
