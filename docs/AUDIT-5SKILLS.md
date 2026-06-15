# 🔬 تقرير التدقيق بالمهارات الخمس (13/06/2026)

فحص فعلي للكود بـ flutter-code-review · flutter-security-audit ·
flutter-performance · flutter-testing · ux-ui-review. كل بند بدليل.

## 🔴 حرِج — يُعالَج أولًا

### 1. صفر اختبارات Flutter (أكبر خطر)
- **الدليل**: `find apps packages -name '*_test.dart'` = **0**. (الخلفية فيها
  قواعد 23/23 + عمولة 10/10، لكن التطبيقات الثلاثة + dyar_core بلا أي اختبار.)
- **الخطر**: تطبيق مال/طلبات/مصادقة بلا شبكة أمان — أي تعديل قد يكسر التسعير
  أو دورة الطلب أو فلتر الحلال دون أن نلاحظ.
- **الإصلاح**: ابدأ بـ unit للنماذج (`Store/MenuItem/Order.fromDoc` + getters
  مثل isHalal، minQty) ومنطق السلة/التسعير؛ ثم widget لـ checkout وdietary
  filter؛ ثم golden RTL لبطاقة المتجر. الهدف: ≥70% على المسارات المالية.

## 🟡 مهم — قبل التوسّع

### 2. تسريب Controllers (لا dispose)
- **الدليل**: 13 ملفًا تنشئ `TextEditingController` كحقول State بلا `dispose()`:
  user(login/checkout/addresses/profile/parcel) · driver(login/register/
  support/earnings/active_parcel) · partner(login/promotions/menu).
  مثال مؤكد: `user/login_screen.dart:15-16` (`_phone`,`_code`).
- **الإصلاح**: أضف `@override void dispose(){ _x.dispose(); super.dispose(); }`
  لكل State فيه controllers (شاشات الدخول/الدفع تُدخَل مرارًا = تسرّب متراكم).

### 3. أداء الصور — بلا memCacheWidth
- **الدليل**: 8 استخدامات `CachedNetworkImage`، **0** منها بـ `memCacheWidth/Height`
  → تحميل صور بدقة كاملة في بطاقات 150px (هدر ذاكرة + jank بقوائم المتاجر).
- **الإصلاح**: `memCacheWidth: (w*dpr).round()` على أغلفة المتاجر/الأصناف.

### 4. لا RepaintBoundary على بطاقات القوائم
- **الدليل**: `RepaintBoundary` = 0 في كل التطبيقات؛ بطاقات المتجر بظلال داخل
  `SliverList` تُعاد رسمها أثناء التمرير.
- **الإصلاح**: غلّف `_StoreCard` بـ `RepaintBoundary`.

### 5. الإتاحة — صفر Semantics
- **الدليل**: `Semantics(` = 0. أزرار أيقونية (♥ مفضلة، 🖨️ طباعة، رجوع،
  جرس) بلا تسميات لقارئ الشاشة.
- **الإصلاح**: `Semantics(button:true, label:'...')` أو `tooltip` للأزرار الأيقونية.

### 6. RTL — EdgeInsets.only(left/right)/fromLTRB
- **الدليل**: 29 موضعًا. كثير منها متماثل (آمن) لكن غير المتماثل يجب تحويله
  لـ `EdgeInsetsDirectional`/`start`/`end` لئلا ينقلب خطأ في العبرية/الإنجليزية.
- **الإصلاح**: تدقيق الـ29 وتحويل غير المتماثل.

## 🟢 تحسينات

### 7. توطين وحدات ثابتة
- "كغم"، بعض الوحدات مكتوبة حرفيًا (`driver/home_screen.dart:452`) — انقلها لـ i18n.
- (أغلب الـ18 المرصودة إيجابيات كاذبة: إيموجي/قيم ديناميكية/شعار «د».)

### 8. تنعيم القوائم
- `itemExtent`/`prototypeItem` لقائمة المتاجر (ارتفاع بطاقة شبه ثابت) لتمرير أنعم.

### 9. Golden tests RTL
- لقطات golden لبطاقة المتجر/الصنف بالعربية والإنجليزية (تثبيت Dyar Ultra UI).

## ✅ الأمان — نظيف إجمالًا
- **لا أسرار في الكود** (فقط `demo-key` لوضع المحاكي). لا `http://`. لا
  `print` لبيانات حسّاسة. التوكنات يديرها Firebase SDK بأمان. SharedPreferences
  يحمل فقط اللغة + مفتاح القفل (غير حسّاس). قفل Face ID موجود (`app_lock.dart`).
  القواعد server-authoritative ومختبرة 23/23.
- **ملاحظتان** (موثّقتان بالـRunbook، غير معطِّلتين): App Check لم يُفعَّل بعد ·
  `FLAG_SECURE` ضد لقطات شاشة الدفع غير مضبوط (يُضاف قبل النشر).

## 🎯 أين تبدأ — أهم 3
1. **اختبارات Flutter** (يقلّل الخطر الأكبر) — النماذج + التسعير + dietary filter.
2. **dispose للـ Controllers** (سريع، يمنع التسريب) — 13 ملفًا.
3. **أداء الصور + RepaintBoundary** (المسار الأكثر استخدامًا: تصفّح المتاجر).

> كلها تحسينات جودة/صلابة — **لا تكسر الإطلاق**. النظام يعمل ومنشور.
> هذه ترفعه من «يعمل» إلى «متين قابل للصيانة بثقة».
