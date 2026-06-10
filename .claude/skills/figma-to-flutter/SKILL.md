---
name: figma-to-flutter
description: "Convert Dyar Ultra UI Figma designs into clean, reusable Flutter widgets and a shared design system (tokens, theme, components) with RTL support. TRIGGERS: 'حوّل التصميم', 'figma to flutter', 'نفّذ التصميم', 'implement design', 'حوّل من فيجما', 'dyar ultra ui', 'صمّم الشاشة', 'design system'. Use when the user wants to turn a Figma screen/component into Flutter code, build the design system, extract tokens, or implement the Dyar Ultra UI. If a figma.com URL or Figma access is available, pull the real design first via the Figma MCP tools."
---

# Figma → Flutter — تنفيذ تصميم Dyar Ultra UI

حوّل تصميم **Dyar Ultra UI** إلى كود Flutter نظيف وقابل لإعادة الاستخدام عبر
التطبيقات الأربعة، مع نظام تصميم موحّد ودعم RTL.

## الخطوة 0: اجلب التصميم الحقيقي

إن وُفّر رابط Figma أو اتصال Figma MCP:
- استخدم أدوات Figma MCP (`get_design_context`, `get_screenshot`, `get_variable_defs`)
  لجلب التصميم الفعلي و**الـ tokens الحقيقية** (ألوان، خطوط، مسافات) — لا تخمّن القيم.
- استخرج `get_variable_defs` لبناء ملف الثيم مباشرة من متغيّرات Figma.
- إن لم يتوفّر وصول، اطلب لقطة/رابط أو القيم المطلوبة قبل التنفيذ.

## الخطوة 1: نظام التصميم أولاً (مرّة واحدة في `dyar_ui`)

لا تكتب ألواناً/قياسات مكتوبة في الشاشات. ابنِ طبقة tokens مشتركة:

```dart
// design tokens مستخرجة من Dyar Ultra UI
abstract class DyarColors { static const primary = Color(0xFF...); /* من Figma */ }
abstract class DyarSpacing { static const sm = 8.0, md = 16.0, lg = 24.0; }
abstract class DyarRadii   { static const card = 16.0; }
abstract class DyarText    { static const TextStyle h1 = TextStyle(...); }
```

ثم `ThemeData` موحّد (`DyarTheme.light/dark`) يُستخدم في التطبيقات الأربعة.
المكوّنات المتكرّرة (`PrimaryButton`, `PropertyCard`, `DyarTextField`) في `dyar_ui` package.

## الخطوة 2: قواعد التحويل

- **القياسات نسبية لا ثابتة قدر الإمكان** — لكن التزم بـ spacing tokens من Figma.
- **استخدم tokens** بدل أي رقم/لون مباشر في الشاشة.
- **RTL إلزامي**: `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`.
- **النصوص من الترجمة** (`AppLocalizations`) لا نصوص ثابتة.
- قسّم الشاشة إلى widgets صغيرة قابلة للاختبار، لا `build()` عملاق.
- استخدم `const` حيثما أمكن.

## الخطوة 3: المطابقة (Fidelity)

- طابق المسافات والأنصاف والظلال والخطوط مع Figma بدقّة.
- نفّذ الحالات: عادي / مضغوط / معطّل / تحميل / خطأ.
- responsive: اختبر على شاشات صغيرة وكبيرة (`LayoutBuilder`/`MediaQuery`).
- ادعم الوضعين الفاتح والداكن إن كانا في التصميم.

## الخطوة 4: التحقق

- قارن الناتج بلقطة Figma (golden test مع نسخة RTL — انظر مهارة flutter-testing).
- تأكّد من عدم وجود overflow في النصوص العربية الطويلة.

## المخرجات

سلّم: (1) tokens/theme في `dyar_ui`، (2) المكوّن/الشاشة، (3) ملاحظة بأي قيم
خمّنتها لغياب وصول Figma كي يصحّحها المستخدم. اقترح وضع المكوّنات القابلة لإعادة
الاستخدام في الحزمة المشتركة لا داخل تطبيق واحد.
