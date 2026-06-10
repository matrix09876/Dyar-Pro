---
name: flutter-code-review
description: "Review Flutter/Dart code for correctness, performance, architecture, and idiomatic style — tailored to the Dyar multi-app project (user/partner/driver). TRIGGERS: 'راجع الكود', 'راجع كود فلاتر', 'review flutter', 'flutter code review', 'فحص الكود', 'مراجعة كود'. Use when the user asks to review Dart/Flutter code, a widget, a screen, a PR, or a diff for quality and bugs. Covers widget rebuilds, state management, null-safety, async/await, error handling, RTL correctness, and separation of concerns."
---

# Flutter Code Review — مراجعة كود ديار

راجع كود Flutter/Dart بعمق وحسب أولويات مشروع ديار (4 تطبيقات تشترك في core).
ابدأ دائماً بقراءة الكود المتغيّر (diff أو الملفات المذكورة)، ثم راجع حسب القوائم أدناه.

## ترتيب المراجعة

1. **الصحّة (Correctness) أولاً** — أخطاء منطقية، null-safety، حالات حدّية، async.
2. **المعمارية** — فصل الطبقات (UI / state / data)، إعادة الاستخدام عبر `dyar_core`.
3. **الأداء** — إعادة بناء الـ widgets، `const`، القوائم الطويلة.
4. **RTL والتعريب** — صحّة الاتجاه والنصوص العربية.
5. **الأناقة (Style)** — تسمية، تكرار، تبسيط.

أخرج النتائج مرتّبة: 🔴 حرِج / 🟡 مهم / 🟢 تحسين، مع `file:line` ومقترح إصلاح ملموس.

## قائمة فحص الصحّة (Correctness)

- [ ] لا `!` (null assertion) على قيم قد تكون null؛ استخدم `?.`, `??`, أو فحص صريح.
- [ ] كل `Future` فيه `await` أو معالجة صريحة؛ لا `unawaited` غير مقصود.
- [ ] `try/catch` حول استدعاءات الشبكة/الـ IO، مع رسائل خطأ للمستخدم بالعربية.
- [ ] `dispose()` لكل `Controller` / `StreamSubscription` / `FocusNode` / `AnimationController`.
- [ ] `mounted` يُفحص قبل `setState`/استخدام `context` بعد `await`.
- [ ] التعامل مع حالات: تحميل / فارغ / خطأ / نجاح في كل شاشة بيانات.

## قائمة فحص المعمارية

- [ ] لا منطق أعمال داخل `build()` — انقله إلى ViewModel/Notifier/Bloc.
- [ ] لا استدعاءات شبكة مباشرة من الـ widget — عبر repository/service.
- [ ] الكود المشترك بين user/partner/driver في حزمة `dyar_core`/`dyar_ui` لا منسوخ.
- [ ] النماذج (models) فيها `fromJson/toJson` وتتعامل مع حقول مفقودة بأمان.
- [ ] فصل واضح: presentation ← domain ← data.

## قائمة فحص الأداء (سريعة)

- [ ] `const` على كل widget ثابت.
- [ ] القوائم الطويلة عبر `ListView.builder`/`SliverList` لا `Column` داخل `ListView`.
- [ ] لا عمليات ثقيلة (json parsing كبير، حلقات) داخل `build()` — استخدم `compute`/isolate.
- [ ] الصور عبر `cached_network_image` مع أبعاد محدّدة.
- [ ] تقليل نطاق إعادة البناء (`Consumer`/`Selector` بدل إعادة بناء الشجرة كلها).

## قائمة فحص RTL والتعريب (حرِج لديار)

- [ ] `EdgeInsetsDirectional` / `AlignmentDirectional` بدل `EdgeInsets.only(left/right)`.
- [ ] `start`/`end` بدل `left`/`right`.
- [ ] أيقونات الاتجاه (السهم/الرجوع) تنعكس مع RTL (`Directionality`/أيقونات directional).
- [ ] كل النصوص الظاهرة من ملفات الترجمة (`AppLocalizations`)، لا نصوص ثابتة مكتوبة.
- [ ] الأرقام والتواريخ والعملة عبر `intl` (`NumberFormat`, `DateFormat`) حسب اللغة.

## قائمة فحص الأمان (تمرير سريع — للتعمّق استخدم flutter-security-audit)

- [ ] لا مفاتيح/أسرار في الكود.
- [ ] الـ tokens في `flutter_secure_storage` لا `SharedPreferences`.
- [ ] لا `print` لبيانات حسّاسة.

## المخرجات

اختم بملخّص: أهم 3 مشاكل يجب إصلاحها الآن، وهل الكود جاهز للدمج أم لا.
عند الطلب طبّق الإصلاحات مباشرة (أو وجّه المستخدم لاستخدام `/code-review --fix`).
