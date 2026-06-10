---
name: flutter-performance
description: "Diagnose and fix performance issues (jank, dropped frames, slow startup, memory) in the Dyar Flutter apps. TRIGGERS: 'حسّن الأداء', 'التطبيق بطيء', 'optimize performance', 'flutter performance', 'jank', 'تقطيع', 'بطء', 'تحسين السرعة', 'الذاكرة'. Use when the user reports lag/jank/slow scrolling/slow startup/high memory, or asks to profile or optimize the Dyar mobile apps for 60/120fps smoothness."
---

# Flutter Performance — تحسين أداء ديار

الهدف: تجربة سلسة 60/120fps لتطبيقات ديار، خصوصاً القوائم الطويلة (العقارات)
والخرائط (driver/user). شخّص أولاً بالأدوات، ثم أصلح السبب الجذري لا الأعراض.

## التشخيص أولاً (لا تخمّن)

```bash
flutter run --profile          # ملف الأداء الحقيقي، لا debug
flutter run --profile --trace-skia
```
- استخدم **DevTools → Performance** لرصد الإطارات التي تتجاوز 16ms (8ms لـ 120Hz).
- **CPU Profiler** لإيجاد الدوال الثقيلة.
- **Memory** لرصد التسريبات (controllers/listeners غير مُتخلَّص منها).
- فعّل `Performance overlay` لرؤية jank الـ UI/raster مباشرة.

## أشيع أسباب الـ Jank في تطبيق عقاري

### 1. إعادة بناء مفرطة (Rebuilds)
- [ ] أضف `const` لكل widget ثابت.
- [ ] قلّص نطاق إعادة البناء: `Consumer`/`Selector`/`context.select` بدل بناء الشجرة كاملة.
- [ ] لا تُنشئ كائنات/دوال داخل `build()` تتغيّر كل مرة.
- [ ] افصل الأجزاء المتحرّكة في widgets مستقلة.

### 2. القوائم (الأهم — قوائم العقارات)
- [ ] `ListView.builder`/`GridView.builder`/`SliverList` لا `Column` داخل `SingleChildScrollView`.
- [ ] حدّد `itemExtent`/`prototypeItem` عند ثبات الارتفاع (يسرّع التمرير كثيراً).
- [ ] خفّف بطاقة العقار: تجنّب shadows/blur/opacity المتراكمة، استخدم `RepaintBoundary`.

### 3. الصور (صور العقارات كثيرة)
- [ ] `cached_network_image` مع `memCacheWidth/Height` بأبعاد العرض الفعلية لا الأصلية.
- [ ] لا تُحمّل صوراً بدقّة 4K في بطاقة 200px.
- [ ] placeholder خفيف + تحميل تدريجي.

### 4. الخرائط (driver/user)
- [ ] حدّد عدد الـ markers المعروضة (clustering عند الكثرة).
- [ ] لا تُعِد رسم الخريطة مع كل تحديث موقع — اخنق (throttle) التحديثات.

### 5. العمل الثقيل على الـ main isolate
- [ ] انقل json parsing الكبير/الحسابات إلى `compute()` أو isolate.
- [ ] لا I/O متزامن في `build()`.

### 6. بدء التشغيل (Startup)
- [ ] أجّل التهيئة غير الحرجة (deferred/lazy) بعد أول إطار.
- [ ] قلّل العمل في `main()` قبل `runApp`.
- [ ] فعّل تصغير الكود وإزالة الموارد غير المستخدمة في الـ release.

### 7. الذاكرة والتسريبات
- [ ] `dispose()` لكل controller/subscription/animation/focusNode.
- [ ] ألغِ الاشتراكات (`StreamSubscription.cancel`) و timers.

## القياس قبل/بعد

اذكر رقماً: زمن الإطار، عدد الإطارات المفقودة، حجم APK، زمن البدء — قبل الإصلاح وبعده.
لا تقل "أصبح أسرع" دون قياس. ركّز على المسار الأكثر استخداماً (تصفّح العقارات).
