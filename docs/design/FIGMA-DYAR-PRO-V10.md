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


---

# موجة 2 — تطبيقا السائق والتاجر (Driver + Partner Wave)

> وثيقة تسليم وكيل التصميم — 2026-06-11 · نفس الملف `FtF2s8zxdAMS2nDJeUFYPS`

## الصفحة `11:2` — 02 · Dyar Driver — FINAL (6 × iPhone 390×844)

| # | الإطار | nodeId | المصدر (الكود المنفّذ) |
|---|---|---|---|
| 1 | 1-Login-OTP | `11:3` | `apps/driver/lib/screens/login_screen.dart` |
| 2 | 2-Register-KYC | `11:34` | `register_screen.dart` (شرائح مركبة + لوحة/رخصة/هوية + pending) |
| 3 | 3-Home-Available | `11:68` | `home_screen.dart` (متصل + بانر التعرفة + claimOrder) |
| 4 | 4-Active-Task | `11:104` | `active_task_screen.dart` (أرباحي + ملاحة + CTA المرحلة التالية) |
| 5 | 5-Earnings | `11:134` | `earnings_screen.dart` (اليوم/الأسبوع/الإجمالي) |
| 6 | 6-Settings | `11:166` | `profile_screen.dart` (لغات 3 / داكن / خروج) |

## الصفحة `12:2` — 03 · Dyar Partner — FINAL (6 × iPhone 390×844)

| # | الإطار | nodeId | المصدر (الكود المنفّذ) |
|---|---|---|---|
| 1 | 1-Login-Email | `12:3` | `apps/partner/lib/screens/login_screen.dart` |
| 2 | 2-Orders-Live | `12:24` | `orders_screen.dart` + `shell.dart` (نشط + قبول/رفض) |
| 3 | 3-Bookings | `12:69` | `bookings_screen.dart` (تأكيد/إجلاس/إكمال/لم يحضر) |
| 4 | 4-Menu | `12:118` | `menu_screen.dart` (سعر سريع + switch توفر) |
| 5 | 5-Hours | `12:164` | `hours_screen.dart` (صفوف أيام + TimePicker + حفظ) |
| 6 | 6-More | `12:236` | `more_screen.dart` (تقييم/رصيد متدرّج/عروض/لغة/خروج) |

كل إطار تحته شريحة **CTA-spec** توثّق: الفعل عند كل نقرة، الوجهة،
hover (تفتيح 6%) / pressed (scale 0.97 + تعتيم 8%) / disabled
(E5E7EB + 9CA3AF)، وتذكير أن الخادم يفرض تسلسل الحالات والأرباح.

## ملاحظات موجة 2
- إيموجي بدل Lucide (قيد بيئة Figma API) — كما الموجة الأولى.
- الوضع الليلي في «المزيد» (Partner) موثّق في CTA-spec دون صف مرئي.
- ساعات العمل RTL: الفتح يمينًا والإغلاق يسارًا — مطابق لرندر Flutter.


---

# الموجة الختامية — Dashboard + Web + Scorecard

## 04 · Dashboard — FINAL (صفحة 16:3) — 6 إطارات Desktop 1440×900
| الإطار | nodeId | المضمون |
|---|---|---|
| 1-Login | `16:5` | بطاقة على تدرّج + 3 لغات + «للإدارة فقط» |
| 2-Overview | `16:39` | سايدبار 20 بندًا + 4 KPI + رسم إيراد + جدول حي + معاينة داكنة مدمجة |
| 3-Orders | `17:2` | مفتاحا Dynamic fare/Assignment + 9 فلاتر + Drawer تعيين سائق |
| 4-City-Settings | `17:241` | ساعات/ذروة/شرائح مناطق/فئات الرؤية الـ11 |
| 5-Marketplace | `19:2` | تبويبات الحالات + بطاقات C2C + حقل العمولة |
| 6-Settings | `19:173` | النموذج العام + جدول قواعد العمولة الذكية |

## 05 · dyar.app Web — FINAL (صفحة 16:4)
- 1-Desktop `20:2` (1440×1900): هيدر لغات/داكن + هيرو + متاجر + CTA تاجر/سائق + شبكة 10 خدمات + فوتر.
- 2-Mobile `20:99` (390×1400): نفس المحتوى متكدسًا بأزرار ≥52px.

## 00 · Scorecard — Global Standards (صفحة 16:2) — `21:2`
12 معيارًا /10 ضد Wolt/HAAT/Talabat/TALABI بتعليل لكل صف، من وثائق
الاستخبارات الأربع + الكود الفعلي.

### المجاميع /120
| **Dyar V10** | Wolt | Talabat | HAAT | TALABI |
|---|---|---|---|---|
| **101** | 102 | 85 | 79 | 56 |

نتفوق الآن: RTL/لغات 10 · سرعة الطلب 9 (≤4 نقرات) · اللوحة 9 · الخندق 9
(سوبر-آب 7 خدمات + OTP + AI) · الهوية/CTA 9. خلف Wolt بنقطة لفجوات
تفعيلية فقط (Maps/App Check/تقارير التاجر/heat-map السائق) — التقدير بعد
المفاتيح ≈ **107/120** أي الصدارة.


---

## تحديث: اكتمال الشرائح والترابط (2026-06-11)

**fileKey:** `FtF2s8zxdAMS2nDJeUFYPS`

### إطارات جديدة من الكود
| الصفحة | الإطار | nodeId | مصدر الكود |
|---|---|---|---|
| 01 · User | 11-Services-Hub — شبكة 14 مهنة بتدرجات مميزة | `32:2` | `services_screen.dart` |
| 01 · User | 12-Jobs — وظائف + شيت تقديم CV | `32:60` | `jobs_screen.dart` |
| 02 · Driver | 7-Tasks-Hub — شرائح 🍔/📦/🚕 بعدادات + بانرات نشطة | `33:2` | `home_screen.dart` |
| 02 · Driver | 8-Active-Parcel — تسليم بـOTP كبير | `33:61` | `active_parcel_screen.dart` |
| 02 · Driver | 9-Active-Ride — بطاقة داكنة + تسلسل الحالة | `34:2` | `active_ride_screen.dart` |
| 02 · Driver | 10-Support-AI — Dyar Bot 🤖 + ردود سريعة | `34:45` | `support_screen.dart` |
| 02 · Driver | 11-AppLock — قفل بصمة/Face ID 🔒 | `34:79` | `dyar_core/security/app_lock.dart` |
| 04 · Dashboard | 7-Order-Timeline — drawer الخط الزمني الكامل | `35:2` | `Orders.tsx` |

### البروتوتايب — 65 Reaction (ON_CLICK → NAVIGATE، Dissolve 0.3s)
- **01 User: 19** — Splash→Home→Store→Item→Store→Checkout→Tracking،
  Home→Services-Hub/Marketplace/Jobs، Profile↔Home.
- **02 Driver: 27** — Login→KYC→Tasks-Hub→Active-Task/Parcel/Ride→
  Earnings، Profile→Support، AppLock→Tasks-Hub.
- **03 Partner: 16** — Login→Orders→Bookings/Menu/Hours/More + رجوع.
- **04 Dashboard: 3** — Orders⇄Order-Timeline.
- نقاط بداية Flow على الصفحات الأربع (🛒/🛵/🏪/🖥️)؛ الوصلات
  عبر-الصفحات بشرائح برتقالية: `36:9` `36:12` `36:15` `36:18`.

### تعديلات على إطارات قائمة
- `1:6` Home: تصفيف شرائح الفئات (إظهار «خدمات») + زرّا 🛍️ (`36:2`)
  و💼 (`36:4`) بالهيدر — يطابقان مداخل الكود الفعلية.
- `11:166` Settings (Driver): تايل «🤖 الدعم والمساعدة» (`36:6`).

---

## صفحة 07 · Ultra Merge — Home·Food·Stores (دمج DYAR ULTRA UI)
نُسخت كل إطارات الإنتاج المعتمدة («جاهز للكود ✓») من ملف Dyar Ultra UI
(`LI80pm1FvvDMVKiFrwh88i`) وأُعيد بناؤها بهوية PRO V10 مع إصلاحات
التدقيق: توحيد السوق على الجليل (+972، كرميئيل/البعنة بدل رام الله/+970)،
أهداف لمس ≥44px، ✓ على مقاطع التقدم بدل اللون وحده، أرقام/أسعار LTR.

| ID | الإطار | Node | مصدر ULTRA | وصلات النقر |
|---|---|---|---|---|
| UM1 | الرئيسية الموحدة | `79:5` | `1860:99` | الطعام→UM2 · المتاجر→UM9 · كرّر→UM6 · تتبع→UM8 |
| UM2 | الطعام — الرئيسية | `82:2` | `1842:2` | فئة/الكل→UM3 · مطعم→UM4 · سلة→UM6 |
| UM3 | قائمة المطاعم + فلاتر | `82:117` | `1844:303` | →UM2/UM4/UM6 |
| UM4 | صفحة المطعم | `84:2` | `1844:639` | →UM3 · 🎁→UM16 · صنف→UM5 · CTA→UM6 |
| UM5 | تفاصيل الصنف | `84:119` | `1845:770` | →UM4 · ضيف للسلة→UM6 |
| UM6 | السلة متعددة المتاجر | `86:2` | `1845:919` | →UM4 · كمّل للدفع→UM7 |
| UM7 | الدفع — 8 وسائل | `86:107` | `1847:1020` | →UM6 · أكّد→UM8 |
| UM8 | تتبع الطلب — خريطة | `88:2` | `1848:1154` | →UM1 |
| UM9 | المتاجر (MASTER M1) | `91:2` | `1933:7` | متجر→UM10 · رجّعها→UM6 · هدايا→UM13 |
| UM10 | المتجر (MASTER M2) | `91:163` | `1935:139` | →UM9 · منتج→UM11 · سلة→UM6 |
| UM11 | المنتج (MASTER M3) | `104:2` | `1936:213` | →UM10 · ضيف للسلة→UM6 |
| UM12 | ستوري بورد الشراء (M4) | `101:2` | `1937:268` | لوحة مطورين |
| UM13 | بطاقات هدايا ديار | `88:118` | `1860:336` | →UM9 · ابعت→UM7 |
| UM14 | خريطة التغطية + GPS-fail | `95:2` | `1860:415` | →UM1 · زائر→UM1 |
| UM15 | الإشعارات والحساب | `98:2` | `1860:494` | →UM1 · إشعار→UM8 |
| UM16 | إرسال الطلب كهدية | `98:98` | `2031:386` | →UM6 · حفظ→UM6 |

مسار الطعام كامل بالبروتوتايب: UM2→UM3→UM4→UM5→UM6→UM7→UM8.
مكررات أُسقطت عمدًا: `1860:178` و`1860:257` (تفوّقت عليهما نسخ MASTER)
وأربعة إطارات Code Alignment لها مكافئ (home/list/scheduling/payment).

## صفحة 08 · Ultra Merge — Auth·Account (`80:2`)
11 إطارًا من ULTRA ص34 بإصلاحات التدقيق (الجليل/+972، لمس ≥44px،
حالات بأيقونة+نص لا لونًا فقط، أرقام LTR-isolated، 🛡️ حماية ديار على OTP):

| ID | الإطار | Node | مصدر | وصلات |
|---|---|---|---|---|
| AM1 | البداية واختيار اللغة | `80:8` | `1975:5` | يلّا نبلّش/عندي حساب→AM2 |
| AM2 | الدخول بالهاتف (+ هدية ₪30) | `80:51` | `1975:65` | أرسل الرمز→AM3 |
| AM3 | رمز التحقق OTP | `81:2` | `1976:61` | تأكيد→AM4 · غيّر الرقم→AM2 |
| AM4 | الموقع وأول عنوان | `81:45` | `1976:118` | الرئيسية: chip عبر-صفحات |
| AM5 | طلباتي | `83:2` | `1977:125` | التفاصيل→AM6 |
| AM6 | تفاصيل طلب + إعادة | `83:81` | `1977:249` | الدعم→AM11 · قيّم→AM7 |
| AM7 | التقييمات والمراجعات | `85:2` | `1978:261` | FS6 ‏chip |
| AM8 | المفضلة | `85:94` | `1978:435` | — |
| AM9 | حسابي الكامل | `87:2` | `1979:533` | →AM5/AM8/AM10/AM11 · خروج→AM1 |
| AM10 | المحفظة والقسائم (₪20 جديد) | `87:123` | `1979:730` | — |
| AM11 | الدعم والمساعدة | `89:2` | `1983:706` | — |

## صفحة 09 · Ultra Merge — Flows·States (`80:3`)
**FS1–FS14 حالات ومسارات** (من ULTRA ص32): فشل الدفع `89:49` (بدّل
البطاقة→FS2)، وسائل الدفع `92:2`، استرداد `92:57`، شيت الإلغاء `93:2`،
محادثة المندوب `93:34`، تقييم+بقشيش `96:2`، محرر العنوان `96:87`،
لا نتائج `97:2`، نفد الصنف `97:71`، تأخر الطلب `100:2` (ألغِ مجانًا→FS3)،
إيصال ضريبي `100:67`، بوابة +18 `103:2`، حالات القائمة `103:22`،
حالات السلة `103:59`.

**BB1–BB7 ديار جملة B2B** (من ULTRA ص33، مطابقة لعقد الكود
`users.merchant` + `minQty`): الرئيسية `105:3` (RFQ→BB2، قفل
الأسعار 🔒→BB7)، طلب عرض سعر `105:108`، العروض `108:2` (اعتمد→BB4)،
سلة الجملة `108:65` (stepper يحترم الحد الأدنى)، رشّح متجرًا `109:2`،
انضم كموصّل `109:79`، توثيق التاجر `110:2`. ‏24 وصلة نقر.

### إطارات مكملة على صفحة 07 (UM17–UM20، من ULTRA ص35)
| ID | الإطار | Node | مصدر | ربط الكود |
|---|---|---|---|---|
| UM17 | عجلة الحظ (OFF عند الإطلاق) | `118:2` | `2003:35` | بوابة إعدادات من اللوحة |
| UM18 | حساسيات الطعام | `119:2` | `2003:83` | `users.allergies` + شارة ⚠ على الأصناف |
| UM19 | ادعُ واربح — المحفظة | `121:2` | `2003:99` | رمز إحالة DY… في `profile_screen.dart` |
| UM20 | خدمات وحجز — أغلفة | `122:2` | `2003:115` | `services_screen.dart` + `booking_sheet.dart` |

إصلاح QA: شرائح CTA-spec العشرون على صفحة 07 كانت 16 منها منهارة
الارتفاع (40px تقصّ البنود) — أُصلحت جميعها بـ`primaryAxisSizingMode=AUTO`
وتحقّق أن 0 منها مقصوص.

## شرائح الأقسام المضافة (من مكتبة FIGMA-PROMPTS)
| الصفحة | الإطار | Node | الكود |
|---|---|---|---|
| 01 User | 13-Login-OTP | `56:2` | `login_screen.dart` |
| 01 User | 14-Addresses | `56:46` | `addresses_screen.dart` |
| 01 User | 15-Notifications | `57:2` | `notifications_screen.dart` |
| 01 User | 16-My-Bookings | `57:64` | `bookings_screen.dart` |
| 01 User | 17-Taxi-Request (+SOS) | `59:2` | `taxi_screen.dart` |
| 01 User | 18-Send-Parcel (OTP) | `59:59` | `parcel_screen.dart` |
| 01 User | 19-My-Orders | `60:2` | `orders_screen.dart` |
| 02 Driver | 10-History | `61:2` | `history_screen.dart` |
| 02 Driver | 11-Profile-Docs | `61:71` | `profile_screen.dart` |
| 03 Partner | 7-Promotions | `64:2` | `promotions_screen.dart` |
| 03 Partner | 8-Balance | `64:59` | `balance_screen.dart` |
| 04 Dashboard | A7-Stores → A16-Jobs | `63:2` `63:173` `63:344` `65:2` `65:151` `65:300` `68:2` `68:144` `70:2` `70:156` | `Stores/Drivers/Users/Rides/Parcels/Bookings/Marketing/Finance/Banners/Jobs.tsx` |
