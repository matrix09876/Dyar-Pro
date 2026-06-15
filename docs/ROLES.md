# Dyar v10 — الأدوار والصلاحيات (RBAC)

خمسة أدوار، لكلٍّ تطبيقه ولوحته، والمسؤول (admin) وحده يضبط القواعد من لوحة التحكم.

| الدور | التطبيق/الواجهة | يدير |
|---|---|---|
| `customer` | dyar.user | طلباته، عناوينه، محفظته، تقييماته |
| `driver` | dyar.driver | مهامه، موقعه الحي، أرباحه |
| `partner` | dyar.partner | متجره، قائمته، طلباته، عروضه |
| `staff` (عامل مكتب) | لوحة التحكم — صلاحيات محدودة | حسب ما يمنحه المسؤول |
| `admin` (المسؤول) | لوحة التحكم — كامل | كل شيء + ضبط صلاحيات الجميع |

## صلاحيات عامل المكتب (staff)
تُخزَّن في `users/{uid}.permissions` كقائمة مفاتيح، يضبطها المسؤول فقط:
```
orders.view, orders.manage, orders.assignDriver,
stores.view, stores.approve,
drivers.view, drivers.approve,
users.view, users.block,
marketing.manage, finance.view, support.manage
```
الواجهة تُظهر/تُخفي الوحدات حسب هذه المفاتيح؛ والخادم (Cloud Functions
+ Firestore Rules) يفرضها فعليًا — لا يكفي الإخفاء في الواجهة.

## مصدر الصلاحية
- **الدور**: Custom Claim `role` (يُضبط عبر `setUserRole` — admin فقط).
- **صلاحيات staff الدقيقة**: `users/{uid}.permissions` + Claim `perms`.
- كل عملية حسّاسة تُتحقق مرتين: Firestore Rules + منطق Cloud Function.

## الذكاء الاصطناعي (AI)
- **تتبّع ذكي**: دالة `aiEta` تقدّر وقت الوصول من موقع السائق الحي + المسافة.
- **رد آلي للدعم**: دالة `aiSupportReply` ترد على رسائل الدعم بلغة المستخدم
  (عربي/عبري/إنجليزي) عبر Claude، مع تصعيد للبشر عند الحاجة.
- المفاتيح: `ANTHROPIC_API_KEY` كـ Secret — لا في الكود.
