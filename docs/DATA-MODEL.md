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
fcmTokens: string[]
status: 'active' | 'blocked'
createdAt, updatedAt
```

### `stores/{storeId}`  (المتجر/المطعم/مزوّد الخدمة = Partner)
```
ownerUid: string               // → users (role=partner)
name, description, logoUrl, coverUrl
type: 'restaurant'|'grocery'|'pharmacy'|'flowers'|'service'|'store'
categoryIds: string[]          // → categories
cityId: string                 // → cities
location: { lat, lng, address }
phone, email
isOpen: boolean                // تبديل يدوي/تلقائي حسب openingHours
openingHours: { [day]: {open,close}[] }
rating: number, ratingCount: number
deliveryFee: number, minOrder: number, prepTimeMins: number
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

### `stores/{storeId}/menu/{itemId}`
```
name, description, imageUrl, price: number
nameL2?, descriptionL2?            // لغة ثانية اختيارية (من اللوحة الحالية)
categoryId, optionGroupIds: string[]
available: boolean, sortOrder: number
extraDeliveryFee?: number          // رسوم توصيل إضافية للصنف
flags: { vegan, allergens, spicy, spillHazard }   // وسوم الصنف
maxQty?: number, featured?: boolean
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
categories: { restaurants, stores, market, pharmacies, express, pets,
              services, construction, jobs, driverRequest, taxi, healthy,
              dineout, local, booking, sharedTransport, parcel,
              marketplace }          // تفعيل الفئات لكل مدينة
categoryBadges: { [category]: string }   // نص شارة لكل فئة
marketplace: { enabled[3], businessIds[], warehouse: { enabled, address,
               phone, hours } }
extraSellStore: { businessId, extraDeliveryCost, askDriverStoreData }
mainDashboardProductsBusinessId?: string
```

### `drivers` — أعمدة لوحة السائقين (من اللوحة الحالية)
لكل سائق إضافةً لما سبق: `access: boolean` (دخول)، `loginEnabled: boolean`،
`prizes[]` (جوائز السائقين: pending_delivery|delivered)،
وقسم `employeeDrivers` (سائقو رواتب بحساب وقت يومي).

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
```

### `coupons/{couponId}`
`{ code, type:'pct'|'fixed', value, minOrder, maxDiscount, usageLimit, usedCount, storeId?, expiresAt, active }`

### `promotions/{promoId}`
بانرات/عروض الواجهة. `{ title, image, target, storeId?, active, sortOrder }`

### `reviews/{reviewId}`
`{ orderId, customerUid, storeId, driverUid?, stars, comment, createdAt }`

### `transactions/{txId}`  — السجل المالي
`{ orderId?, uid, type:'order'|'payout'|'topup'|'refund'|'commission', amount, balanceAfter, createdAt }`

### `notifications/{id}`
`{ uid, title, body, data, read, createdAt }`

### `support/{ticketId}`
`{ uid, subject, messages[], status:'open'|'closed', createdAt }`

### `config/app`  (وثيقة إعدادات مفردة)
`{ serviceFee, defaultCommissionPct, currency, supportPhone, minAppVersion, maintenanceMode, referralReward, surgeEnabled }`

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
