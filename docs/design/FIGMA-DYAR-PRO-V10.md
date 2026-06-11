# Figma — DYAR PRO V10 · موجة تطبيق المستخدم (User App Wave)

> وثيقة تسليم وكيل التصميم — تاريخ: 2026-06-11

## الملف

| | |
|---|---|
| **اسم الملف** | DYAR PRO V10 |
| **fileKey** | `FtF2s8zxdAMS2nDJeUFYPS` |
| **الرابط** | https://www.figma.com/design/FtF2s8zxdAMS2nDJeUFYPS |
| **الخطة** | DYAR APP - OPCYBERS (`organization::1559690530317643385`) |
| **الصفحة** | `0:1` — **01 · Dyar User — FINAL** |
| **الخط** | Noto Sans Arabic (Regular/Medium/SemiBold/Bold/Black) |
| **الألوان** | من `packages/dyar_ui/lib/src/tokens.dart` — الأساسي `#F4691E`، الداكن `#E04E12`، الفاتح `#FFE6D5`، التدرّج `FF8A3D→F4691E→E04E12`، ink `#1A1A1F`، داكن `#15151A` / بطاقات `#1E1E25` |

## الإطارات (10 × iPhone 390×844، صف واحد بترقيم برتقالي)

| # | الإطار | nodeId | المصدر (الكود المنفّذ) |
|---|---|---|---|
| 1 | 1-Splash-Onboarding | `1:2` | هوية ديار (لوغو نصّي + تدرّج) |
| 2 | 2-Home | `1:6` | `home_screen.dart` + `shell.dart` |
| 3 | 3-Store | `1:10` | `store_screen.dart` |
| 4 | 4-Item-Sheet | `1:14` | `item_sheet.dart` |
| 5 | 5-Checkout | `1:18` | `checkout_screen.dart` |
| 6 | 6-Tracking | `1:22` | `tracking_screen.dart` |
| 7 | 7-Bookings-Sheet | `1:26` | `booking_sheet.dart` |
| 8 | 8-Marketplace | `1:30` | `marketplace_screen.dart` |
| 9 | 9-Profile | `1:34` | `profile_screen.dart` |
| 10 | 10-Home-Dark | `1:38` | `home_screen.dart` + tokens الداكنة |

كل إطار تحته شريحة **CTA-spec** (note chip باسم `<frame> / CTA-spec`) تذكر:
الفعل عند كل نقرة، الوجهة، حالات hover/pressed/disabled، الخط Noto Sans
Arabic، والألوان من الـ tokens.

## ملاحظات تنفيذ / ما تعذّر

- **البحث عن ملف سابق باسم "DYAR PRO V10"**: أداة `mcp__Figma__search-designs`
  غير موجودة في هذه البيئة (search-designs متاحة لـ Canva فقط)، ولا يوجد
  fileKey مسجّل في المستودع — لذلك أُنشئ الملف من جديد وفق التعليمات.
  إن وُجد ملف قديم بنفس الاسم في Drafts فيمكن دمجهما يدويًا.
- **مهارتا `/figma-use` و`/figma-generate-design`** غير مسجّلتين في بيئة
  الوكيل (Unknown skill) — تم الالتزام بتعليمات خادم Figma MCP مباشرة.
- **اللوغو** `docs/brand/logo-white.png` أبيض على شفاف؛ بدل رفعه كصورة
  استُخدم لوغو نصّي «ديار» داخل دائرة بيضاء على تدرّج برتقالي (Splash).
- **الأيقونات**: Lucide غير متاحة كخط داخل Figma API هنا — استُخدمت رموز
  إيموجي/نصية مطابقة للدلالة (🔍 🔔 📍 🛵 …) كما في مراجع ultra-home.
- إطار Home يُظهر بطاقة المتجر مقصوصة أسفل شريط التنقّل العائم عمدًا
  (حالة تمرير واقعية).

## التحقق البصري

لقطة كاملة للصفحة أُخذت وتم تدقيق إطاري Home وCheckout بدقة أعلى —
RTL سليم، التدرّجات والظلال مطابقة للكود، طرق الدفع VISA/CASH/BIT
والبقشيش والجدولة ظاهرة كما في `checkout_screen.dart`.
