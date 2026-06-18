# Decision Log

### [2026-06-15] توحيد فرع العمل
- **السياق:** الكود الكامل كان على `diyar-app-dashboard-scope`، وفرعي يحوي المهارات فقط.
- **القرار:** دمج فرع الكود إلى `claude/project-inspection-tools-dquhn1` (`-X theirs`).
- **المبرّر:** فرعي مجموعة جزئية؛ الدمج لا يفقد شيئًا ويوحّد العمل.

### [2026-06-17] بناء APK عبر GitHub Actions لا محليًا
- **السياق:** حاوية Claude بلا Flutter/Android SDK ولا مجلّد android/.
- **القرار:** workflows تبني على Actions (`flutter create` يولّد android/ في CI).
- **المبرّر:** أوثق طريقة لسقالة صحيحة مطابقة لنسخة Flutter.

### [2026-06-17] applicationId = com.dyar.user
- **القرار:** تثبيت applicationId و minSdk=23 عبر sed في CI.
- **المبرّر:** يجب أن يطابق اسم الحزمة المسجّل في Firebase (google-services.json).

### [2026-06-17] وضع المعاينة DYAR_DEMO
- **السياق:** APK كامل يحتاج سرّ Firebase (خطوة المالك)؛ أردنا APK للتجربة فورًا.
- **القرار:** `kDyarDemo` يهيّئ Firebase بإعدادات **وهمية** (لا يتعطّل، الشبكة تفشل بصمت).
- **المبرّر:** أكثر أمانًا من تخطّي التهيئة (يمنع أخطاء "No Firebase App").

### [2026-06-17] تثبيت Flutter 3.44.2 في الـ CI
- **المبرّر:** النسخة التي تحقّقنا منها (Kotlin DSL) — قابلية تكرار وتفادي مفاجآت DSL.

### [2026-06-18] إضافة memory-bank (تكييف RooFlow)
- **السياق:** المالك طلب إضافة "RooFlow".
- **القرار:** تكييف مفهوم Memory Bank كـ skill أصلي لـ Claude Code (لا نسخ Roo حرفيًا).
- **المبرّر:** RooFlow مبني على Roo Code ولا يعمل في Claude؛ المفهوم قابل للتكييف.
