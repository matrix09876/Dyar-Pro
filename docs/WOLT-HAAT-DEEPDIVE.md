# Wolt × HAAT — تشريح معمّق (Deep-Dive) لصالح Dyar v10

> وثيقة استخبارات منافسين مبنية على بحث إنترنت (مواقع رسمية، صفحات
> App Store/Google Play، صحافة تقنية، مراجعات مستخدمين) بتاريخ
> 2026-06-11. تُكمِّل `docs/COMPETITIVE-MATRIX.md` ولا تستبدلها.
> كل قسم ينتهي بقائمة Sources. حالة Dyar مأخوذة من
> `docs/FEATURES.md` + `docs/DATA-MODEL.md` + شاشات `apps/*/lib/screens`.

---

## الجزء 1 — جرد الميزات لكل تطبيق

### 1.1 Wolt — تطبيق المستخدم (Wolt: Food delivery & more)

| الميزة | التفاصيل المؤكدة |
|---|---|
| **Group Order بدفع منفصل** | إسرائيل أول دولة بالعالم تُطلق فيها: المنشئ يشارك رابط/QR، كل مشارك يختار من جهازه **ويدفع حصته فقط**، مزامنة لحظية لأي تغيير، وكل مشارك يتتبع الطلب باستقلال. ~8% من طلبات Wolt جماعية. جُرّبت أولًا على مستخدمي Wolt Benefits (مئات الشركات). |
| **اشتراك Wolt+** | 49 ₪/شهر: رسوم توصيل 0 + عروض حصرية للأعضاء. شروط: مسافة جوية حتى 4 كم، حد أدنى 60 ₪ للمطاعم و140 ₪ للسوبرماركت/الصيدليات. يُباع أيضًا بخصم عبر الشركات (Benefits). |
| **تتبع حي دقيق** | خط زمني بالحالة + موقع السائق الحي + ETA؛ التقييم بعد التسليم يقيّم المتجر وتجربة التوصيل (نظام "Smiley" التاريخي تحوّل لتقييم تجربة شامل). ملاحظة مهمة: إن وصّل المتجر بسائقيه الخاصين **لا يوجد تتبع** داخل التطبيق — نقطة ضعف. |
| **جدولة الطلبات (Preorder)** | اختيار وقت توصيل لاحق للمطاعم والمتاجر. |
| **Wolt Market** | دكاكين مظلمة (dark stores) تشغّلها Wolt: ~3,000 منتج، وعد توصيل ≤30 دقيقة، خيار استلام ذاتي، تتعامل مع المورّدين مباشرة. تحت تدقيق تنظيمي في إسرائيل (رفض إعفاء — احتمال بيع قسري). |
| **Wolt Package** | إرسال أغراض من عنوان لعنوان (طرود داخل المدينة). |
| **أدوات سعر** | Wolt Value Plan (خصومات أسبوعية للجميع)، Payless Monday (أكواد خصم لـ10,000 زبون شهريًا)، **فلتر مقارنة أسعار** للمنتجات بين المتاجر، رسوم تشغيل ديناميكية (~4 ₪ وسطيًا). |
| **Wolt Benefits / for Work** | ميزانيات وجبات وبقالة للموظفين: فاتورة شهرية واحدة، بطاقة **Wolt One** بـTap-to-Pay في +10,000 نقطة بيع، سياسات صرف حسب الفريق/الموقع/اليوم/الساعة، قسائم فعاليات وهدايا موظفين. |

**نقاط ضعف موثقة (مراجعات Trustpilot/JustUseApp):** دعم بطيء ورافض
للتعويض، استرداد بـ"رصيد Wolt" بدل المال (~10% من قيمة طلب غير صالح
للأكل)، خصم كامل عند نقص أصناف، إظهار التأخير **بعد** إتمام الطلب لا
قبله، طعام بارد/متأخر.

**Sources:**
- https://www.jpost.com/consumerism/article-897912 (Group Order بدفع منفصل)
- https://www.jpost.com/business-and-innovation/article-838564 و https://www.jpost.com/consumerism/article-838896 (Wolt+ والميزات الجديدة)
- https://explore.wolt.com/wolt-plus و https://explore.wolt.com/en/isr/woltplus-terms
- https://explore.wolt.com/en/isr/wolt-market و https://www.timesofisrael.com/wolt-launches-grocery-delivery-from-new-market-store-in-tel-aviv/ و https://www.jpost.com/business-and-innovation/article-885394
- https://explore.wolt.com/en/isr/wolt-for-work/employee-benefits
- https://press.wolt.com/en-WW/237306-algorithmic-transparency-consumers/
- https://www.trustpilot.com/review/wolt.fi و https://justuseapp.com/en/app/943905271/wolt-food-delivery/reviews (الشكاوى)

### 1.2 Wolt Merchant (تطبيق + بوابة التاجر)

| الميزة | التفاصيل المؤكدة |
|---|---|
| **Merchant App** | استقبال الطلبات وإتمامها، تتبع المبيعات الحية، تعديل القائمة/المخزون لحظيًا. |
| **Listing Manager** | محرر قوائم ذاتي (أصناف، صور، أسعار، توفر) — كان اسمه Menu editor. |
| **حملات Self-Service** | من بوابة التاجر مباشرة: توصيل 0€، خصومات، **Wolt Ads** (ظهور مدفوع)، عروض كومبو، اشترِ 2 واحصل على 3. |
| **تقارير ثلاثية** | Performance (مبيعات، طلبات، متوسط السلة وعدد أصنافها، حسب نوع التسليم) · Operations (نسبة الرفض، الالتزام بالوقت، زمن التحضير) · Customer base (زبائن جدد مقابل عائدين). |
| **تكاملات POS** | API رسمي + وسطاء (Deliverect, Mergeport, ChoiceQR) لإدارة القوائم والطلبات من نظام المطعم نفسه. |
| **Wolt Drive API** | التاجر يبيع من موقعه/تطبيقه وWolt توفر الميل الأخير white-label: إرسال SMS تتبع للزبون، إلغاء مبرمج، اختيار المناطق/الطلبات المؤهلة. |

**Sources:**
- https://merchant.wolt.com/ و https://explore.wolt.com/en/isr/merchant/business/restaurants
- https://explore.wolt.com/en/deu/merchant/solution/analytics
- https://press.wolt.com/en-WW/237307-algorithmic-transparency-merchants/
- https://developer.wolt.com/docs/wolt-drive و https://developer.wolt.com/docs/api/wolt-drive
- https://www.deliverect.com/en/blog/online-food-delivery/wolt-101-essential-guide-for-restaurants

### 1.3 Wolt Courier Partner (تطبيق السائق)

| الميزة | التفاصيل المؤكدة |
|---|---|
| **City Heat Maps** (2025) | خريطة حرارية لحظية لبؤر الطلب — أين ومتى الطلب أعلى. |
| **توقع الطلب** | رسم "Expected demand today" + "أرباحك هذا الأسبوع" داخل التطبيق. |
| **Task Batching (Bundles)** | حِزم مهام: عدة طلبات من نفس المطعم أو مطاعم متقاربة لتسليمات بنفس المنطقة — تزيد المهام/الساعة. |
| **Early Payouts** | سحب فوري لـ50–70% من الأرباح فور إتمام التسليم — تصل للبنك خلال دقائق. |
| **أرباح شفافة** | عرض لحظي للأرباح والبقشيش (البقشيش 100% للسائق)، ساعات مرنة بلا مناوبات إلزامية. |
| **أدوات مساعدة** | اتجاهات مقترحة، hotspots، دعم سائقين مخصص، تقرير شفافية خوارزمية معلن (كيفية توزيع المهام). |
| التقييم | 4.8★ على App Store الأمريكي، +32 لغة. |

**شكاوى السائقين الموثقة:** أجر منخفض للتسليمة في بعض الأسواق، إشعارات
إلغاء متأخرة، طلبات ماركت ثقيلة لراكبي الدراجات، وفي أسواق تُدار عبر
"شركاء أسطول" قد لا يصل البقشيش كاملًا.

**Sources:**
- https://apps.apple.com/us/app/wolt-courier-partner/id1477299281
- https://press.wolt.com/en-WW/245863-early-payouts-a-new-level-of-financial-flexibility-for-wolt-courier-partners/
- https://press.wolt.com/en-WW/237304-algorithmic-transparency-courier-partners/ و https://press.wolt.com/en-WW/257465-10-questions-about-wolt-couriers/
- https://trademagazin.hu/en/uj-funkciokkal-fejleszti-a-kiszallitast-a-futarpartnerei-szamara-a-wolt/ (Heat Maps)
- https://www.partnersbaltics.com/the-wolt-courier-partner-app-and-its-algorithm

### 1.4 HAAT — تطبيق المستخدم (com.haat.client)

| الميزة | التفاصيل المؤكدة |
|---|---|
| **توصيل بلا عنوان شارع** | الطلب يُرسل إلى **موقع GPS للهاتف** — مصمم للبلدات العربية بلا أرقام بيوت. خوارزمية ML تتعلم الخرائط من مسارات السائقين الفعلية حيث يفشل GPS القياسي. هذا خندقهم التقني الأساسي. |
| **الدفع** | نقدًا (80% من الإيراد!) + بطاقة + **Cibus** + Apple/Google Pay + بطاقات هدايا. |
| **3 لغات** | عربية/عبرية/إنجليزية (+فرنسية على iOS — للمغرب). |
| **جدولة الطلبات** | طلب لوقت لاحق مدعوم. |
| **سلع رقمية** | بطاقات هدايا، شحن رصيد هاتف، أرصدة ألعاب (Fortnite credits) — تستثمر جمهور الدفع النقدي. |
| **إحالة وهدايا** | برنامج "ادعُ واربح" مع تتبع الدعوات، وإرسال بطاقات هدايا للأصدقاء (تحديث 20.5.0). |
| **التغطية** | ~40 مدينة في 3 دول (إسرائيل، الضفة/القدس الشرقية، المغرب)، +1,000 سائق. تمويل 20M$ لمنافسة Wolt. |
| **رسوم** | تسوّق بلا service fee (نقطة بيع تسويقية لديهم) وتوصيل أرخص من Wolt. |
| الأرقام | Android: 4.7★ (~10K تقييم، +500K تنزيل) · iOS: 4.4★ (24K تقييم، #3 طعام وشراب في إسرائيل). |

**نقاط ضعف موثقة (مراجعات):** **لا قناة تواصل مع السائق** (لا دردشة ولا
اتصال) عندما يضيع عن العنوان، دعم WhatsApp لا يردّ، لا تعويض عن أخطاء
(إضافات خاطئة/كميات صغيرة) فالمطاعم لا تهتم بجودة طلبات HAAT، تأخير
وطعام بارد (طلب ساعتين لمسافة ربع ساعة)، متجر يظهر متاحًا ثم يرفض
التوصيل عند الدفع أو يتصل "لا يوجد طعام".

**Sources:**
- https://haat.delivery/ و https://apps.apple.com/il/app/haat/id1496579620
- https://play.google.com/store/apps/details?id=com.haat.client&hl=en_US
- https://www.bloomberg.com/news/articles/2025-10-21/israeli-arab-startup-haat-solves-big-food-delivery-problems
- https://www.israelhayom.com/2022/01/24/new-app-haat-brings-food-delivery-to-underserved-arab-israeli-communities/
- https://www.calcalistech.com/ctechnews/article/sjqk79m2q (التوسع للمناطق الفلسطينية)
- https://www.asiabusinessoutlook.com/news/israelbased-haat-secures-20m-to-challenge-wolt-in-israel-market-nwid-11674.html
- https://www.ynetnews.com/business/article/rkhxwyx25

### 1.5 HAAT Partner (com.haat.restaurant) — تطبيق التاجر

| الميزة | التفاصيل المؤكدة |
|---|---|
| استقبال الطلبات | طلبات مفصلة لحظيًا + تحديث حالة الطلب (قبول → تحضير → جاهز). |
| مزامنة مخزون | للماركتات: real-time inventory sync (معلن على موقعهم). |
| خدمات تسويق | عبر فريق HAAT (وليس self-service): حملات سوشيال، sponsored listings. |
| POS | حلول نقطة بيع ضمن عرضهم للتجار في مناطق بنية تحتية ضعيفة. |
| الأرقام | 4.4★ (85 تقييمًا فقط)، +10K تنزيل — أداة تشغيلية بسيطة، **بلا تقارير ذاتية أو حملات self-service** (لا دليل عليها في أي مصدر). |

> ملاحظة تحقق: لا وجود لتطبيق باسم **"HaatBis"** — الأسماء الرسمية:
> `HAAT Delivery` (زبون)، `HAAT Partner` (تاجر)، `HAAT Driver` (سائق)،
> + بوابة ويب للأعمال. أي ذكر لـ"HaatBis" غير مؤكد ويُعتبر إشاعة.

**Sources:**
- https://play.google.com/store/apps/details?id=com.haat.restaurant
- https://haat.delivery/ (خدمات التجار والتسويق وDaaS)
- https://www.appbrain.com/app/haat-partner/com.haat.restaurant

### 1.6 HAAT Driver (com.haat.haatdriver) — تطبيق السائق

| الميزة | التفاصيل المؤكدة |
|---|---|
| إدارة التسليم | إشعارات بالطلبات المنتظرة + تعليمات end-to-end للمهمة. |
| ملاحة خاصة | يستفيد من خرائط HAAT المتعلَّمة (مواقع بيوت بلا عناوين) — أهم ما يميزه. |
| توظيف مرن | "Become a Courier" بجدولة مرنة + بوابة وظائف careers.haat.delivery. |
| **DaaS** | شبكة السائقين تُؤجَّر كخدمة (Delivery-as-a-Service) لأعمال خارجية. |
| الأرقام | 4.2★ (~100 تقييم)، +10K تنزيل — **بلا خرائط حرارية، بلا early payout، بلا batching معلن**. أبسط بكثير من Wolt Courier. |

**Sources:**
- https://play.google.com/store/apps/details?id=com.haat.haatdriver&hl=en_US
- https://haat.delivery/ (DaaS + التوظيف)
- https://haat-driver.en.uptodown.com/android

---

## الجزء 2 — جدول المقارنة الموحّد

✅ موجود · 🟡 جزئي · ❌ غير موجود

| الميزة | Wolt | HAAT | **Dyar الآن** | الفجوة |
|---|---|---|---|---|
| طلب جماعي بدفع منفصل | ✅ (إسرائيل أولًا) | ❌ | ❌ | **G1** |
| اشتراك توصيل (+Plus) | ✅ 49₪ | ❌ | ❌ | **G2** |
| تتبع حي + ETA | ✅ | ✅ | ✅ | — |
| إظهار التأخر قبل تأكيد الطلب | ❌ (شكوى) | ❌ | ❌ | **G3** |
| جدولة التوصيل | ✅ | ✅ | ✅ خلفية · 🟡 واجهة | **G4** |
| توصيل لنقطة GPS بلا عنوان | ❌ | ✅ (خندقهم) | 🟡 (lat/lng بالعنوان) | **G5** |
| دفع Cibus/قسائم موظفين | ✅ (Benefits) | ✅ Cibus | ❌ | **G6** |
| سلع رقمية (شحن رصيد/ألعاب) | ❌ | ✅ | ❌ | **G7** |
| فلتر مقارنة أسعار منتجات | ✅ | ❌ | ❌ | **G8** |
| دكان مظلم (Market خاص) | ✅ | ❌ | 🟡 (warehouse في cities.marketplace) | **G9** |
| حملات تاجر self-service | ✅ | ❌ | 🟡 (promotions_screen هيكل) | **G10** |
| تقارير تاجر (أداء/تشغيل/زبائن) | ✅ | ❌ | 🟡 (لوحة الأدمن فقط) | **G11** |
| Ads/ظهور مدفوع للتاجر | ✅ Wolt Ads | 🟡 عبر فريقهم | ❌ | **G12** |
| تكامل POS / API قوائم | ✅ | 🟡 | 🟡 (webhooks.menuCatalogUrl + استيراد AI) | **G13** |
| خريطة حرارية للطلب (سائق) | ✅ 2025 | ❌ | ❌ | **G14** |
| توقع الطلب اليومي (سائق) | ✅ | ❌ | ❌ | **G14** |
| حِزم مهام (batching) | ✅ | ❌ | ❌ | **G15** |
| سحب أرباح فوري (early payout) | ✅ 50–70% | ❌ | ❌ | **G16** |
| دردشة/اتصال زبون↔سائق | ✅ | ❌ (أكبر شكوى) | ✅ (`chats`) | — تفوقنا |
| بقشيش 100% للسائق | ✅ (مع استثناءات) | ❌ | ✅ | — تفوقنا |
| توصيل B2B كخدمة (Drive/DaaS) | ✅ API | ✅ DaaS | ❌ | **G17** |
| حساب شركات/ميزانيات موظفين | ✅ Benefits | ❌ | ❌ | **G18** |
| تقييم منفصل للمتجر والتوصيل | ✅ | 🟡 | 🟡 (rating واحد بالطلب) | **G19** |
| تاكسي + طرود + حجوزات بنفس التطبيق | ❌ | ❌ | ✅ | — تفوقنا |
| 3 لغات RTL فوري | ❌ | ✅ | ✅ | — |
| ألعاب/روليت/تبرعات | ❌ | ❌ | ✅ نموذج | — تفوقنا |
| دعم AI لحظي | ❌ | ❌ | ✅ | — تفوقنا |

---

## الجزء 3 — مواصفات تنفيذ الفجوات (بنمط Dyar)

كل مواصفة: Firestore → Cloud Function → Flutter → لوحة. الحجم: S ≤ يوم · M ≤ أسبوع · L > أسبوع.

### G1 — الطلب الجماعي بدفع منفصل (L) — أعلى أثر تسويقي
- **Firestore**: `groupCarts/{cartId}`: `{ hostUid, storeId, code, joinLink, status:'open'|'locked'|'ordered', deadline?, members: [{uid, name, items[], subtotal, paymentStatus}] , createdAt }`.
- **Functions**: `createGroupCart`, `joinGroupCart` (عبر code/QR)، `lockAndSubmitGroupCart` — تجمّع الأصناف في `orders/{id}` واحد مع `payment.split: [{uid, amount, intentId}]`، وتحصيل كل عضو على حدة (EasycardNG/نقدًا مع تحديد من يدفع نقدًا).
- **Flutter (user)**: `group_cart_screen.dart` + بانر انضمام في `store_screen.dart` + مشاركة رابط/QR.
- **اللوحة**: عمود "جماعي" في صفحة الطلبات + تفاصيل المنقسمين.

### G2 — اشتراك Dyar+ (L) — محرّك الاحتفاظ الأول
- **Firestore**: `subscriptions/{uid}`: `{ plan:'monthly'|'yearly', price, status:'active'|'cancelled'|'past_due', startedAt, renewsAt, savingsTotal }` + `config/app.dyarPlus: { price, minOrder, maxKm, partnerCommissionRelief }`.
- **Functions**: `subscribeDyarPlus` (تحصيل دوري)، وتعديل `pricing` في دالة إنشاء الطلب: `deliveryFee=0` للمشترك ضمن الشروط. **تمايزنا: جزء من رسوم الاشتراك يُخصم من عمولة المطعم** ليحبّنا التجار (عكس Wolt).
- **Flutter**: `dyar_plus_screen.dart` (مزايا + عدّاد "وفّرت X₪").
- **اللوحة**: صفحة Dyar+ (مشتركون، إيراد شهري، churn).

### G3 — صدق الـ ETA قبل التأكيد (S) — ضربة دعائية ضد Wolt
- **Functions**: في `checkout` احسب `etaRange` من حمل المطبخ (`prepTimeMins` الحي) + توفر السائقين بالمدينة (`cities.saturation`) وأعِده **قبل** الدفع. إن كانت المدينة مشبعة أظهر "متأخر اليوم +X دقيقة".
- **Flutter**: شريط ETA في `checkout_screen.dart` قبل زر الدفع.
- **Firestore**: لا تغيير (قراءة فقط). **اللوحة**: مؤشر saturation موجود.

### G4 — واجهة الجدولة (S)
- موجودة خلفيًا (`scheduledFor`). أضِف bottom-sheet منتقي وقت في `checkout_screen.dart` + شارة "مجدول" في `orders_screen.dart` (تاجر/لوحة).

### G5 — "وصّل لموقعي" + خرائط متعلَّمة، نسخة HAAT المحسّنة (M)
- **Firestore**: في `users.addresses[]` أضِف `type:'gps_pin'` و`landmark`؛ مجموعة جديدة `learnedLocations/{geohash}`: `{ lat, lng, label, confirmedByDrivers: n, photos[] }`.
- **Functions**: `confirmDeliveryPoint` — عند كل تسليم ناجح يُرسّخ السائق النقطة الفعلية، فتُقترح تلقائيًا للطلب التالي بنفس المنطقة (نبني خندق HAAT لأنفسنا في الجليل).
- **Flutter (user)**: زر "وصّل إلى موقعي الآن" في `addresses_screen.dart`؛ (driver) عرض النقطة المتعلَّمة في `active_task_screen.dart`.
- **اللوحة**: طبقة learnedLocations على خريطة المدينة.

### G6 — Cibus/قسائم (M)
- `payment.method` يضاف له `'cibus'`؛ Function `chargeCibus` عبر مزود القسائم؛ تبويب وسيلة دفع في `checkout_screen.dart`؛ تقرير تسوية Cibus باللوحة. (سوق الموظفين العرب في المختلطة كبير ومهمَل).

### G7 — سلع رقمية (M)
- **Firestore**: `digitalGoods/{skuId}`: `{ type:'topup'|'gametcard'|'giftcard', provider, denominations[], cityIds[], active }` + أوامرها في `orders.type:'digital'`.
- **Functions**: `purchaseDigitalGood` (تكامل مزوّد + تسليم الكود بإشعار/SMS). **Flutter**: قسم "شحن وبطاقات" في `home_screen.dart`. **اللوحة**: صفحة مخزون رقمي.

### G8 — مقارنة الأسعار (M)
- **Functions**: فهرس بحث منتجات عبر المتاجر (`searchKeywords` موجودة) يعيد نفس المنتج مرتبًا بالسعر+رسوم التوصيل الفعلية. **Flutter**: تبويب "قارن" في نتائج البحث. لا تغيير بالنموذج.

### G10 — حملات التاجر self-service (M) — فجوة HAAT الأوضح
- **Firestore**: `stores/{id}/campaigns/{campaignId}`: `{ type:'free_delivery'|'pct_off'|'combo'|'bxgy'|'boost', budget, startsAt, endsAt, status:'pending_approval'|'active'|'ended', stats:{views, orders, spend} }`.
- **Functions**: `submitCampaign` (موافقة أدمن) + تطبيقها في تسعير الطلب + عدّادات.
- **Flutter (partner)**: توسيع `promotions_screen.dart` بمعالج إنشاء حملة.
- **اللوحة**: طابور موافقات + أداء الحملات.

### G11 — تقارير التاجر الثلاثية (M)
- **Functions**: مجدولة يومية تكتب `stores/{id}/reports/{period}`: `{ sales, orders, avgBasket, rejectedPct, prepTimeAvg, punctuality, newCustomers, returningCustomers }` (تجميع من `orders`).
- **Flutter (partner)**: `reports_screen.dart` جديدة (3 تبويبات كـWolt). **اللوحة**: نفس البيانات بمقارنة بين المتاجر.

### G12 — Dyar Ads (L، بعد كتلة حرجة من المتاجر)
- `campaigns.type:'boost'` يرفع الترتيب في الفرز مع شارة "مُموَّل" + فوترة بالنقرة في `transactions.type:'ads'`.

### G14 — خريطة حرارة + توقع طلب للسائق (M) — يقفز فوق HAAT مباشرة
- **Functions**: مجدولة كل 10 دقائق تكتب `cities/{id}/demand/current`: `{ cells: [{geohash, level:0..3}], expectedCurve: [24 قيمة] }` من `orders` النشطة وأنماط الأسبوع الماضي.
- **Flutter (driver)**: طبقة حرارة في خريطة `home_screen.dart` + رسم "الطلب المتوقع اليوم". **اللوحة**: نفس الخريطة موجودة (Orders map).

### G15 — حِزم المهام (L)
- **Functions**: توسيع دالة الإسناد: إن وُجد طلبان `ready` من نفس المتجر/متجرين متقاربين (≤700م) ووجهتان ≤1كم تُنشأ `taskBundles/{id}`: `{ orderIds[], driverUid, sequence[], bonusPct }` بأجر إضافي معلن.
- **Flutter (driver)**: `active_task_screen.dart` يعرض محطات مرقمة. **اللوحة**: شارة "حزمة" بالطلبات.

### G16 — سحب فوري للأرباح (M) — أقوى أداة توظيف سائقين بالجليل
- **Firestore**: `payoutRequests/{id}`: `{ driverUid, amount, fee, status:'instant'|'standard', requestedAt, settledAt }`.
- **Functions**: `requestInstantPayout` — حتى 80% من رصيد اليوم (نتفوق على 50–70% لدى Wolt)، تحويل عبر بوابة الدفع، خصم من `drivers.earnings`.
- **Flutter (driver)**: زر "اسحب الآن" في `earnings_screen.dart`. **اللوحة**: طابور التحويلات بالمالية.

### G17 — Dyar Drive (DaaS API) (L، مرحلة لاحقة)
- **Functions**: HTTPS endpoints بـAPI keys لكل عميل B2B: `createDelivery`, `cancelDelivery`, `trackDelivery` + SMS تتبع للمستلم؛ تُنشئ `orders.type:'daas'` وتدخل نفس مسار الإسناد. **اللوحة**: صفحة عملاء API ومفاتيحهم.

### G18 — Dyar Business (حسابات شركات) (L، لاحقًا)
- `organizations/{orgId}`: `{ name, adminUids[], budgetRules[{team, dailyCap, days, hours}], invoiceEmail }` + `payment.method:'org_budget'`. فاتورة شهرية موحدة. سوق الشركات العربية والسلطات المحلية غير مخدوم إطلاقًا.

### G19 — تقييم ثنائي (S)
- `orders.rating` يصبح `{ store: {stars, comment}, delivery: {stars, comment} }` + تحديث `reviews` و`drivers.rating` بشكل منفصل. شاشة التقييم بعد التسليم بخطوتين سريعتين (إيموجي كـSmiley).

---

## الجزء 4 — "قوة عظمى": 10 ميزات نتفوق بها عليهما معًا

مبنية مباشرة على شكاوى المستخدمين الموثقة أعلاه:

1. **طلب جماعي أذكى من Wolt**: دفع منفصل + موعد إغلاق تلقائي + تذكير من لم يُكمل + خيار "المضيف يدفع الباقي" + تقسيم رسوم التوصيل بالتساوي. (Wolt تدعم الدفع المنفصل فقط؛ HAAT لا شيء.)
2. **Dyar+ صديق المطاعم**: اشتراك أرخص من 49₪ وجزء منه يخفّض عمولة المطعم — التجار يروّجون له بأنفسهم بدل أن يكرهوه.
3. **تعويض تلقائي فوري (Refund SLA)**: أكبر شكوى ضد الاثنين هي الدعم والاسترداد. دعم AI الموجود لدينا + قاعدة: صنف ناقص = استرداد للمحفظة خلال 60 ثانية بلا نقاش، مع سقف احتيال لكل مستخدم. لا أحد بالسوق يقدّمها.
4. **اتصال/دردشة مع السائق دائمًا** (`chats` جاهزة): أكبر شكوى ضد HAAT تحديدًا — نعلن عنها كميزة: "سائقك على بعد رسالة".
5. **ETA صادق قبل الدفع**: Wolt تُظهر التأخير بعد الطلب — نُظهره قبله مع خيار "أخّر طلبي بخصم".
6. **حوافز سائقين لحظية**: surge bonus حي على الخريطة الحرارية ("وصّل من هذه المنطقة الآن +7₪") + سحب فوري 80% — يجفف سائقي HAAT في الجليل ويستقطب سائقي Wolt الساخطين على الأجور.
7. **خرائط متعلَّمة + OTP + صورة إثبات**: نأخذ خندق HAAT (توصيل بلا عناوين) ونضيف فوقه أمان تسليم لا يملكه أحد.
8. **عمولة متدرجة شفافة ومعلنة** (15%→12% حسب الحجم، 6% للخدمات — موجودة في نموذجنا): سلاح اكتساب التجار ضد عمولات Wolt المرتفعة وغموض HAAT.
9. **سوبر آب حقيقي**: طعام + بقالة + صيدليات + تاكسي + طرود بOTP + حجز طاولات + مواعيد خدمات + سلع رقمية — لا Wolt ولا HAAT يجمعها؛ تكلفة اكتساب الزبون تتوزع على 7 خدمات.
10. **بقشيش 100% مُثبَت بإيصال**: شاشة للزبون تُظهر "وصل البقشيش للسائق ✓" — يحوّل فضيحة حجب البقشيش لدى منافسي Wolt إلى ميزة ثقة لنا.

---

## الجزء 5 — خارطة التنفيذ (الأثر ÷ الجهد)

| موجة | البنود | الحجم | لماذا أولًا |
|---|---|---|---|
| **الموجة 1 — أسبوعان** | G3 (ETA صادق) · G4 (واجهة جدولة) · G19 (تقييم ثنائي) · قوة 4 و10 (إبراز الدردشة + إيصال البقشيش) | S+S+S | مكاسب ثقة فورية ضد شكاوى المنافسين، بلا تغييرات نموذج كبيرة |
| **الموجة 2 — شهر** | G5 (GPS متعلَّم) · G16 (سحب فوري) · G14 (خريطة حرارة) · قوة 3 (Refund SLA) | M×4 | تأمين العرض (سائقون) والطلب (ثقة) في الجليل قبل أي توسع |
| **الموجة 3 — شهر–شهرين** | G10 (حملات التاجر) · G11 (تقارير التاجر) · G6 (Cibus) · G7 (سلع رقمية) | M×4 | اكتساب التجار بأدوات لا يملكها HAAT إطلاقًا + إيراد هامشي رقمي |
| **الموجة 4 — ربع** | G1 (طلب جماعي) · G2 (Dyar+) · G15 (حِزم المهام) | L×3 | محركات النمو والاحتفاظ الكبرى — تحتاج قاعدة مستخدمين نشطة |
| **الموجة 5 — بعد الإطلاق** | G17 (Dyar Drive DaaS) · G18 (Dyar Business) · G12 (Dyar Ads) · G9 (دكان مظلم) | L×4 | خطوط إيراد B2B تتطلب كثافة تشغيلية قائمة |

> قاعدة التحديث: أي بند يُنفَّذ → حدّث `docs/DATA-MODEL.md` + الأنواع +
> `backend/firestore.rules` معًا (القاعدة الإلزامية 5 في CLAUDE.md)،
> وحدّث صف الميزة في `docs/COMPETITIVE-MATRIX.md`.
