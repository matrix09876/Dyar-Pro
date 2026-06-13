# Dyar — نموذج البيانات (Firestore Data Model)

> العقد المركزي بين لوحة التحكم والتطبيقات الأربعة. أي تغيير هنا يجب أن
> ينعكس في `backend/firestore.rules`، `dashboard/src/types/`، وحزمة
> `dyar_core`. الأنواع المرجعية في `backend/functions/src/types.ts`.

كل المبالغ بأصغر وحدة عملة (أغورة/سنت) كأعداد صحيحة لتجنّب أخطاء العشرية.
كل الطوابع الزمنية `Timestamp`. المعرّفات `string`.

## المجموعات (Collections)

### `users/{uid}`
الملف الموحّد لأي مستخدم. الدور يحدّد التطبيق الذي يدخله.
```
role: 'customer' | 'driver' | 'partner' | 'admin'
name, phone, email, photoUrl
addresses: [{ id, label, line, lat, lng, notes }]
allergies: string[]            // قسم الحساسية (ميزة من تطبيق ديار الحالي)
favorites: { stores: string[], services: string[] }
walletBalance: number          // أغورة
points: number                 // نقاط الولاء — يمنحها الخادم عند delivered
                               // وفق config/loyalty (لا تُكتب من العميل)
fcmTokens: string[]
status: 'active' | 'blocked'
merchant?: boolean             // حساب تاجر B2B — تمنحه الإدارة فقط من
                               // اللوحة (Users)؛ يرى فئة تجار الجملة.
                               // محمي في القواعد ضد الكتابة الذاتية.
createdAt, updatedAt
```

### `stores/{storeId}`  (المتجر/المطعم/مزوّد الخدمة = Partner)
```
ownerUid: string               // → users (role=partner)
name, description, logoUrl, coverUrl
type: 'restaurant'|'grocery'|'pharmacy'|'flowers'|'service'|'store'|'wholesale'
                               // wholesale = متجر جملة B2B: يظهر فقط في فئة
                               // التجار لحسابات users.merchant==true
dietary?: string[]             // halal|kosher|vegetarian|vegan|glutenFree|spicy
                               // يصرّح بها التاجر؛ فلتر اكتشاف + شارات
dietaryVerified?: boolean      // توثيق الإدارة للحلال/الكوشير (admin فقط) → ✓
sabbathAware?: boolean         // إغلاق تلقائي يوم السبت (متاجر كوشير)
serviceCategory?: string       // عند type=='service' فقط — مهنة المزوّد:
                               // 'plumber'|'electrician'|'painter'|'mechanic'
                               // |'carpenter'|'accountant'|'lawyer'|'doctor'
                               // |'dentist'|'barber'|'salon'|'cleaning'
                               // |'electronics'|'ac'
                               // العقد الثابت: kServiceCategories في
                               // packages/dyar_core (key+emoji+labelAr/He/En)
categoryIds: string[]          // → categories
cityId: string                 // → cities
location: { lat, lng, address }
phone, email
isOpen: boolean                // تبديل يدوي/تلقائي حسب openingHours
openingHours: { [day]: {open,close}[] }
rating: number, ratingCount: number
deliveryFee: number, minOrder: number, prepTimeMins: number
brand: { template: 'elegant'|'fresh'|'street'|'pharma'|'boutique',
         accent?: '#hex' }     // هوية المينيو — قوالب MenuBrand في dyar_ui؛
                               // غيابه = هوية ديار الافتراضية. accent يعيد
                               // صبغ القالب بلون المتجر (يكتبه partner/admin)
commissionPct: number          // عمولة المنصّة
status: 'pending'|'approved'|'suspended'   // الإدارة توافق
createdAt, updatedAt
```
فرعية: `stores/{id}/menu/{itemId}` و `stores/{id}/options/{groupId}`.

حقول إضافية (من لوحة admin.dyar.app الحالية — تفاصيل المتجر):
```
fees: { serviceFeeFix, serviceFeePct, smallOrderFee, smallOrderUnder,
        bagFee, extraDeliveryFee, extraDeliveryAfterNProducts }
logistics: { commission, costPerKm, baseDeliveryFee, extraFee,
             fleet: boolean, fleetAccessToDyarDrivers: boolean }
whiteLabel: { showPaymentMethods, requireOtp, pickupOnly, showClientsOnApp }
advanced: { editDeliveryZones, createStaff, chargeSmallOrder,
            costPerBag, editBrandImage, editAddress }
dineOut: { active, description, cuisine, phone, menuPdfUrl, coverUrl,
           homeDeliveries, reservationCost, cancellationPolicy }
kiosk: { enabled, increasePrice }
webhooks: { menuCatalogUrl }
isPartner: boolean            // شارة شريك
searchKeywords: string[]
```
فرعية إضافية: `stores/{id}/tables/{tableId}` (Dine Out) و
`stores/{id}/staff/{uid}` (طاقم المتجر).

### `stores/{id}/zones/{zoneId}`  — مناطق التوصيل (من اللوحة الحالية)
```
name, center: { lat, lng }, radiusM: number
deliveryFee: number, active: boolean
```
المنطقة المعطّلة (`active=false`) تمنع الطلب منها. الرسوم لكل منطقة
تتجاوز رسوم المتجر الافتراضية.

### `stores/{id}/legal/contract`  — القانوني والتعاقدي
```
accepted: boolean, acceptedAt, signatureUrl   // توقيع رقمي (Storage)
termsVersion: string, requiresInvoice: boolean
bank: { bankName, iban, accountHolder }
personInCharge: { name, phone, email, idNumber }
```

### العمولة المتدرجة (السياسة الافتراضية — config/app.commissionTiers)
```
[{ maxMonthlyOrders: 299, pct: 15 },
 { maxMonthlyOrders: 500, pct: 13.5 },
 { maxMonthlyOrders: null, pct: 12 }]
serviceProvidersPct: 6     // حلاق/طبيب/ميكانيكي/محامي...
```
التسوية الشهرية تحتسب العمولة من عدد طلبات الشهر وفق هذه الشرائح،
مع إمكانية override لكل متجر عبر `commissionPct`.

### قواعد العمولة الذكية — `config/app.commissionRules`
قائمة قواعد **مرتبة بالأولوية** (أول قاعدة مطابقة تفوز) لتحديد العمولة
حسب البلد/المدينة/المتجر/نوع الخدمة مع دعم نسبة ذروة زمنية:
```
commissionRules: [{
  scope: 'store'|'city'|'country'|'storeType'
  match: string            // storeId | cityId | country | store.type
  pct: number              // النسبة الأساسية للقاعدة
  peakPct?: number         // نسبة الذروة (تتجاوز pct داخل النافذة)
  peakHours?: { from: 'HH:mm', to: 'HH:mm' }   // Asia/Jerusalem،
}]                         // النافذة تدعم عبور منتصف الليل (from > to)
```
ترتيب الحسم الكامل (`resolveCommissionPct` في
`backend/functions/src/ops/commission.ts`):
1. `stores/{id}.commissionPct` — override المتجر (الأعلى).
2. `type === 'service'` → `serviceProvidersPct` (افتراضي 6%).
3. أول قاعدة مطابقة من `commissionRules` (مع `peakPct` داخل النافذة).
4. `commissionTiers` حسب حجم الطلبات الشهري — **الافتراضي الأخير**.

### `stores/{storeId}/menu/{itemId}`
```
name, description, imageUrl, price: number
nameL2?, descriptionL2?            // لغة ثانية اختيارية (من اللوحة الحالية)
categoryId, optionGroupIds: string[]
available: boolean, sortOrder: number
extraDeliveryFee?: number          // رسوم توصيل إضافية للصنف
flags: { vegan, allergens, spicy, spillHazard }   // وسوم الصنف
maxQty?: number, featured?: boolean
minQty?: number                    // حد أدنى للكمية (افتراضي 1) —
                                   // لمتاجر الجملة B2B؛ يفرضه الـUI
dietary?: string[]                 // halal|kosher|vegetarian|vegan|glutenFree|spicy
                                   // شرائح على الصنف + مطابقة حساسيات المستخدم
```

### `stores/{storeId}/options/{groupId}`  (مجموعات الإضافات)
```
name: string                       // مثل "كاري اصفر"، "صدر دجاج"
active: boolean, sortOrder: number
choices: [{ name, price, active }]
showInKiosk: boolean
```

### `categories/{categoryId}`
أصناف عامة (طعام، بقالة، خدمات...). `{ name, icon, type, sortOrder, active }`.

### `cities/{cityId}`
مناطق التشغيل — مع إعدادات لكل مدينة (من admin.dyar.app):
```
name, country, active
hours: { open: 'HH:mm', close: 'HH:mm' }
orderNotifyEmail?: string
dynamicFare: { enabled, demandLevel: 'normal'|'high'|'very_high' }
zoneTiers: { basePct: 5, secondPct: 20, thirdPct: 15, fourthPct: 30,
             baseActive, secondActive, thirdActive, fourthActive }
saturation: { enabled, delayedTime?, until? }
commissionDisable: { enabled, vehicleType?, reactivateAt? }
autoAssignment: boolean              // إسناد آلي لكل مدينة
cancelIfNotAccepted: boolean
categories: { restaurants, groceries, pharmacies, flowers, services,
              stores, taxi, parcel, marketplace, bookings, jobs,
              market, express, pets, construction, driverRequest,
              healthy, dineout, local, sharedTransport }
              // تفعيل الفئات لكل مدينة — `categories.{key}=bool`.
              // المفاتيح الـ11 الأولى هي ما تتحكم به لوحة CitySettings
              // وما يقرأه تطبيق المستخدم (cityConfigProvider) لإخفاء
              // بلاطات الرئيسية. الافتراضي الآمن: غير المضبوط = ظاهر.
categoryBadges: { [category]: string }   // نص شارة لكل فئة
marketplace: { enabled[3], businessIds[], warehouse: { enabled, address,
               phone, hours } }
extraSellStore: { businessId, extraDeliveryCost, askDriverStoreData }
mainDashboardProductsBusinessId?: string
```

### `cities/{id}/zones/{zoneId}`  — مناطق المدينة (مضلّعات على الخريطة)
```
name, polygon: [{lat,lng}]          // رؤوس قابلة للتحرير (رسم حر)
deliveryFee: number
tier: 'base'|'second'|'third'|'fourth'   // Base area...
groupId?: string                    // مجموعات مناطق (Manage groups)
active: boolean                     // Disable zones
```
`cities/{id}/zoneGroups/{groupId}`: `{ name }`.

### إعدادات خدمات المدينة — `cities/{id}.services`
```
packageService: {
  request:  { basePer1Km, costPerExtraKm, serviceCost },
  withPayment: { enabled, basePer1Km, costPerExtraKm, increasePctOverProduct },
  weightTiers: { upTo5kg: {enabled, basePer1Km, costPerExtraKm, serviceCost},
                 upTo15kg: {...} },
  fastService: { enabled, ... },
  dynamicFare: { enabled, increasePct, demandLevel },
  extraStops: boolean, waitingTime: boolean,
  extraWeight: { enabled, costPerKg },
  paymentGateway?: string
}
taxiService / sharedTransport / parcelDelivery: نفس النمط (أساس + كم + خيارات)
```
خريطة الطلبات الحية (Orders map): تُرسم من `orders` النشطة بإحداثيات
`address.lat/lng` لكل مدينة.

### `drivers` — أعمدة لوحة السائقين (من اللوحة الحالية)
لكل سائق إضافةً لما سبق: `access: boolean` (دخول)، `loginEnabled: boolean`،
`prizes[]` (جوائز السائقين: pending_delivery|delivered)،
وقسم `employeeDrivers` (سائقو رواتب بحساب وقت يومي).

### حوافز السائقين لكل مدينة — `cities/{id}.driverIncentives`
```
speedBonus, connectionBonus, fuelCostSupport, deliveryProfit,
saveSpot, physicalPrizes: { enabled, ...params }
quickReplies: string[]            // ردود سريعة جاهزة للسائقين
paymentGateway: 'EasycardNG' | ...   // بوابة دفع السائقين
```
`newslettersDrivers/{id}`: نشرات موجهة للسائقين.

### `packageRoutes/{routeId}` — مسارات شحن الطرود (Package Delivery Services)
```
name: 'إسرائيل', pickupPoint, deliveryPoint, notes
maxWeightKg: 1000, maxVolumeM3: 6
rates: { base: 50, perKg: 100, perM3: 100 }
active: boolean
```

### قوالب البريد — `config/emails`
```
templates: {
  newUserRegistration: { html },             // HTML بأنماط CSS داخلية فقط
  driverOnboarding:    { subject, html },
  orderReceipt:        { subject, html },    // إيصال رقمي للطلب
}
```
المتغيرات بصيغة `{userName}` تُستبدل عند الإرسال (عبر دالة بريد في
Functions). لا CSS خارجي — كل التنسيق داخل الملف.

### بوابات الدفع — أسرار (Functions Secrets، لا تُخزَّن في Firestore)
```
GREENPAY:   merchantId, terminal
EASYCARDNG: terminalId, apiKey        // البوابة الأساسية في السوق
MERCADOPAGO: accessToken
STRIPE:     secret, webhook           // مُنفَّذ فعليًا لدينا
```
**طرق الدفع للمستخدم النهائي (قرار المالك): VISA (بطاقة) · CASH (نقدًا)
· BIT (تطبيق Bit الإسرائيلي)** — تُنفَّذ البطاقة عبر EasycardNG/Stripe،
وBit عبر تكامل بوابة محلية؛ `payment.method: 'card'|'cash'|'bit'|'wallet'`.
الاختيار لكل خدمة/مدينة عبر `paymentGateway` في الإعدادات؛ المفاتيح نفسها
عبر `firebase functions:secrets:set` فقط.

### استيراد البيانات من الويب (AI) — أداة لوحة
`{ source: 'UberEats'|..., url }` → دالة AI تسحب القائمة والصور وتبنيها
في `stores/{id}/menu` — تتكامل مع بنية الـ AI الموجودة (`ai/assistant.ts`).

### Extras لكل مدينة — `cities/{id}.extras`
```
games: {
  roulette: { enabled, endsAt,
    prizes: [{ discountPct, probabilityPct }] },   // المجموع 100%
  jackpot: { enabled, endsAt },
  scratchAndWin: { enabled, endsAt },
}
donation: { enabled, name, description, htmlUrl?, logoUrl?,
            amounts: [n1..n5], total }
quickRepliesUsers: string[], quickRepliesSupport: string[]
quickOffer: {...}
marketingPopups: [{ image, target: 'none'|'business'|'url', active }]
```
`donationLogs/{id}`: `{ orderId, name, email, amount, at }`.
جوائز السائقين (`driverPrizes`): `{ title, ordersRequired, prize, active }`
— تُمنح حسب عدد الطلبات المكتملة.

### البانرات والفلاتر لكل مدينة — `cities/{id}/banners` + `/filters`
```
banner: { image, title, placement: 'stories'|'main'|'lower'|'driver'
          |'<category>', target: { type: 'business'|'discount'|'search',
          businessId?, query? }, active, sortOrder }
filter: { category: 'services'|'restaurants'|..., name, icon, active }
// فلاتر الخدمات: خدمات منزلية، تنظيف، سباكة، تصليح سيارات، نجارة،
// كهربائي، إلكترونيات، تجميل، حلاق، غسيل... (شبكة أيقونات)
```

### `orders/{orderId}`  — قلب النظام
```
code: string                   // رقم قصير للعرض
customerUid, storeId, driverUid?
items: [{ itemId, name, qty, unitPrice, options[], lineTotal }]
status: 'pending'|'accepted'|'preparing'|'ready'|'assigned'
        |'picked_up'|'on_the_way'|'delivered'|'cancelled'|'rejected'
type: 'delivery' | 'pickup' | 'dinein' | 'service'
address: { line, lat, lng, notes }
pricing: { subtotal, deliveryFee, serviceFee, discount, tip, total }
payment: { method:'card'|'cash'|'wallet'|'paypal',
           status:'pending'|'paid'|'refunded'|'failed',
           intentId?, paidAt? }
timeline: [{ status, at, by }]  // سجل تدقيق كامل
eta?: Timestamp
rating?: { stars, comment }
createdAt, updatedAt
```

### `drivers/{uid}`  (ملف تشغيلي للسائق، مكمّل لـ users)
```
vehicle: { type:'car'|'motorcycle'|'bicycle', plate?, model? }
documents: { license, insurance, idCard }  // روابط Storage + حالة تحقق
isOnline: boolean
currentLocation: { lat, lng, heading, at }
status: 'pending'|'approved'|'suspended'
activeOrderId?: string
earnings: { today, week, total }            // أغورة
rating: number, ratingCount: number
stats: { avgDeliveryMins, deliveries,
         deliveredCount }       // deliveredCount يحرّك جوائز driverPrizes
```

### `coupons/{couponId}`
`{ code, type:'pct'|'fixed', value, minOrder, maxDiscount, usageLimit, usedCount, storeId?, expiresAt, active }`

### `promotions/{promoId}`
بانرات/عروض الواجهة. `{ title, image, target, storeId?, active, sortOrder }`

### `reviews/{reviewId}`
`{ orderId, customerUid, storeId, driverUid?, stars, comment, createdAt }`

### `transactions/{txId}`  — السجل المالي
`{ orderId?, uid, type:'order'|'payout'|'topup'|'refund'|'commission'|'prize_bonus', amount, balanceAfter, createdAt }`
`prize_bonus`: مكافأة جائزة مندوبين (driverPrizes) — يكتبها الخادم فقط.

### `notifications/{id}`
`{ uid, title, body, data, read, createdAt }`

### `broadcasts/{id}`  — بث الإشعارات (لوحة التحكم → FCM topics)
```
title, body: string
audience: 'customers' | 'drivers' | 'partners' | 'uid'
uid?: string                   // عند audience='uid' (مستخدم واحد)
sentBy: string                 // uid المُرسِل من اللوحة
sentCount: number
createdAt: Timestamp
```
تُرسل عبر callable **`sendBroadcast`** (admin أو staff بصلاحية
`broadcast` في claims.perms): إلى موضوع FCM `role-{audience}` — تشترك
التطبيقات بموضوع دورها عند الإقلاع (موبايل فقط، انظر
`initDyarFirebase(broadcastTopic:)`) — أو إلى fcmTokens مستخدم واحد.
الصلاحيات: قراءة backoffice؛ الكتابة عبر Functions فقط.

### `blockedAddresses/{id}`  — عناوين محظورة (مكافحة الاحتيال)
`{ line: string, reason: string, createdAt }`
`createOrder` يرفض أي طلب يحتوي `address.line` (بعد trim+lowercase) على
سطر محظور — `HttpsError('failed-precondition','blocked-address')`.
الصلاحيات: قراءة/كتابة admin فقط.

### `support/{ticketId}` — حقول تذاكر الوكيل الصوتي
```
via?: 'voice-agent'            // مصدر التذكرة
topic?: string                 // order-issue|driver|app|refund|other
orderCode?, phone?: string     // للمتابعة والاتصال
```

### `config/voice`  (صوت ديار — ElevenLabs)
```
enabled: boolean               // مفتاح عام من اللوحة
agentId?: string               // وكيل المحادثة الحية (ConvAI) — docs/VOICE-AGENT.md
support, support2, driver, announce: string  // Voice IDs للشخصيات الأربع
```

### `config/loyalty`  — نظام النقاط (الولاء)
```
enabled: boolean
earnPerShekel: number          // نقاط لكل ₪1 من إجمالي الطلب
redeemRate: number             // أغورة لكل نقطة عند الاستبدال
```
عند `delivered`: الخادم يزيد `users/{customerUid}.points` بمقدار
`round(total/100 * earnPerShekel)`. الكتابة admin (من بطاقة الإعدادات).

### `driverPrizes/{id}`  — جوائز المندوبين 🏆
```
title: string
targetDeliveries: number       // هدف عدد التوصيلات
bonus: number                  // أغورة
active: boolean
createdAt: Timestamp
```
عند بلوغ `drivers/{uid}.stats.deliveredCount` هدف جائزة نشطة: حركة
`transactions` بنوع `prize_bonus` + زيادة `earnings.total` (خادم فقط).
الصلاحيات: قراءة للجميع (تحفيز السائقين)، كتابة admin.

### `support/{ticketId}`
`{ uid, subject, messages[], status:'open'|'closed', createdAt }`

### `marketProducts/{productId}`  — سوق C2C (بيع وشراء)
المستخدم يرفع منتجًا، الإدارة توافق، والمنصّة تأخذ عمولة عند البيع.
```
sellerUid: string              // → users (أي مستخدم مسجّل)
title, description: string
price: number                  // أغورة
imageUrl: string
category: 'electronics'|'fashion'|'home'|'cars'|'other'
city: string
status: 'pending'|'approved'|'rejected'|'sold'
createdAt: Timestamp           // (+ soldAt عند البيع)
```
الصلاحيات: القراءة للجميع عند `approved`؛ البائع يقرأ منتجاته بكل
الحالات؛ create لأي مسجّل بـ `status:'pending'` فقط؛ البائع يعدّل منتجه
دون `status/sellerUid`؛ admin كل شيء. **البيع النهائي عبر callable
`markProductSold`** (البائع أو admin): يضع `sold` ويكتب في `transactions`
عمولة بالسالب على البائع =
`price * config/app.marketplaceCommissionPct (افتراضي 5) / 100`.

### `config/app`  (وثيقة إعدادات مفردة)
`{ serviceFee, defaultCommissionPct, marketplaceCommissionPct, commissionTiers, serviceProvidersPct, commissionRules, currency, supportPhone, minAppVersion, maintenanceMode, referralReward, surgeEnabled, platformName, brandColor, phoneCode, mapsEnabled, newUserGift }`

إعدادات الهوية والعموميات (تدقيق v5.2.001):
`platformName` اسم المنصة المعروض؛ `brandColor` لون الهوية (hex)؛
`currency` (افتراضي ILS)؛ `phoneCode` رمز الهاتف الدولي (افتراضي +972)؛
`mapsEnabled` تفعيل الخرائط؛ `newUserGift` هدية المستخدم الجديد (أغورة).

`commissionTiers` و`serviceProvidersPct` و`commissionRules` موثّقة أعلاه
في قسم «العمولة المتدرجة» و«قواعد العمولة الذكية».
`{ serviceFee, defaultCommissionPct, marketplaceCommissionPct, currency, supportPhone, minAppVersion, maintenanceMode, referralReward, surgeEnabled, defaultCityId? }`

`defaultCityId`: المدينة التي يقرأ منها تطبيق المستخدم قواعد الرؤية
(`cities/{id}.categories`) عبر `cityConfigProvider` — وإن غاب، تُؤخذ أول
مدينة `active`، وإن لم توجد فكل الفئات ظاهرة (افتراضي آمن).

---
## وحدات السوبر آب (من دراسة تطبيق ديار الحالي + المنافسين)

### `rides/{rideId}`  — مشاوير التاكسي (مثل Uber/Careem)
```
customerUid, driverUid?
pickup: { lat, lng, address }
dropoff: { lat, lng, address }
tier: 'standard' | 'comfort' | 'xl'     // قياسي/راحة/عائلي
status: 'searching'|'accepted'|'arriving'|'in_progress'|'completed'|'cancelled'
pricing: { base, perKm, surge: number, total }   // surge=1 بلا ذروة
distanceKm, durationMins
payment: { method, status }
sos?: { triggeredAt, location }          // زر الطوارئ
rating?: { stars, comment }
createdAt, updatedAt
```

### `parcels/{parcelId}`  — شحن الطرود
```
senderUid, driverUid?
sender: { name, phone, address, lat, lng }
recipient: { name, phone, address, lat, lng }
route: { from, to }                      // مسار التوصيل (داخلي/دولي)
size: { weightKg, volumeM3 }             // حد أقصى 1000كغ / 6م³
status: 'pending'|'pickup'|'in_transit'|'delivered'|'cancelled'
pricing: { total }, payment: { method, status }
createdAt, updatedAt
```

### `bookings/{bookingId}`  — حجز طاولات/مواعيد خدمات
```
customerUid, storeId
type: 'table' | 'service'                // طاولة مطعم أو موعد (حلاق/طبيب..)
partySize?: number, tableId?: string     // Vip 1...
slot: Timestamp, notes?: string
reminder: boolean                        // تذكير قبل 30 دقيقة (FCM مجدول)
fee: number                              // رسوم حجز/طلب صغير
status: 'pending'|'confirmed'|'seated'|'completed'|'cancelled'|'no_show'
createdAt, updatedAt
```
فرعية للمتجر: `stores/{id}/tables/{tableId}` `{ name, seats, zone }` و
`stores/{id}/slots` (التوفر).

### `giftcards/{cardId}`  — بطاقات الهدايا
```
code: string, amount: number, balance: number
purchaserUid, recipientEmail?, recipientName?
status: 'active'|'redeemed'|'expired'
redeemedBy?, redeemedAt?, expiresAt
```

### `referrals/{uid}`  — ادعُ واربح
```
code: string                             // رمز المشاركة الفريد
invitedBy?: string                       // رمز من دعاه
invitees: string[]                       // من استخدموا رمزه
rewards: { freeDeliveries: number, credit: number }
```

### `jobs/{jobId}`  — لوحة الوظائف
```
title, description, storeId?, cityId
type: 'driver'|'kitchen'|'service'|'other'
salary?: string, contact: { phone?, email? }
status: 'open'|'closed', createdAt
```

### `jobApplications/{id}`  — طلبات التوظيف (تقديم + سيرة ذاتية)
```
jobId: string                            // الوظيفة المتقدَّم لها
jobTitle?: string                        // denormalized لعرض "طلباتي"
applicantUid: string
name: string, phone: string
cvText: string                           // نبذة/سيرة ذاتية نصية
cvUrl?: string                           // ملف CV في Storage (اختياري)
status: 'new'|'shortlisted'|'rejected'|'hired'
createdAt
```
الصلاحيات: المتقدم ينشئ لنفسه بحالة `new` ويقرأ طلباته؛ admin/staff
وpartner صاحب الوظيفة (عبر `jobs.storeId → stores.ownerUid`) يقرآن
ويحدّثان `status` فقط. فهارس: `jobId+createdAt`، `applicantUid+createdAt`.

### `chats/{chatId}` + `chats/{id}/messages/{msgId}`  — دردشة الطلب
```
chat: { orderId|rideId|parcelId, participants: uid[], lastMessage, updatedAt }
message: { senderUid, text, imageUrl?, sentAt, readBy: uid[] }
```

## دورة حياة الطلب (State Machine)
```
pending → accepted → preparing → ready → assigned → picked_up
        → on_the_way → delivered
(أي مرحلة) → cancelled / rejected
```
التحوّلات الحساسة تُنفَّذ عبر Cloud Functions فقط (لا من العميل مباشرة):
الدفع، تعيين السائق، احتساب الأرباح/العمولة، استرداد المبالغ.

## مصفوفة الصلاحيات (مختصر)
| المجموعة | customer | driver | partner | admin |
|---|---|---|---|---|
| users (own) | RW | RW | RW | RW(all) |
| stores | R | R | RW(own) | RW |
| menu | R | R | RW(own store) | RW |
| orders | RW(own) | R/update(assigned) | R/update(own store) | RW |
| drivers | — | RW(own) | — | RW |
| coupons/promotions/categories/cities/config | R | R | R | RW |
| transactions | R(own) | R(own) | R(own) | RW |

التفاصيل الكاملة منفّذة في `backend/firestore.rules`.

### `config/features`  (مفاتيح إظهار/إخفاء الميزات — تديرها اللوحة)
```
<featureKey>: boolean          // مفتاح عالمي (الافتراضي true = ظاهر)
byRegion: { <cityId>: { <featureKey>: boolean } }   // تجاوز للمنطقة
```
الجمهور (user/partner/driver/service) ضمنيٌّ في مفتاح الميزة. تقرأها كل
التطبيقات عبر `featureFlagsProvider` (dyar_core) وتدمجها مع رؤية المدينة
(CityConfig). تُدار من صفحة **الميزات** باللوحة. المفاتيح المعروفة في
`kFeatureKeysByAudience`.

### تتبّع المراحل والتعلّم (Live tracking + AI-lite)
- `orders/{id}.stageMins` = `{ accept, prep, pickup, deliver, total }` —
  دقائق كل مرحلة، تُحسب من الخط الزمني عند التسليم (تظهر في درج الطلب باللوحة).
- `stores/{id}.stageStats` و`drivers/{id}.stats.avgPickupMins/avgDeliverMins` —
  متوسطات متحركة EMA (80/20) = هوية أداء المتجر/السائق.
- `learning/byType_{type}` = `{ type, stageStats:{accept,prep,pickup,deliver,total,count} }`
  — تعلّم التوقيت حسب نوع الطلب. تقرأها اللوحة (backoffice) فقط؛ الكتابة Functions.
