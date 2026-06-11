# تقرير المراجعة الأمنية — منصّة dyar (قبل الإطلاق)

**التاريخ:** 2026-06-11
**النطاق المُختبَر:** `dyar.app`، `admin.dyar.app`، والبنية الخلفية المشتركة (Firebase project: `cafi-a68cf`)
**نوع الفحص:** مراجعة أمنية **غير تدميرية** (passive / safe reconnaissance) — لا هجمات حجب خدمة، ولا تخمين كلمات مرور، ولا كتابة/تعديل بيانات، ولا تنزيل بيانات مستخدمين.
**الحالة:** ⚠️ **يوجد بند حرج واحد يجب إغلاقه قبل الإطلاق والإعلان.**

> هذا التقرير موجّه للمطورين. كل بند يحتوي: الخطورة، الوصف، الدليل، الأثر، والإصلاح المقترح.

---

## ملخّص تنفيذي

| # | البند | الخطورة | الحالة |
|---|---|:---:|---|
| 1 | مخزن Firebase Storage مفتوح للسرد بلا مصادقة (1000+ ملف) | 🔴 **حرجة** | يجب الإصلاح فوراً |
| 2 | مسارات backend حساسة مكشوفة في كود العميل (OTP/محفظة/بطاقات هدايا/proxy/admin) | 🟠 **عالية** | يجب التحقق من الحماية الخادمية |
| 3 | غياب الترويسات الأمنية (CSP, X-Frame-Options, …) | 🟡 متوسطة | يُنصح بشدّة |
| 4 | مفاتيح API للعميل غير مقيّدة (Firebase + Google Maps) | 🟡 متوسطة | يُنصح بشدّة |
| 5 | لوحة admin متاحة علناً — يجب فرض الصلاحيات خادمياً | 🟡 متوسطة | تحقّق |
| 6 | كشف معلومات بسيط (asset-manifest، نطاقات Firebase الافتراضية) | 🔵 منخفضة | تحسين |
| 7 | تقوية مصادقة Firebase (حماية تعداد البريد، MFA للأدمن) | 🔵 منخفضة | تحسين |

**نقاط سليمة مؤكَّدة (جيّد):** Firestore محمي بقواعد (كل المجموعات تُرجع 403 بلا مصادقة) ✅ — لا توجد Realtime Database مفتوحة (404) ✅ — HSTS مُفعّل ✅ — خرائط المصدر (source maps) و`.env`/`.git` **غير** مكشوفة (ما ظهر 200 كان مجرد إعادة توجيه SPA) ✅.

---

## 1) 🔴 حرجة — Firebase Storage مفتوح للسرد العام بلا مصادقة

**الوصف:** نقطة سرد ملفات المخزن تستجيب لطلب بلا أي رمز مصادقة وتُعيد قائمة ملفات.

**الدليل (رموز حالة فقط — لم نُنزّل أي محتوى):**
```
GET https://firebasestorage.googleapis.com/v0/b/cafi-a68cf.appspot.com/o
→ HTTP 200   (الصفحة الأولى وحدها أعادت 1000 عنصر = الحد الأقصى للصفحة)
Access-Control-Allow-Origin: *   ← أي موقع خارجي يستطيع القراءة
```

**الأثر:** أي شخص على الإنترنت يمكنه **تعداد وتنزيل** كل الملفات المرفوعة (صور المستخدمين، مستندات، هويات، إيصالات… أياً كان محتواها) دون تسجيل دخول. هذا تسريب بيانات مباشر وانتهاك خصوصية، وأخطر بند قبل الإطلاق.

**الإصلاح:** ضبط قواعد Storage لتطلب المصادقة وتمنع سرد الجذر. مثال:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // امنع كل شيء افتراضياً
    match /{allPaths=**} { allow read, write: if false; }

    // اسمح فقط لصاحب الملف بالوصول لمجلده
    match /users/{userId}/{file=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // أصول عامة فقط (إن وُجدت) — للقراءة دون سرد كامل
    match /public/{file=**} { allow read: if true; allow write: if false; }
  }
}
```
ثم: **فعّل Firebase App Check** على Storage، وراجع الملفات المرفوعة حالياً.

---

## 2) 🟠 عالية — مسارات backend حساسة مكشوفة في حزمة العميل

**الوصف:** حزمة `dyar.app/static/js/main.*.js` تحتوي مسارات استدعاء خلفية حسّاسة (على الأرجح Cloud Functions). استُخرجت من الكود **دون استدعائها** (تجنّباً لأي أثر جانبي):
```
/drivers/create-otp/        /drivers/create-new-otp/
/drivers/createcust/        /drivers/linkcustomer/   /drivers/detachcustomer/
/drivers/cancelorder/       /drivers/gift-card-add    /drivers/gift-card-check
/drivers/proxy/             /user-wallet              /users/
/admin/account              /admin/templates
```

**الأثر:** إذا كان أي من هذه المسارات لا يفرض **مصادقة + تفويض (authorization) خادمياً**، فقد يتمكّن مهاجم من: توليد OTP، إضافة/فحص بطاقات هدايا، التلاعب بالمحفظة، إنشاء/ربط عملاء، أو الوصول لوظائف admin. مسار `proxy` خطير بشكل خاص (احتمال SSRF/open proxy).

**الإصلاح (يجب التحقق يدوياً لكل مسار):**
- تحقّق أن كل دالة تتطلّب `request.auth` صالحاً، وتتحقق من **custom claims/الدور** (driver/admin) خادمياً وليس في الواجهة فقط.
- طبّق **تحديد معدّل (rate limiting)** على create-otp و gift-card.
- تحقّق من المدخلات (input validation) ومن صلاحية الملكية (هل هذا السائق يملك هذا الطلب؟).
- راجع `proxy` خصيصاً ضد SSRF (قائمة سماح للوجهات).
- فعّل **App Check** كشرط لاستدعاء الدوال.

> لم نختبر هذه المسارات فعلياً لأن استدعاءها قد ينشئ بيانات أو يُطلق رسائل OTP. تتطلب مراجعة كود + اختبار مُصادَق في بيئة staging.

---

## 3) 🟡 متوسطة — غياب الترويسات الأمنية

**الدليل:** الترويسات الموجودة على `dyar.app` و`admin.dyar.app` تقتصر على `Strict-Transport-Security`. **مفقود:**
```
Content-Security-Policy      (لا يوجد)  → حماية ضعيفة ضد XSS
X-Frame-Options / frame-ancestors (لا يوجد) → عرضة للـ Clickjacking
X-Content-Type-Options: nosniff   (لا يوجد)
Referrer-Policy              (لا يوجد)
Permissions-Policy           (لا يوجد)
```

**الإصلاح:** أضِفها في `firebase.json` ضمن `hosting.headers`:
```json
{
  "source": "**",
  "headers": [
    { "key": "X-Frame-Options", "value": "DENY" },
    { "key": "X-Content-Type-Options", "value": "nosniff" },
    { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
    { "key": "Permissions-Policy", "value": "geolocation=(self), camera=(), microphone=()" },
    { "key": "Content-Security-Policy", "value": "default-src 'self'; script-src 'self' https://www.googletagmanager.com https://*.googleapis.com; img-src 'self' data: https:; connect-src 'self' https://*.googleapis.com https://firebasestorage.googleapis.com; frame-ancestors 'none'" }
  ]
}
```
(اضبط CSP تدريجياً حسب النطاقات التي يحتاجها التطبيق فعلاً.)

---

## 4) 🟡 متوسطة — مفاتيح العميل غير مقيّدة

**الدليل:** ظاهرة في كود العميل (وهذا طبيعي لتطبيقات الويب، لكنها تحتاج تقييداً):
- مفتاح Firebase Web API: `AIzaSyB…YMd4` (مشروع `cafi-a68cf`)
- مفتاح Google Maps: `googleMapsAPI: "AIzaSyDlEiv…HZfZk"`

**الأثر:** مفاتيح غير مقيّدة قد تُساء لتوليد فواتير (Maps)، أو لإساءة استخدام Identity Toolkit (تسجيلات مزعجة/استنزاف حصص).

**الإصلاح:**
- قيّد مفتاح Maps بـ **HTTP referrer restrictions** (نطاقات dyar فقط) وبالـAPIs المطلوبة فقط في Google Cloud Console.
- فعّل **Firebase App Check** (reCAPTCHA Enterprise للويب) لربط الطلبات بتطبيقاتك الشرعية.
- راجع تقييد مفتاح Firebase حسب الإمكان.

---

## 5) 🟡 متوسطة — لوحة admin متاحة علناً

**الدليل:** `https://admin.dyar.app/` (تطبيق Flutter web) يُقدَّم لأي زائر بـ HTTP 200.

**الأثر:** تقديم شِفرة اللوحة للعموم طبيعي في تطبيقات SPA، لكن الخطر يكمن إن كانت الصلاحيات مفروضة في الواجهة فقط. يجب أن يكون كل إجراء إداري محمياً **خادمياً**.

**الإصلاح:**
- افرض دور admin عبر **custom claims** + قواعد Firestore/Functions، لا عبر إخفاء عناصر الواجهة فقط.
- فعّل **App Check** على اللوحة، وفعّل **MFA** لحسابات الأدمن.
- فكّر في تقييد الوصول للوحة (Firebase Hosting + IAP/قائمة IP إن أمكن).

---

## 6) 🔵 منخفضة — كشف معلومات بسيط

- `https://dyar.app/asset-manifest.json` (HTTP 200, JSON) يكشف بنية ملفات التطبيق. غير حرج لكن يُفضّل عدم نشره.
- التطبيق متاح أيضاً عبر النطاقات الافتراضية `cafi-a68cf.web.app` و`cafi-a68cf.firebaseapp.com` (HTTP 200) — قد تتجاوز أي ضوابط مربوطة بالنطاق المخصّص. فكّر في إعادة التوجيه للنطاق الرسمي.
- اسم مشروع Firebase الداخلي (`cafi-a68cf`) يختلف عن العلامة (dyar) — كشف بسيط لا يستدعي إجراءً.

---

## 7) 🔵 منخفضة — تقوية مصادقة Firebase

- فعّل **Email Enumeration Protection** (يمنع كشف وجود بريد من رسائل الخطأ).
- افرض **سياسة كلمة مرور قوية** و**MFA** (خصوصاً للأدمن والسائقين).
- راجع طرق تسجيل الدخول المُفعّلة واحذف غير المستخدم منها.

---

## قائمة التحقق قبل الإطلاق (Pre-launch Checklist)

- [ ] 🔴 إغلاق قواعد Firebase Storage ومنع السرد العام + App Check.
- [ ] 🟠 مراجعة وتأمين كل مسارات `/drivers/*`, `/user-wallet`, `/admin/*` خادمياً (auth + authz + rate limit + input validation + فحص `proxy` ضد SSRF).
- [ ] 🟡 إضافة الترويسات الأمنية (CSP, X-Frame-Options, nosniff, Referrer-Policy, Permissions-Policy).
- [ ] 🟡 تقييد مفاتيح Maps/Firebase + تفعيل App Check.
- [ ] 🟡 تأكيد فرض دور admin خادمياً + MFA.
- [ ] 🔵 إخفاء asset-manifest، توحيد النطاق، تقوية المصادقة.
- [ ] إعادة الفحص بعد الإصلاح، ويُفضّل اختبار اختراق مُصادَق على بيئة staging للبنود التي يتعذّر فحصها بأمان على الإنتاج.

---

## المنهجية والحدود

- كل الفحوص كانت **قراءة فقط/غير تدميرية**؛ لم يُنزَّل أي محتوى مستخدمين ولم تُكتب أي بيانات.
- مسارات الـbackend في البند 2 **لم تُستدعَ** تجنّباً للآثار الجانبية — تحتاج مراجعة كود + اختبار مُصادَق.
- الفحص خارجي (black-box) من مصدر واحد؛ لا يغني عن مراجعة شِفرة قواعد الأمان (Storage/Firestore rules) والدوال مباشرةً.
