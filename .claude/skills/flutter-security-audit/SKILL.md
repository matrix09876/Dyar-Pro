---
name: flutter-security-audit
description: "Security audit for the Dyar Flutter apps based on OWASP MASVS — secure storage, auth tokens, API keys, network/TLS, permissions, deep links, and PII protection. TRIGGERS: 'فحص أمني', 'تدقيق أمني', 'security audit', 'افحص الأمان', 'flutter security', 'هل التطبيق آمن'. Use when the user asks to audit security, check for vulnerabilities, review auth/token handling, secrets, or data protection in the Dyar mobile apps. This is for DEFENSIVE security of the user's own app."
---

# Flutter Security Audit — تدقيق أمان ديار

تدقيق أمني دفاعي لتطبيقات ديار (user/partner/driver) وفق **OWASP MASVS**.
ابدأ بمسح المشروع بحثاً عن الأنماط الخطرة، ثم رتّب النتائج حسب الخطورة.

## المسح الأولي (شغّله أولاً)

ابحث في الكود عن:
- أسرار مكشوفة: `apiKey`, `secret`, `password`, `token`, `Bearer `, مفاتيح Google/Firebase، روابط قواعد بيانات.
- تخزين غير آمن: `SharedPreferences` لقيم حسّاسة.
- `http://` (غير مشفّر) بدل `https://`.
- `print(` / `debugPrint(` لبيانات المستخدم.
- تعطيل التحقق: `badCertificateCallback`, `allowBadCertificates`, تجاوز TLS.

## محاور التدقيق

### 1. التخزين (Storage — MASVS-STORAGE)
- [ ] الـ tokens / refresh tokens / PII في `flutter_secure_storage` (Keychain/Keystore).
- [ ] لا بيانات حسّاسة في `SharedPreferences`، logs، أو ملفات نصية.
- [ ] مسح البيانات الحسّاسة عند تسجيل الخروج.
- [ ] لا cache للشاشات الحسّاسة (دفع/هوية) — `secureFlag` على Android ضدّ لقطات الشاشة.

### 2. المصادقة والجلسات (Auth — MASVS-AUTH)
- [ ] انتهاء صلاحية الـ token + آلية refresh آمنة.
- [ ] دعم البصمة/Face ID (`local_auth`) للعمليات الحسّاسة (الدفع، تحويل الأرباح في partner).
- [ ] منع إعادة استخدام الجلسة بعد تسجيل الخروج.
- [ ] التحقق من الصلاحيات على الخادم لا على العميل فقط (خاصة فصل أدوار user/partner/driver).

### 3. الشبكة (Network — MASVS-NETWORK)
- [ ] HTTPS فقط، لا استثناءات `cleartextTraffic`.
- [ ] **Certificate pinning** للـ API الأساسي (حسّاس لتطبيق دفع/عقاري).
- [ ] لا تعطيل التحقق من الشهادات في أي بيئة تُشحن.
- [ ] فحّص استجابات الخادم قبل الثقة بها (لا تثق ببيانات العميل).

### 4. المفاتيح والأسرار (Secrets)
- [ ] لا مفاتيح في الكود/git — استخدم `--dart-define`/متغيرات بيئة + ملفات مُستثناة في `.gitignore`.
- [ ] مفاتيح Maps/الدفع مقيّدة (restricted) على مستوى المنصة + bundle id.
- [ ] فصل مفاتيح dev/prod.

### 5. المنصّة (Platform — MASVS-PLATFORM)
- [ ] صلاحيات Android/iOS بالحدّ الأدنى (الموقع للـ driver فقط عند الحاجة، الكاميرا عند الحاجة).
- [ ] **Deep links / App Links** مُتحقّق منها — لا تنفّذ إجراءات حسّاسة من رابط دون تأكيد.
- [ ] حماية WebView (إن وُجد): تعطيل JS غير الضروري، فحص الـ URLs.

### 6. الكود والمقاومة (Code — MASVS-RESILIENCE)
- [ ] تشويش/تصغير (R8/ProGuard) في الإصدار النهائي.
- [ ] لا logs تشخيصية في الـ release.
- [ ] فحص الـ root/jailbreak للعمليات المالية (اختياري حسب الحساسية).

## المخرجات

جدول: **الثغرة | الخطورة (حرِجة/عالية/متوسطة/منخفضة) | الموقع `file:line` | الإصلاح المقترح**.
ثم خطة إصلاح مرتّبة بالأولوية. ركّز على الثغرات الحقيقية القابلة للاستغلال، لا الإنذارات النظرية.

> هذا تدقيق دفاعي لتطبيق المستخدم نفسه. لا تنتج أكواد هجومية أو تجاوز حماية أنظمة الآخرين.
