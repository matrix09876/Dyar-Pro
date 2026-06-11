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

## ما تفوقنا به على اللوحة الحالية
ثلاث لغات RTL/LTR فورية + دارك مود + صلاحيات staff مفروضة من الخادم (لا
عرض فقط) + رد دعم AI + تتبّع حي + state machine للطلبات يمنع أي تلاعب.
