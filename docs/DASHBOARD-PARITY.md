# مطابقة لوحة التحكم — admin.dyar.app (21 قسمًا) → Dyar v10

المرجع: تقرير لوحة ديار الحالية (11/06/2026). ✅ موجود · 🔶 جزئي · 🔜 تالٍ.

| # | القسم الحالي | في Dyar v10 | حالة |
|---|---|---|---|
| 1 | Orders (تبويبات + Dynamic fare + Assignment) | `/orders` فلاتر حالة + مفاتيح التسعير الديناميكي والإسناد الآلي في الترويسة | ✅ |
| 2 | Marketplace › Orders | نموذج B2C/B2B في DATA-MODEL — واجهة | 🔜 |
| 3 | Marketplace › Products | فئات/منتجات السوق | 🔜 |
| 4 | Marketplace › Banners | `/marketing` بانرات (promotions) | 🔶 |
| 5 | Marketplace › Sellers | أدوار partner + رصيد | 🔶 |
| 6 | Businesses (+registrations/balances/logistics) | `/stores`: بحث + فلاتر + Available/Active + عمولة + رسوم | ✅ |
| 7 | Drivers (4 أقسام: تسجيلات/جوائز/موظفون) | `/drivers` موافقات + أرباح؛ الجوائز | 🔶 |
| 8 | Users | `/users` بحث/حظر/محفظة | ✅ |
| 9 | Support (تبويبات بحسب النوع + عدادات) | `/support` + رد AI تلقائي | 🔶 |
| 10 | Promotions (أكواد + نظام نقاط) | `/marketing` كوبونات | ✅ |
| 11 | Marketing (حملات، AI email، نشرات، Popups) | `/marketing` + aiSupportReply أساس AI | 🔶 |
| 12 | Notes (كانبان بحسب المدينة) | `/notes` جديد | ✅ |
| 13 | Staff (أدوار إدارية) | `/team` صلاحيات دقيقة يضبطها admin | ✅ أقوى |
| 14 | Charts (12 تقريرًا) | `/` KPIs + إيراد أسبوعي؛ بقية التقارير | 🔶 |
| 15 | Cities (تجميع بالدولة + عدادات) | `/cities` جديد CRUD | ✅ |
| 16 | Extras (روابط/بلاغات) | README + Extras | 🔜 |
| 17 | Training/FAQ (أعمدة بحسب الجمهور) | `/training` جديد CRUD | ✅ |
| 18 | Jobs (تبويبات حالات) | `/jobs` + حالات | ✅ |
| 19 | Logs (سجل تدقيق بتبويبات) | `/logs` جديد — يقرأ مجموعة logs | ✅ |
| 20 | Seetly (اشتراكات) | تكامل خارجي | 🔜 |
| 21 | Settings (21 بطاقة) | `/settings` الأساسية + رسوم/Surge/صيانة | 🔶 |

## عقود مكتملة بانتظار واجهاتها (من لقطات 11/06)
- إعدادات المدينة الكاملة: ساعات، Dynamic fare بمستوى الطلب، 4 شرائح مناطق
  (+5/+20/+15/+30%)، تشبّع، تعطيل عمولة حسب المركبة، إسناد آلي لكل مدينة،
  مستودع Marketplace، تفعيل فئات وشارات لكل مدينة، Extra sell store.
- السائقون: Access/Login منفصلان، جوائز، سائقو رواتب (وقت يومي)، رصيد،
  إشعار/رسالة لكل سائق.
- Marketing settings: Pixel 1/2 + Google Analytics + روابط تحميل ذكية
  (dyar.app/download → المتجر المناسب حسب الجهاز).

## تفاصيل مؤكدة من اللقطات الختامية
- **4 واجهات ويب للنظام** (System Site Links): الموقع العام، White-label
  لكل تاجر، Kiosk للفروع، Fleet للأساطيل — `web/` لدينا يغطي العام،
  والثلاثة الباقية قوالب من نفس الكود ببراميتر متجر.
- **Training**: المحتوى الفعلي بالعربية (ما هو ديار؟ المناطق؟ التسجيل؟
  طرق الدفع؟ الإلغاء؟ تقييم؟ عمولة التاجر؟ ساعات العمل؟...) + أزرار
  فيديوهات السائقين/التجار — تُزرع في `faq` مباشرة.
- **صيغة السجل**: "<الكيان> enabled/blocked/disabled by <اسم> the <تاريخ>
  [until <تاريخ>]" — حقول logs: entity, action, by, at, until?.
- **Seetly**: باقات Advance/Pro/Enterprise بعدّاد مستخدمين ومبلغ + مقاييس
  (Total Income, Seetly fee, Tax, Total Earnings) + جدول أعضاء
  (Membership/Subscription) — تكامل خارجي مؤجل.
- **بطاقة إعدادات مميزة**: Build Applications (توليد APK مخصص) و
  Import data from the web (استيراد قوائم بالـ AI) — لدينا أساس الثانية
  في خطة AI.

## ما تفوقنا به على اللوحة الحالية
ثلاث لغات RTL/LTR فورية + دارك مود + صلاحيات staff مفروضة من الخادم (لا
عرض فقط) + رد دعم AI + تتبّع حي + state machine للطلبات يمنع أي تلاعب.
