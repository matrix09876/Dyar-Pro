# Dyar v10 — سياق المشروع (Project Context)

> **اسم المشروع الرسمي: Dyar v10** — مشروع جديد مبني من الصفر (ليس قالبًا
> جاهزًا ولا استنساخًا)، هدفه التفوق على Wolt / HAAT / Talabat / Uber / Careem.

> **ديار = سوبر آب توصيل وطلبات وخدمات (Delivery Super-App)** على غرار
> **Wolt / Haat.delivery / Talabat**. الهدف: منتج أقوى من المنافسين.
> يخدم: طعام من المطاعم، بقالة، صيدليات، متاجر، ورود، **وخدمات** (حلاقة،
> صالونات، أطباء، ميكانيكيين...)، بالإضافة إلى **توصيل + نقل** عبر السائقين.
>
> عربية أولاً (RTL) + إنجليزية + عبرية (سوق إسرائيل حاليًا). التصميم في
> Figma باسم **Dyar Ultra UI**.

> ⚠️ ملاحظة: وصف سابق صنّف ديار خطأً كتطبيق "عقارات". هذا غير صحيح — ديار
> تطبيق توصيل/طلبات، وهذا الملف هو مصدر الحقيقة.

## المنظومة — 4 عملاء + خلفية واحدة

| المكوّن | المنصة | الجمهور | الحالة |
|---|---|---|---|
| **Dashboard (لوحة التحكم)** | Web — React+Vite+TS | الإدارة | **المرحلة 1 (الأولوية)** |
| `dyar.driver` | Flutter (iOS+Android) | السائق/المندوب | مرحلة 2 |
| `dyar.partner` | Flutter | التاجر/المتجر | مرحلة 3 |
| `dyar.user` | Flutter | الزبون | مرحلة 4 |
| `dyar.app` (web) | React | تسويق + طلب ويب | لاحقًا |

**كل العملاء يتصلون بخلفية Firebase واحدة** (مصدر حقيقة واحد). لوحة التحكم
هي المتحكّم المركزي: المتاجر، الطلبات، السائقون، المستخدمون، الأصناف،
العروض، المدفوعات، الإعدادات، التحليلات.

## التقنية (Stack)

### الخلفية — `backend/` (Firebase)
- **Firestore** — قاعدة بيانات لحظية. انظر `docs/DATA-MODEL.md`.
- **Firebase Auth** — مصادقة (هاتف/OTP + بريد). أدوار عبر Custom Claims:
  `admin`, `partner`, `driver`, `customer`.
- **Cloud Functions (TypeScript)** — دورة حياة الطلب، تعيين السائق،
  مدفوعات Stripe/PayPal، إشعارات FCM، التسويات المالية.
- **Storage** — صور المتاجر/المنتجات/الوثائق.
- **FCM** — إشعارات لحظية لكل تطبيق.

### لوحة التحكم — `dashboard/`
- React 18 + Vite + TypeScript + TailwindCSS + React Router + TanStack Query.
- Firebase Web SDK. رسوم: Recharts. RTL إلزامي.

### الموبايل — `apps/*` + `packages/*`
- Flutter / Dart، monorepo بـ **melos**. حزم مشتركة: `dyar_core` (نماذج،
  خدمات Firebase، حالة)، `dyar_ui` (نظام تصميم Dyar Ultra UI).
- إدارة الحالة: **Riverpod**. الخرائط: Google Maps. التعريب: `intl`.

## هيكل المستودع (Monorepo)

```
Dyar-Pro/
├── CLAUDE.md                 # مصدر الحقيقة
├── docs/                     # المعمارية، نموذج البيانات، خارطة الطريق
├── backend/                  # Firebase (rules, functions, indexes)
│   └── functions/src/        # Cloud Functions (TypeScript)
├── dashboard/                # لوحة التحكم (React) — المرحلة 1
├── apps/                     # تطبيقات Flutter (المراحل 2–4)
│   ├── driver/ partner/ user/
└── packages/                 # حزم Flutter مشتركة (dyar_core, dyar_ui)
```

## أوامر البناء والتشغيل

| المهمة | الأمر |
|---|---|
| تشغيل لوحة التحكم | `cd dashboard && npm install && npm run dev` |
| بناء لوحة التحكم | `cd dashboard && npm run build` |
| Cloud Functions | `cd backend/functions && npm install && npm run build` |
| نشر القواعد | `cd backend && firebase deploy --only firestore:rules,storage` |
| نشر الدوال | `cd backend && firebase deploy --only functions` |

## قواعد إلزامية (Hard Rules)

1. **لا أسرار في الكود**: كل المفاتيح عبر `.env` (لوحة) و
   `functions:config`/`--dart-define` (دوال/موبايل). القوالب في `.env.example`.
2. **RTL أولاً**: كل واجهة تُختبر بالعربية. ويب `dir="rtl"`؛ Flutter `start/end`.
3. **الأمان أولًا**: Firestore Rules تمنع أي وصول غير مصرّح. كل عملية حساسة
   (دفع، تغيير حالة، أرباح) تمرّ عبر Cloud Functions.
4. **التصميم من Figma**: التزم بـ tokens من *Dyar Ultra UI*.
5. **عقد بيانات واحد**: أي تغيير يُحدَّث في `docs/DATA-MODEL.md` + الأنواع +
   قواعد الأمان معًا.

## المفاتيح المطلوبة من المالك (تُضاف لاحقًا)
- إعدادات مشروع Firebase. مفاتيح Stripe/PayPal. مفتاح Google Maps.
- شهادات النشر (Apple Developer + Google Play).

## المهارات (`.claude/skills/`)
`llm-council`, `flutter-code-review`, `flutter-security-audit`,
`flutter-testing`, `flutter-performance`, `figma-to-flutter`,
`ux-ui-review`, `competitor-analysis`.

## الحالة الحالية
المرحلة 1 قيد الإنشاء: تأسيس الـ monorepo + خلفية Firebase (عقد البيانات،
القواعد، هيكل الدوال) + لوحة التحكم.
