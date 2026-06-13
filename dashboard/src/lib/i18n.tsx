// i18n ثلاثي اللغة (عربي/عبري/إنجليزي) مع RTL/LTR تلقائي — وفق صفحة i18n
// في Dyar Ultra UI Handoff. اللغة والثيم محفوظان في localStorage.
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';

export type Lang = 'ar' | 'he' | 'en';
export const RTL_LANGS: Lang[] = ['ar', 'he'];

type Dict = Record<string, { ar: string; he: string; en: string }>;

export const T: Dict = {
  // التنقل الرئيسي
  appName:      { ar: 'ديار', he: 'דיאר', en: 'Dyar' },
  adminPanel:   { ar: 'لوحة التحكم', he: 'לוח בקרה', en: 'Admin Panel' },
  overview:     { ar: 'نظرة عامة', he: 'סקירה כללית', en: 'Overview' },
  orders:       { ar: 'الطلبات', he: 'הזמנות', en: 'Orders' },
  rides:        { ar: 'المشاوير', he: 'נסיעות', en: 'Rides' },
  parcels:      { ar: 'الطرود', he: 'חבילות', en: 'Parcels' },
  bookings:     { ar: 'الحجوزات', he: 'הזמנות מקום', en: 'Bookings' },
  stores:       { ar: 'المتاجر', he: 'חנויות', en: 'Stores' },
  drivers:      { ar: 'السائقون', he: 'נהגים', en: 'Drivers' },
  users:        { ar: 'المستخدمون', he: 'משתמשים', en: 'Users' },
  marketing:    { ar: 'التسويق', he: 'שיווק', en: 'Marketing' },
  finance:      { ar: 'المالية', he: 'כספים', en: 'Finance' },
  jobs:         { ar: 'الوظائف', he: 'משרות', en: 'Jobs' },
  support:      { ar: 'الدعم', he: 'תמיכה', en: 'Support' },
  team:         { ar: 'الفريق والصلاحيات', he: 'צוות והרשאות', en: 'Team & roles' },
  notes:        { ar: 'الملاحظات', he: 'הערות', en: 'Notes' },
  training:     { ar: 'التدريب', he: 'הדרכה', en: 'Training' },
  logs:         { ar: 'سجل العمليات', he: 'יומן פעולות', en: 'Logs' },
  banners:      { ar: 'البانرات', he: 'באנרים', en: 'Banners' },
  marketplace:  { ar: 'بيع وشراء', he: 'קנייה ומכירה', en: 'Marketplace' },
  marketplaceCommission: { ar: 'عمولة السوق %', he: 'עמלת השוק %', en: 'Market commission %' },
  settings:     { ar: 'الإعدادات', he: 'הגדרות', en: 'Settings' },
  features:     { ar: 'الميزات', he: 'תכונות', en: 'Features' },
  featuresHint: { ar: 'أظهر/أخفِ أي ميزة لكل جمهور — التحكم بالمنطقة من صفحة المدن', he: 'הצג/הסתר תכונות לכל קהל — שליטה לפי אזור בעמוד הערים', en: 'Show/hide features per audience — region control in Cities' },
  logout:       { ar: 'تسجيل الخروج', he: 'התנתקות', en: 'Log out' },
  hello:        { ar: 'مرحبًا،', he: 'שלום,', en: 'Hello,' },
  broadcast:    { ar: 'بث الإشعارات', he: 'שידור התראות', en: 'Broadcast' },
  blockedAddresses: { ar: 'العناوين المحظورة', he: 'כתובות חסומות', en: 'Blocked addresses' },

  // عام
  search:       { ar: 'بحث...', he: 'חיפוש...', en: 'Search...' },
  loading:      { ar: 'جارٍ التحميل...', he: 'טוען...', en: 'Loading...' },
  noData:       { ar: 'لا توجد بيانات بعد', he: 'אין נתונים עדיין', en: 'No data yet' },
  save:         { ar: 'حفظ', he: 'שמירה', en: 'Save' },
  cancel:       { ar: 'إلغاء', he: 'ביטול', en: 'Cancel' },
  confirm:      { ar: 'تأكيد', he: 'אישור', en: 'Confirm' },
  actions:      { ar: 'إجراءات', he: 'פעולות', en: 'Actions' },
  status:       { ar: 'الحالة', he: 'סטטוס', en: 'Status' },
  total:        { ar: 'الإجمالي', he: 'סה״כ', en: 'Total' },
  details:      { ar: 'التفاصيل', he: 'פרטים', en: 'Details' },
  approve:      { ar: 'موافقة', he: 'אישור', en: 'Approve' },
  reject:       { ar: 'رفض', he: 'דחייה', en: 'Reject' },
  suspend:      { ar: 'تعليق', he: 'השעיה', en: 'Suspend' },
  block:        { ar: 'حظر', he: 'חסימה', en: 'Block' },
  unblock:      { ar: 'إلغاء الحظر', he: 'ביטול חסימה', en: 'Unblock' },
  active:       { ar: 'نشط', he: 'פעיל', en: 'Active' },
  date:         { ar: 'التاريخ', he: 'תאריך', en: 'Date' },
  name:         { ar: 'الاسم', he: 'שם', en: 'Name' },
  phone:        { ar: 'الهاتف', he: 'טלפון', en: 'Phone' },
  email:        { ar: 'البريد', he: 'אימייל', en: 'Email' },
  city:         { ar: 'المدينة', he: 'עיר', en: 'City' },
  price:        { ar: 'السعر', he: 'מחיר', en: 'Price' },
  rating:       { ar: 'التقييم', he: 'דירוג', en: 'Rating' },
  online:       { ar: 'متصل', he: 'מחובר', en: 'Online' },
  offline:      { ar: 'غير متصل', he: 'לא מחובר', en: 'Offline' },

  // تسجيل الدخول
  loginTitle:   { ar: 'تسجيل الدخول للوحة ديار', he: 'התחברות ללוח דיאר', en: 'Sign in to Dyar Admin' },
  loginSubtitle:{ ar: 'كل شيء بمكان واحد — أدر منظومتك', he: 'הכל במקום אחד — נהל את המערכת', en: 'All you need in one place — manage your platform' },
  password:     { ar: 'كلمة المرور', he: 'סיסמה', en: 'Password' },
  signIn:       { ar: 'دخول', he: 'כניסה', en: 'Sign in' },
  loginError:   { ar: 'بيانات الدخول غير صحيحة', he: 'פרטי התחברות שגויים', en: 'Invalid credentials' },
  adminOnly:    { ar: 'هذه اللوحة للإدارة فقط', he: 'הלוח למנהלים בלבד', en: 'Admins only' },

  // نظرة عامة
  todayOrders:  { ar: 'طلبات اليوم', he: 'הזמנות היום', en: "Today's orders" },
  todayRevenue: { ar: 'إيراد اليوم', he: 'הכנסות היום', en: "Today's revenue" },
  activeDrivers:{ ar: 'سائقون متصلون', he: 'נהגים מחוברים', en: 'Online drivers' },
  pendingStores:{ ar: 'متاجر بانتظار الموافقة', he: 'חנויות ממתינות', en: 'Stores pending approval' },
  last7days:    { ar: 'آخر 7 أيام', he: '7 ימים אחרונים', en: 'Last 7 days' },
  liveOrders:   { ar: 'الطلبات الحية', he: 'הזמנות חיות', en: 'Live orders' },
  revenue:      { ar: 'الإيراد', he: 'הכנסות', en: 'Revenue' },

  // الطلبات
  orderCode:    { ar: 'رقم الطلب', he: 'מס׳ הזמנה', en: 'Order #' },
  customer:     { ar: 'الزبون', he: 'לקוח', en: 'Customer' },
  store:        { ar: 'المتجر', he: 'חנות', en: 'Store' },
  driver:       { ar: 'السائق', he: 'נהג', en: 'Driver' },
  assignDriver: { ar: 'تعيين سائق', he: 'שיוך נהג', en: 'Assign driver' },
  payment:      { ar: 'الدفع', he: 'תשלום', en: 'Payment' },
  items:        { ar: 'الأصناف', he: 'פריטים', en: 'Items' },

  // المتاجر
  commission:   { ar: 'العمولة %', he: 'עמלה %', en: 'Commission %' },
  storeType:    { ar: 'النوع', he: 'סוג', en: 'Type' },
  open:         { ar: 'مفتوح', he: 'פתוח', en: 'Open' },
  closed:       { ar: 'مغلق', he: 'סגור', en: 'Closed' },
  pendingApproval:{ ar: 'بانتظار الموافقة', he: 'ממתין לאישור', en: 'Pending approval' },
  approved:     { ar: 'معتمد', he: 'מאושר', en: 'Approved' },
  suspended:    { ar: 'معلّق', he: 'מושעה', en: 'Suspended' },

  // السائقون
  vehicle:      { ar: 'المركبة', he: 'רכב', en: 'Vehicle' },
  earnings:     { ar: 'الأرباح', he: 'רווחים', en: 'Earnings' },
  documents:    { ar: 'الوثائق', he: 'מסמכים', en: 'Documents' },
  wallet:       { ar: 'المحفظة', he: 'ארנק', en: 'Wallet' },

  // التسويق
  coupons:      { ar: 'الكوبونات', he: 'קופונים', en: 'Coupons' },
  promotions:   { ar: 'العروض', he: 'מבצעים', en: 'Promotions' },
  giftcards:    { ar: 'بطاقات الهدايا', he: 'כרטיסי מתנה', en: 'Gift cards' },
  referrals:    { ar: 'ادعُ واربح', he: 'הזמן והרווח', en: 'Invite & earn' },
  addCoupon:    { ar: 'إضافة كوبون', he: 'הוספת קופון', en: 'Add coupon' },
  code:         { ar: 'الرمز', he: 'קוד', en: 'Code' },
  discount:     { ar: 'الخصم', he: 'הנחה', en: 'Discount' },
  expiry:       { ar: 'الانتهاء', he: 'תפוגה', en: 'Expiry' },
  usage:        { ar: 'الاستخدام', he: 'שימוש', en: 'Usage' },

  // المالية
  transactions: { ar: 'الحركات المالية', he: 'תנועות כספיות', en: 'Transactions' },
  payouts:      { ar: 'التسويات', he: 'תשלומים', en: 'Payouts' },
  type:         { ar: 'النوع', he: 'סוג', en: 'Type' },
  amount:       { ar: 'المبلغ', he: 'סכום', en: 'Amount' },

  // الإعدادات
  serviceFee:   { ar: 'رسوم الخدمة (أغورة)', he: 'דמי שירות (אגורות)', en: 'Service fee (agorot)' },
  defaultCommission:{ ar: 'العمولة الافتراضية %', he: 'עמלת ברירת מחדל %', en: 'Default commission %' },
  maintenanceMode:{ ar: 'وضع الصيانة', he: 'מצב תחזוקה', en: 'Maintenance mode' },
  referralReward:{ ar: 'مكافأة الإحالة (أغورة)', he: 'תגמול הפניה (אגורות)', en: 'Referral reward (agorot)' },
  notConfigured:{ ar: 'لم يتم ربط Firebase بعد — انسخ env. وأدخل المفاتيح', he: 'Firebase לא מחובר — מלא את env.', en: 'Firebase not configured — fill .env' },

  // فئات المدينة (الرؤية في تطبيق المستخدم)
  visibleCategories: { ar: 'الفئات الظاهرة في هذه المدينة', he: 'קטגוריות מוצגות בעיר זו', en: 'Categories visible in this city' },
  visibleCategoriesHint: { ar: 'ما يُعطَّل هنا يختفي من تطبيق المستخدم في هذه المدينة', he: 'מה שמכובה כאן מוסתר באפליקציה בעיר זו', en: 'Disabled items are hidden from the user app in this city' },
  cat_restaurants:  { ar: 'مطاعم', he: 'מסעדות', en: 'Restaurants' },
  cat_groceries:    { ar: 'بقالة', he: 'מכולת', en: 'Groceries' },
  cat_pharmacies:   { ar: 'صيدليات', he: 'בתי מרקחת', en: 'Pharmacies' },
  cat_flowers:      { ar: 'ورود', he: 'פרחים', en: 'Flowers' },
  cat_services:     { ar: 'خدمات', he: 'שירותים', en: 'Services' },
  cat_stores:       { ar: 'متاجر', he: 'חנויות', en: 'Stores' },
  cat_taxi:         { ar: 'تاكسي', he: 'מונית', en: 'Taxi' },
  cat_parcel:       { ar: 'طرود', he: 'חבילות', en: 'Parcels' },
  cat_marketplace:  { ar: 'بيع وشراء', he: 'קנייה ומכירה', en: 'Marketplace' },
  cat_bookings:     { ar: 'حجوزات', he: 'הזמנות מקום', en: 'Bookings' },
  cat_jobs:         { ar: 'وظائف', he: 'משרות', en: 'Jobs' },

  // بث الإشعارات (Broadcast)
  bcTitle:      { ar: 'العنوان', he: 'כותרת', en: 'Title' },
  bcBody:       { ar: 'نص الرسالة', he: 'תוכן ההודעה', en: 'Message body' },
  audience:     { ar: 'الجمهور', he: 'קהל יעד', en: 'Audience' },
  audCustomers: { ar: 'الزبائن', he: 'לקוחות', en: 'Customers' },
  audDrivers:   { ar: 'المندوبون', he: 'שליחים', en: 'Drivers' },
  audPartners:  { ar: 'الأعمال التابعة', he: 'עסקים שותפים', en: 'Partners' },
  audSingle:    { ar: 'مستخدم واحد (UID)', he: 'משתמש יחיד (UID)', en: 'Single user (UID)' },
  send:         { ar: 'إرسال', he: 'שליחה', en: 'Send' },
  sent:         { ar: 'أُرسل ✓', he: 'נשלח ✓', en: 'Sent ✓' },
  sentBy:       { ar: 'أرسلها', he: 'נשלח ע״י', en: 'Sent by' },
  history:      { ar: 'السجل', he: 'היסטוריה', en: 'History' },

  // العناوين المحظورة (مكافحة الاحتيال)
  addressLine:  { ar: 'العنوان', he: 'כתובת', en: 'Address' },
  reason:       { ar: 'السبب', he: 'סיבה', en: 'Reason' },
  addAddress:   { ar: 'إضافة عنوان', he: 'הוספת כתובת', en: 'Add address' },
  blockedAddressesHint: {
    ar: 'أي طلب يحتوي عنوانه على سطر محظور يُرفض تلقائيًا — مكافحة الاحتيال',
    he: 'כל הזמנה שכתובתה מכילה שורה חסומה נדחית אוטומטית — מניעת הונאות',
    en: 'Any order whose address contains a blocked line is rejected automatically — anti-fraud',
  },

  // نظام النقاط (الولاء)
  loyalty:      { ar: 'نظام النقاط', he: 'מערכת נקודות', en: 'Loyalty points' },
  loyaltyEnabled: { ar: 'تفعيل النقاط', he: 'הפעלת נקודות', en: 'Enable points' },
  earnPerShekel:{ ar: 'نقاط لكل ₪1', he: 'נקודות לכל ₪1', en: 'Points per ₪1' },
  redeemRate:   { ar: 'أغورة لكل نقطة (استبدال)', he: 'אגורות לנקודה (פדיון)', en: 'Agorot per point (redeem)' },
  points:       { ar: 'النقاط', he: 'נקודות', en: 'Points' },

  // جوائز المندوبين
  driverPrizes: { ar: 'جوائز المندوبين', he: 'פרסי שליחים', en: 'Driver prizes' },
  targetDeliveries: { ar: 'هدف التوصيلات', he: 'יעד משלוחים', en: 'Deliveries target' },
  bonus:        { ar: 'المكافأة (أغورة)', he: 'בונוס (אגורות)', en: 'Bonus (agorot)' },
  addPrize:     { ar: 'إضافة جائزة', he: 'הוספת פרס', en: 'Add prize' },
  monthlyEarningsReport: { ar: 'تقرير الأرباح الشهري', he: 'דו״ח רווחים חודשי', en: 'Monthly earnings report' },

  // تفعيل/تعطيل فئة في كل المدن
  bulkCategoryToggle: { ar: 'تفعيل/تعطيل فئة في كل المدن', he: 'הפעלה/כיבוי קטגוריה בכל הערים', en: 'Toggle category in all cities' },
  category:     { ar: 'الفئة', he: 'קטגוריה', en: 'Category' },
  enable:       { ar: 'تفعيل', he: 'הפעלה', en: 'Enable' },
  disable:      { ar: 'تعطيل', he: 'כיבוי', en: 'Disable' },
  apply:        { ar: 'تطبيق', he: 'החלה', en: 'Apply' },

  // إعدادات عامة موسّعة
  platformName: { ar: 'اسم المنصة', he: 'שם הפלטפורמה', en: 'Platform name' },
  brandColor:   { ar: 'لون الهوية', he: 'צבע מותג', en: 'Brand color' },
  currency:     { ar: 'العملة', he: 'מטבע', en: 'Currency' },
  phoneCode:    { ar: 'رمز الهاتف الدولي', he: 'קידומת בינלאומית', en: 'Phone code' },
  mapsEnabled:  { ar: 'تفعيل الخرائط', he: 'הפעלת מפות', en: 'Maps enabled' },
  newUserGift:  { ar: 'هدية المستخدم الجديد ₪', he: 'מתנת משתמש חדש ₪', en: 'New user gift ₪' },

  // التقارير
  reports:      { ar: 'التقارير', he: 'דוחות', en: 'Reports' },
  topDrivers:   { ar: 'أفضل المندوبين', he: 'שליחים מובילים', en: 'Top drivers' },
  salesByStore: { ar: 'المبيعات حسب النشاط', he: 'מכירות לפי עסק', en: 'Sales by business' },
  timeAnalysis: { ar: 'تحليل الأوقات', he: 'ניתוח שעות', en: 'Time analysis' },
  couponsUsed:  { ar: 'الأكواد المستخدمة', he: 'קודים בשימוש', en: 'Codes used' },
  deliveries:   { ar: 'التوصيلات', he: 'משלוחים', en: 'Deliveries' },

  // التسويق — نمط Hub
  hubCoupons:   { ar: 'أكواد خصم بشروط وحدود استخدام', he: 'קודי הנחה עם תנאים', en: 'Discount codes with rules & limits' },
  hubPromos:    { ar: 'عروض ترويجية تظهر في التطبيق', he: 'מבצעים המוצגים באפליקציה', en: 'Promotions shown in the app' },
  hubGiftcards: { ar: 'بطاقات هدايا برصيد قابل للصرف', he: 'כרטיסי מתנה עם יתרה', en: 'Gift cards with redeemable balance' },
  hubBanners:   { ar: 'لافتات بكل المواضع (ستوري/رئيسية/فئات)', he: 'באנרים בכל המיקומים', en: 'Banners in all placements' },
  hubBroadcast: { ar: 'إشعارات دفع للزبائن والمندوبين والأعمال', he: 'התראות פוש לכל הקהלים', en: 'Push notifications to all audiences' },

  // صوت ديار
  dyarVoice:     { ar: 'صوت ديار', he: 'הקול של דיאר', en: 'Dyar Voice' },
  dyarVoiceHint: { ar: 'أصوات بشرية عربية من ElevenLabs — شخصية لكل دور، وتُستبدل بلصق Voice ID آخر', he: 'קולות אנושיים בערבית — אישיות לכל תפקיד', en: 'Human Arabic voices — a persona per role, replace by pasting another Voice ID' },
  voiceEnabled:  { ar: 'تفعيل الصوت', he: 'הפעלת קול', en: 'Enable voice' },
  voiceSupport:  { ar: 'الدعم — الرد الأساسي', he: 'תמיכה — מענה ראשי', en: 'Support — primary' },
  voiceSupport2: { ar: 'الدعم — استرداد واعتذار', he: 'תמיכה — החזרים', en: 'Support — refunds' },
  voiceDriver:   { ar: 'تنبيهات السائق', he: 'התראות נהג', en: 'Driver alerts' },
  voiceAnnounce: { ar: 'الإعلانات الرسمية', he: 'הודעות רשמיות', en: 'Announcements' },
  voiceAgentId:  { ar: 'الوكيل الصوتي الحي (Agent ID)', he: 'סוכן קולי חי (Agent ID)', en: 'Live voice agent (Agent ID)' },
  voiceAgentHint:{ ar: 'محادثة فورية طبيعية — أنشئه باتباع docs/VOICE-AGENT.md والصق المعرف هنا', he: 'שיחה חיה — ראה docs/VOICE-AGENT.md', en: 'Real-time conversation — create per docs/VOICE-AGENT.md and paste the ID' },

  // الفريق — أدوار جاهزة
  csRole:     { ar: 'دور خدمة العملاء', he: 'תפקיד שירות לקוחות', en: 'Customer service role' },
  clearPerms: { ar: 'مسح الصلاحيات', he: 'איפוס הרשאות', en: 'Clear permissions' },

  // الحِمية والتصديق (حلال/كوشير)
  dietaryFilter: { ar: 'حِمية/تصديق', he: 'תזונה/אישור', en: 'Diet/Cert' },
  verified:      { ar: 'موثّق', he: 'מאומת', en: 'Verified' },

  // الدعم — عدّادات حية
  activeOrders: { ar: 'طلبات نشطة', he: 'הזמנות פעילות', en: 'Active orders' },
  messages:     { ar: 'رسائل', he: 'הודעות', en: 'Messages' },

  // المتاجر — نسخ النشاط
  duplicate:    { ar: 'نسخ', he: 'שכפול', en: 'Duplicate' },

  // حالات الطلب
  st_pending:   { ar: 'بانتظار', he: 'ממתין', en: 'Pending' },
  st_accepted:  { ar: 'مقبول', he: 'התקבל', en: 'Accepted' },
  st_preparing: { ar: 'قيد التحضير', he: 'בהכנה', en: 'Preparing' },
  st_ready:     { ar: 'جاهز', he: 'מוכן', en: 'Ready' },
  st_assigned:  { ar: 'مُعيَّن', he: 'שויך', en: 'Assigned' },
  st_picked_up: { ar: 'مُستلَم', he: 'נאסף', en: 'Picked up' },
  st_on_the_way:{ ar: 'في الطريق', he: 'בדרך', en: 'On the way' },
  st_delivered: { ar: 'تم التوصيل', he: 'נמסר', en: 'Delivered' },
  st_cancelled: { ar: 'ملغي', he: 'בוטל', en: 'Cancelled' },
  st_rejected:  { ar: 'مرفوض', he: 'נדחה', en: 'Rejected' },
  st_approved:  { ar: 'معتمد', he: 'מאושר', en: 'Approved' },
  st_sold:      { ar: 'مُباع', he: 'נמכר', en: 'Sold' },

  // التوظيف (المتقدمون + CV)
  applicants:   { ar: 'المتقدمون', he: 'מועמדים', en: 'Applicants' },
  cv:           { ar: 'السيرة الذاتية', he: 'קורות חיים', en: 'CV' },
  shortlist:    { ar: 'ترشيح', he: 'רשימה מצומצמת', en: 'Shortlist' },
  hire:         { ar: 'توظيف', he: 'גיוס', en: 'Hire' },
  noApplicants: { ar: 'لا متقدمين بعد', he: 'אין מועמדים עדיין', en: 'No applicants yet' },
  st_new:        { ar: 'جديد', he: 'חדש', en: 'New' },
  st_shortlisted:{ ar: 'مرشَّح مبدئيًا', he: 'ברשימה מצומצמת', en: 'Shortlisted' },
  st_hired:      { ar: 'تم التوظيف', he: 'התקבל', en: 'Hired' },
};

interface I18nState {
  lang: Lang;
  dir: 'rtl' | 'ltr';
  dark: boolean;
  t: (key: string) => string;
  setLang: (l: Lang) => void;
  toggleDark: () => void;
}

const I18nContext = createContext<I18nState>(null as unknown as I18nState);

export function I18nProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>(() => (localStorage.getItem('dyar.lang') as Lang) || 'ar');
  const [dark, setDark] = useState(() => localStorage.getItem('dyar.dark') === '1');

  const dir: 'rtl' | 'ltr' = RTL_LANGS.includes(lang) ? 'rtl' : 'ltr';

  useEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = dir;
    localStorage.setItem('dyar.lang', lang);
  }, [lang, dir]);

  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark);
    localStorage.setItem('dyar.dark', dark ? '1' : '0');
  }, [dark]);

  const t = (key: string) => T[key]?.[lang] ?? key;

  return (
    <I18nContext.Provider value={{ lang, dir, dark, t, setLang: setLangState, toggleDark: () => setDark((d) => !d) }}>
      {children}
    </I18nContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export const useI18n = () => useContext(I18nContext);
