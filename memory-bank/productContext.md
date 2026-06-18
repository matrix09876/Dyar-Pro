# Product Context — Dyar v10

> ذاكرة المشروع (Memory Bank). مصدر الحقيقة الكامل: `CLAUDE.md`.

## ما هو
**ديار = سوبر-آب توصيل وطلبات وخدمات** (Delivery Super-App) على غرار Wolt/HAAT/
Talabat. عربية أولاً (RTL) + عبرية + إنجليزية. سوق الجليل/إسرائيل. التصميم في
Figma باسم **Dyar Ultra UI**. الهدف: التفوّق على المنافسين (Scorecard ≈ 101/120).

## المنظومة (monorepo + melos)
- `apps/user` — الزبون (طعام/متاجر/خدمات/تاكسي/طرود/محفظة).
- `apps/partner` — التاجر/المزوّد.
- `apps/driver` — السائق/المندوب.
- `packages/dyar_core` — نماذج + خدمات Firebase + حالة (Riverpod) + providers + i18n.
- `packages/dyar_ui` — نظام التصميم (tokens, theme, LucideIcons shim, widgets).
- `backend/` — Firebase (Functions TS + Firestore Rules + Indexes).
- `dashboard/` (React) + `web/` (موقع) + `docs/`.

## التقنية
Flutter/Dart · Riverpod · Firebase (Auth هاتف/OTP + بريد، Firestore، Functions،
FCM، Storage) · Google Maps · google_fonts (Noto Sans Arabic).

## design tokens (dyar_ui)
برتقالي `#F4691E` / داكن `#E04E12` / فاتح `#FFE6D5` · ink `#1A1A1F` · radius 16 ·
CTA 54px · لمس ≥44px · خط Noto Sans Arabic. الأيقونات: طبقة `LucideIcons` فوق
Material rounded (قرار Figma: إيموجي→Lucide في الـ chrome).

## أعلام الميزات
الأقسام تظهر/تُخفى عبر `featureFlagsProvider` (config/features) و`cityConfigProvider`
(cities/{id}.categories) — تتحكّم بها لوحة التحكم لكل مدينة.
