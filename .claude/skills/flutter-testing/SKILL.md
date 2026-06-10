---
name: flutter-testing
description: "Write and improve tests for the Dyar Flutter apps — unit, widget, golden, and integration tests, including RTL/Arabic coverage. TRIGGERS: 'اكتب اختبارات', 'أضف اختبارات', 'add tests', 'write tests', 'flutter test', 'اختبر', 'تغطية الاختبارات', 'golden test'. Use when the user asks to add tests, increase coverage, write a widget/unit/integration test, set up golden tests, or test a feature/bugfix in the Dyar mobile apps."
---

# Flutter Testing — اختبارات ديار

اكتب اختبارات فعّالة تمسك الأخطاء الحقيقية لتطبيقات ديار. ابدأ بفهم الكود
المراد اختباره، حدّد الطبقة المناسبة، ثم اكتب اختبارات صغيرة واضحة.

## هرم الاختبارات (ابدأ من الأسفل)

1. **Unit** — منطق الأعمال، الـ models، الـ repositories، الـ notifiers/blocs. الأكثر والأسرع.
2. **Widget** — سلوك الـ widgets/الشاشات بمعزل (`testWidgets` + `pumpWidget`).
3. **Golden** — ثبات الشكل البصري (مهم مع تصميم Dyar Ultra UI) — مع نسخة RTL.
4. **Integration** — تدفقات كاملة (تسجيل دخول → بحث → حجز) على جهاز/محاكي.

## قواعد الكتابة

- بنية AAA: **Arrange / Act / Assert** — واضحة في كل اختبار.
- اسم الاختبار يصف السلوك: `'يعرض رسالة خطأ عند فشل تحميل العقارات'`.
- اختبر السلوك لا التفاصيل الداخلية.
- استخدم `mocktail`/`mockito` للـ repositories والشبكة — لا اتصال شبكة حقيقي.
- لكل bug تُصلحه: اكتب اختباراً يفشل قبل الإصلاح ويمرّ بعده.

## أمثلة هيكلية

### Widget مع حالات البيانات
اختبر دائماً: **تحميل / بيانات / فارغ / خطأ** لكل شاشة تجلب بيانات.
```dart
testWidgets('شاشة العقارات تعرض القائمة عند النجاح', (tester) async {
  when(() => repo.fetch()).thenAnswer((_) async => fakeListings);
  await tester.pumpWidget(wrap(PropertiesScreen(repo: repo)));
  await tester.pumpAndSettle();
  expect(find.byType(PropertyCard), findsNWidgets(fakeListings.length));
});
```

### تغطية RTL (إلزامية لديار)
غلّف الـ widget بـ Directionality واختبر الوضعين:
```dart
Widget wrap(Widget child, {TextDirection dir = TextDirection.rtl}) =>
  MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Directionality(textDirection: dir, child: child),
  );
```

### Golden مع RTL
أنشئ نسختين: `property_card_ar.png` (RTL) و `property_card_en.png` (LTR).

## قائمة ما يجب اختباره في ديار

- [ ] منطق الأسعار/العمولات (partner) — حساسة، اختبر الحالات الحدّية.
- [ ] تدفّق الحجز/الطلب (user) من البداية للنهاية.
- [ ] تحديثات حالة المهمة وتتبّع الموقع (driver).
- [ ] التحقق من النماذج (forms): حقول فارغة، مدخلات خاطئة، أرقام عربية/إنجليزية.
- [ ] التعريب: لا نصوص مفقودة، الأرقام/التواريخ بالصيغة الصحيحة.
- [ ] الصلاحيات: لا يصل user لشاشات partner/driver.

## التشغيل

```bash
flutter test                          # unit + widget
flutter test --update-goldens         # تحديث صور golden
flutter test integration_test/        # integration
flutter test --coverage               # تقرير تغطية
```

## المخرجات

اكتب الاختبارات، شغّلها وتأكّد من نجاحها، وأبلغ بالنتيجة الفعلية (نجح/فشل + المخرجات).
لا تدّعِ النجاح دون تشغيل. اقترح نسبة التغطية المستهدفة للأجزاء الحرجة (المال، الحجز، الأمان).
