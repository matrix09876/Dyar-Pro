# 📦 ديار v10 — حزمة التسليم للفريق البرمجي (Developer Handoff)

> **الحالة:** الكود **مكتمل وجاهز** — Flutter (3 تطبيقات) + خلفية Firebase
> + لوحة تحكم + نظام تصميم Figma. آخر تدقيق شامل للمستودع: **GO — صفر
> blockers** (كل البناءات والاختبارات الآلية خضراء، والفهارس والقواعد مكتملة).
> هذا المستند هو نقطة البداية. التاريخ: 2026-06-13.

---

## 1) ما الذي تستلمونه

| المكوّن | المسار | التقنية | الحالة |
|---|---|---|---|
| تطبيق الزبون | `apps/user` | Flutter (iOS+Android) | مكتمل |
| تطبيق السائق | `apps/driver` | Flutter | مكتمل |
| تطبيق التاجر | `apps/partner` | Flutter | مكتمل |
| حزم مشتركة | `packages/dyar_core` · `packages/dyar_ui` | Flutter (melos) | مكتمل |
| لوحة التحكم | `dashboard` | React 18 + Vite + TS + Tailwind | مكتمل + منشور |
| الخلفية | `backend/functions` | Cloud Functions (TypeScript) | مكتمل + منشور |
| القواعد والفهارس | `backend/firestore.rules` · `firestore.indexes.json` | Firestore | مكتمل |
| التصميم | `docs/design/` + ملف Figma «Dyar Ultra UI» | Figma | مرجع التصميم |

**عربية أولًا (RTL) + عبري + إنجليزي** — تعريب ثلاثي كامل في كل الواجهات.

### الميزات الرائدة الثلاث (مكتملة)
1. **AI Shopping Assistant** — المستخدم يكتب نيّته، فيبني الـAI سلة من متجر
   حقيقي بأصناف وأسعار مُتحقَّقة خادميًا (لا اختراع منتجات/أسعار).
2. **الخرائط الحية + منتقي الدبوس بدقة المتر** — مُسيّجة بعلم بناء حتى إضافة
   مفتاح Google Maps (بديل أنيق يعمل قبلها).
3. **B2B RFQ (طلب عرض سعر)** — تاجر يطلب، مورد يسعّر، عمولة ديار محسوبة
   ومحفوظة خادميًا (حماية العمولة) + صفحة مراقبة في اللوحة.

بالإضافة إلى: التوصيل/الطعام/البقالة/الصيدلية، التاكسي، الطرود، الخدمات،
السوق C2C، الوظائف، المحفظة/الولاء/الإحالة، **ديار Meals** (بدل وجبات
الشركات نمط 10bis)، **الوكيل الصوتي «تاليا»**، الستوري، الحلال/الكوشير.

---

## 2) المستودع والفرع

- **المستودع:** `https://github.com/matrix09876/Dyar-Pro`
- **الفرع الجاهز:** `claude/diyar-app-dashboard-scope-byq00p`
- **الاستنساخ:**
  ```bash
  git clone https://github.com/matrix09876/Dyar-Pro.git
  cd Dyar-Pro
  git checkout claude/diyar-app-dashboard-scope-byq00p
  ```

---

## 3) التشغيل والبناء

| المهمة | الأمر |
|---|---|
| اللوحة (تطوير) | `cd dashboard && npm install && npm run dev` |
| اللوحة (بناء) | `cd dashboard && npm run build` |
| الدوال (بناء) | `cd backend/functions && npm install && npm run build` |
| تطبيقات Flutter | `dart pub global activate melos && melos bootstrap` ثم `cd apps/user && flutter run` |
| تحليل Flutter | `melos run analyze` (أو `cd apps/<app> && flutter analyze`) |
| اختبارات Flutter | `flutter test` داخل كل تطبيق/حزمة |
| اختبارات القواعد | `cd backend && firebase emulators:exec --only firestore 'cd tests && node rules.test.mjs'` |

> **مهم:** البيئة التي حُضِّر فيها الكود لا تحوي Flutter SDK، لذا **لم يُشغَّل
> `flutter analyze`/`flutter test` على تطبيقات الموبايل بعد** — شغّلوها على
> أجهزتكم كأول خطوة (الرموز والمفاتيح والأيقونات تحقّقنا منها يدويًا).

---

## 4) المفاتيح والأسرار المطلوبة — قبل الإطلاق

> **المرجع الكامل خطوة بخطوة:** `docs/KEYS-RUNBOOK.md`

**لا أسرار في الكود إطلاقًا** — كلها عبر Firebase Functions Secrets أو `.env`:

| المفتاح | الأين | الغرض | الحالة |
|---|---|---|---|
| إعدادات Firebase | `dashboard/.env` (Web config عام) | اللوحة + التطبيقات | منشور (dyar-ai) |
| `EASYCARD_*` | Functions Secrets | الدفع VISA/Bit | **مجرَّب حيًّا ✓ (200/201)** |
| `ANTHROPIC_API_KEY` | Functions Secret | المساعد الذكي + الدعم | **يجب تدويره** |
| `ELEVENLABS_API_KEY` | Functions Secret | الوكيل الصوتي «تاليا» | **يجب تدويره** |
| `SUPPORT_HOOK_SECRET` | Functions Secret | خطافات الدعم | مضبوط |
| Google Maps (Android/iOS) | AndroidManifest + AppDelegate | الخرائط الحية | **مطلوب** (`KEYS-RUNBOOK §4`) |
| Stripe (اختياري) | Functions Secrets | دفع بطاقات بديل | اختياري |

> ⚠️ **تدوير المفاتيح:** أي مفاتيح ظهرت سابقًا في محادثات/سجلات يجب
> **تدويرها (إلغاء وإصدار جديد)** قبل الإطلاق — خصوصًا ElevenLabs وAnthropic.

---

## 5) النشر (Deploy)

مشروع Firebase: **`dyar-ai`** · المنطقة **`me-west1`** · خطة Blaze · Node 22.

```bash
cd backend
# 1) القواعد + الفهارس + التخزين  (الفهارس الجديدة لازمة — RFQ + orders)
firebase deploy --only firestore:rules,firestore:indexes,storage
# 2) الدوال
firebase deploy --only functions
# 3) اللوحة (Hosting)
cd ../dashboard && npm run build && firebase deploy --only hosting
```

> بناء الفهارس على الإنتاج قد يستغرق دقائق — تحقّقوا من اكتمالها في
> Firebase Console → Firestore → Indexes قبل اختبار شاشات التتبّع/السائقين.

---

## 6) ✅ قائمة التحقق قبل الإطلاق (Pre-Launch Checklist)

- [ ] **اللغة (i18n):** افتحوا كل تطبيق بالعربية ثم العبرية ثم الإنجليزية —
      تأكدوا من RTL/LTR الصحيح وعدم وجود نص غير مترجم. (المرجع:
      `packages/dyar_core/lib/src/i18n/strings.dart` + `dashboard/src/lib/i18n.tsx`).
- [ ] **الدفع EasyCard:** اختبروا دورة دفع كاملة (VISA + Bit) على الإنتاج —
      الدالة `createEasycardPayment` + الـ webhook `easycardWebhook` (مجرَّبة حيًّا،
      تحتاج فقط مفاتيح الإنتاج النهائية في Secrets).
- [ ] **الدعم + الوكيل الصوتي:** جرّبوا «تاليا» (`docs/VOICE-AGENT.md`) وردود
      الدعم الآلية، وتأكدوا من تصعيد المحادثة لموظف بشري عند اللزوم.
- [ ] **الخرائط:** أضيفوا مفتاح Google Maps وابنوا بـ
      `--dart-define=DYAR_MAPS=true` ثم اختبروا التتبّع الحي ومنتقي العنوان.
- [ ] **App Check:** فعّلوا Play Integrity / App Attest / reCAPTCHA
      (`KEYS-RUNBOOK §8`) ثم Enforce على Firestore وFunctions.
- [ ] **Flutter analyze + tests:** نظيفة على أجهزتكم قبل بناء الإصدار.
- [ ] **تدوير المفاتيح المكشوفة** (ElevenLabs / Anthropic).
- [ ] **الأدوار:** أنشئوا أول أدمن عبر `claimFirstAdmin` (محمي بـ
      `SUPPORT_HOOK_SECRET`، يقفل نفسه بعد أول استخدام).

---

## 7) الإضافات الموجودة لدينا والمطلوب تفعيلها/سدّها

هذه **مبنية في الكود** وتحتاج فقط مفتاحًا أو تفعيلًا تشغيليًا:

1. **الخرائط الحية + منتقي الدبوس** — جاهزة، مُسيّجة بـ `kMapsEnabled`
   (`packages/dyar_core/lib/src/utils/links.dart`). فعّلوها بمفتاح Maps.
2. **App Check** — موثّق وجاهز للتفعيل، لم يُفرَض بعد.
3. **تدوير المفاتيح** — إجراء أمني مطلوب.
4. **onUserCreate (Identity Platform)** — دالة موجودة، تحتاج تفعيل Identity
   Platform في الكونسول (غير حاجبة).
5. **(مستقبلي) تكامل Cibus** لبدل الوجبات — خارج النطاق الحالي.

---

## 8) التوثيق المرجعي (في `docs/`)

| الملف | المحتوى |
|---|---|
| `KEYS-RUNBOOK.md` | **ابدأوا هنا** — كل المفاتيح والنشر خطوة بخطوة |
| `DATA-MODEL.md` | عقد البيانات (المجموعات والحقول) |
| `SYSTEM-VERIFICATION.md` | مصفوفة التحقق |
| `READINESS-GATE.md` | بوابة الجاهزية للإطلاق |
| `FIGMA-ULTRA-UI-VERIFICATION.md` | مطابقة التصميم بالكود |
| `VOICE-AGENT.md` | إعداد الوكيل الصوتي «تاليا» |
| `ROLES.md` | الأدوار والصلاحيات |
| `design/FIGMA-DYAR-PRO-V10.md` · `design/FIGMA-PROMPTS.md` | مراجع التصميم |
| `.claude/agents/dyar-inspector.md` | فاحص آلي — شغّلوه قبل كل دمج/إطلاق |

---

## 9) نتيجة التدقيق الآلي (آخر تشغيل)

- بناء الدوال (`tsc`): ✅ · بناء اللوحة (`vite`): ✅
- اختبارات قواعد Firestore: **39/39 ✅**
- اختبارات محرك العمولة: **10/10 ✅** · عمولة B2B: **5/5 ✅**
- مسح الأسرار على كل الملفات: **لا أسرار مكشوفة ✅**
- قواعد الأمان: لا كتابة عميل غير مصرّح بها على أي مجموعة حسّاسة ✅
- **الحكم: GO — جاهز للتسليم (بعد إكمال قائمة §6 التشغيلية).**

> Flutter analyze/tests للموبايل = مهمة أولى على أجهزتكم (لا SDK في بيئة التحضير).
