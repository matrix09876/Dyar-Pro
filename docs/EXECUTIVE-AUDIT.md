# Dyar v10 — Executive Audit (CEO→CTO→CISO Single-Intelligence Review)
التاريخ: 2026-06-11 · النطاق: backend + dashboard + 3 تطبيقات + web + docs
المنهج: مراجعة كل شاشة/عقد/دالة فعليًا (لا افتراضات) — Impact/Priority/Complexity/Effort/ROI لكل بند.

# Executive Summary
منظومة سوبر-آب عاملة E2E على Firebase بمصدر حقيقة واحد: طلب الزبون يظهر
لحظيًا للتاجر واللوحة والسائق (مُثبت بلقطات حية). تجربة الطلب وصلت Wolt-grade
(خيارات صنف، بقشيش، كوبون، جدولة، ETA حي، مفضلة، Reorder). الأمان مبني
صح (تسعير خادمي، state-machine، قواعد مُختبرة 9/9). الفجوات الحرجة ليست
معمارية بل تفعيلية: مفاتيح الإنتاج، تحصيل البطاقات داخل التطبيق، App Check،
وقياس (Crashlytics/Analytics). الحكم: **أساس قابل للمنافسة فعليًا؛ الطريق
للإطلاق = 3 أسابيع منضبطة وفق Priority Matrix أدناه.**

# Critical Findings (Top 8)
| # | الاكتشاف | Impact | Priority | Fix |
|---|---|---|---|---|
| C1 | البطاقة/Bit لا يُحصَّلان داخل التطبيق (URL يُعاد ولا WebView يفتح) | إيراد | P0 | شاشة WebView لـ paymentUrl + polling حالة الدفع (M) |
| C2 | لا App Check ولا rate-limit على callable | أمان | P0 | تفعيل App Check + حد على createOrder (S) |
| C3 | Custom Claims لا تتحدث لحظيًا بعد ترقية دور (يلزم re-login) | تشغيل | P1 | force token refresh عبر FCM data msg أو revoke (S) |
| C4 | لا Crashlytics/Analytics — عمى تشغيلي عند الإطلاق | نمو | P0 | حزم Firebase + أحداث funnel (S) |
| C5 | بدون Offline persistence بالتطبيقات | UX | P1 | enablePersistence + كاش Hive للسلة (S) |
| C6 | bundle اللوحة 1.1MB دون code-splitting | أداء | P2 | dynamic import للصفحات + manualChunks (S) |
| C7 | redeemGiftCard يعدّل البطاقة من العميل (ثقة زائدة) | أمان | P1 | نقله إلى callable مع زيادة رصيد خادمية (S) |
| C8 | بحث Firestore أمامي فقط (لا typo-tolerance) | UX | P2 | فهرس Algolia/Typesense عند الحجم (M) |

# Business Analysis
نموذج الإيراد (مُنفَّذ): عمولة متدرجة 15/13.5/12% + خدمات 6% (تسوية شهرية
آلية) + رسوم خدمة + توصيل بالمناطق + Marketplace 5% (وكيل قيد البناء) +
بقشيش 100% للسائق (احتفاظ سائقين). فرص: اشتراك **Dyar+** (توصيل مجاني
شهري — يضرب Wolt+ محليًا)، ترويج ممول للمتاجر (موثق بالعقد)، B2B جملة
(صفحة 33 بالـFigma). تسرّب مُغلق: الكوبون والتسعير خادميان؛ المتبقي C7.
Unit economics: عمولة منطقة أساس ₪18 توصيل + 12-15% تكفي CAC عضوي محلي
(إحالة مدمجة DY-code).

# Product Analysis
- Personas مغطاة: زبون/تاجر/سائق/أدمن/Staff بمدن. ناقص: مقدم خدمة كـpersona
  مستقلة (وكيل الموجة 2) وB2B buyer.
- Journeys: order E2E ✅ · taxi/parcel ✅ (بلا خرائط مرئية 🔑) · bookings 🟡
  (وكيل يعمل الآن) · marketplace 🟡 (وكيل) · jobs+CV ◻️ (موجة 2).
- Duplicates: لا ازدواج؛ services موحّدة بdyar_core (SDK واحد للتطبيقات الثلاثة).

# UI Review (لقطات حية فُحصت شاشة-شاشة)
✅ يجيب كل شاشة رئيسية عن "ما هذا/لماذا/ماذا أفعل" خلال 3 ثوانٍ (هيرو متدرج،
CTA واحد مهيمن 54px، تسلسل بصري W900→muted). فجوات: حالات خطأ نصية فقط
(يلزم illustrations)، dark mode غير مدقق على كل شاشة (P2)، صور بدون
placeholder shimmer في item_sheet (S).

# UX Review
نقرات حتى الطلب: 4 (فتح متجر→صنف→أضف→Checkout) — أفضل من Talabat (6-7).
فجوة: لا "Basket bar" دائم عبر التبويبات (السلة تختفي خارج المتجر) — أضف
شريط سلة عائمًا فوق الـnav عند count>0 (S/P1). Onboarding غائب عمدًا (قرار
P0#6 بالهاندوف: سلايد واحدة) — ينفذ بالموجة 3.

# RTL/LTR Review
صلب: EdgeInsetsDirectional/PositionedDirectional بكل الشاشات، أرقام/عملة
LTR قسرًا (MoneyText)، هاتف/OTP dir=ltr. فحص عبري سريع ✅. ناقص: روسية
(جدول i18n يحتمل عمودًا رابعًا — Phase 2 كما بالهاندوف)، واختبار golden
لكل اتجاه (P2).

# Design System Review
Tokens موحدة (brand scale، radius 16/24، CTA 54px، Noto Sans Arabic+Inter)
بين Tailwind وdyar_ui — مصدران متطابقان يدويًا؛ خطر انجراف: ولّدهما من
ملف tokens واحد (style-dictionary) (P2/M). Motion: لا نظام حركة بعد —
أضف durations/curves قياسية بdyar_ui (S).

# SDK Review (dyar_core = الـSDK الرسمي)
نظيف: services مُحقنة (db اختياري للاختبار)، أخطاء HttpsError تمر للواجهة.
ناقص: retry/backoff موحّد للcallables، interceptor للlogging، وSemVer +
CHANGELOG للحزمة (P1/S). أمثلة تكامل: الديمو نفسه يقوم بالدور.

# Mobile Review
Web-build مُثبت؛ iOS/Android يحتاجان: deep links (dyar://order/{id})،
push routing من FCM data، حفظ لغة/ثيم بSharedPreferences (مزوّد موجود،
الربط S)، اختبار أذونات الموقع iOS (Info.plist مفاتيح موجودة من flutterfire
لاحقًا). Battery: بث الموقع كل تحديث — قيّده بـ distanceFilter 25m (S).

# Architecture Review
Firestore fan-out سليم؛ نقاط حمل مستقبلية: orders بالعرض الكامل للوحة —
أضف تجزئة بالتاريخ/المدينة عند >50k/شهر؛ autoAssign يقرأ كل السائقين
المتصلين — أضف geohash حقل وindex (M/P2). Functions v2 idempotent-friendly
(webhook يحدّث بمفاتيح خارجية).

# Security Review (OWASP/API)
قوي: لا أسرار بالكود، Secrets للدوال، state-machine، rules denial-by-default
مع اختبارات. ثغرات مرتبة: C2 (App Check) · C7 (giftcard) · storage rules
تسمح كتابة صور لأي مسجل بمسار stores/* (قيّد بالمالك) (P1/S) · webhook
EasyCard auth بمقارنة substring — بدّل بتوقيع HMAC حسب توثيقهم عند المفاتيح
(P0 مع التفعيل). جلسات: Firebase افتراضي كافٍ + revoke عند الحظر (S).

# Missing Features (متبقٍ بعد الموجات الجارية)
Group Order (L) · Dyar+ اشتراك (M) · دردشة داخل الطلب زبون↔سائق (M) ·
خرائط مرئية 🔑 · كاشير Kiosk ويب (M) · تقارير اللوحة الـ12 (M) ·
طابعة التاجر (M) · jobs+CV (وكيل موجة 2).

# Competitive Advantages (نقاط القتل)
تاكسي+طرود+حجوزات+سوق بتطبيق واحد · OTP تسليم (حماية ديار) · 3 لغات فورية
· عمولات أذكى من HAAT (متدرجة آلية) · AI (دعم/ETA/استيراد مينيو) ·
لوحة Staff بصلاحيات خادمية تتفوق على admin.dyar.app الحالية.

# Priority Matrix → Quick Wins (0-7d)
C1 WebView دفع · C2 AppCheck · C4 قياس · C7 giftcard · basket-bar ·
persistence · token-refresh — مجموعها ~5 أيام عمل.
# Short-Term (30d)
دمج فروع الوكلاء (bookings/marketplace/intel/teardown) · موجة 2 (عمولات
ذكية بالذروة، مقدمو خدمات+قواعد رؤية، jobs+CV، هوية مينيو) · دردشة الطلب ·
splitting اللوحة · golden tests RTL.
# Mid-Term (90d)
Dyar+ · Group Order · Kiosk web · تقارير 12 · geohash assignment ·
Algolia · الروسية.
# Long-Term (6-12m)
B2B جملة · Fleet white-label · ML توقع طلب/تسعير ذروة · توسع مدن بقواعد
اللوحة فقط (صفر كود).

# Developer Handoff Notes
كل Quick-Win معلّم بموضعه: C1→`payments/easycard.ts`+شاشة جديدة
`payment_webview.dart` · C7→نقل منطق `user_service.redeemGiftCard` إلى
callable `redeemGiftCard` · basket-bar→`shell.dart` Consumer(cartProvider)
· persistence→`firebase_boot.dart` سطران. الفروع الجارية: agent-bookings /
agent-marketplace / agent-competitor-teardown / agent-wolt-haat-intel —
ادمجها بهذا الترتيب ثم شغّل الفحص الكامل (analyze×3 + build×3 + tsc +
rules 9/9).

# Final CTO Verdict
**أطلق.** الأساس أصلب من حد السوق المحلي، والمخاطر المتبقية معروفة ومسعّرة
وقابلة للإغلاق في أسبوع للقائمة الحمراء. التميّز الحقيقي ليس الميزات بل
الدمج: خمس خدمات بسرعة 4 نقرات وهوية واحدة — لا Wolt ولا HAAT ولا Talabat
يقدمها معًا. التزم بالـMatrix ولا تضف نطاقًا قبل إغلاق P0.
