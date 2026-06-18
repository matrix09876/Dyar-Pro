---
name: memory-bank
description: "Persistent project memory across sessions for Dyar — a Claude Code adaptation of RooFlow's Memory Bank. Read the memory-bank/ files at the START of any non-trivial task to restore project context, and update them when significant changes/decisions/progress happen. TRIGGERS: 'update memory bank', 'UMB', 'حدّث الذاكرة', 'حدث الميموري', 'اقرأ الذاكرة', 'استرجع السياق', 'memory bank', 'sync context'. Also self-activate at the beginning of a session/task to load context, and before finishing a major task to persist what changed."
---

# Memory Bank — ذاكرة مشروع ديار الدائمة

تكييف لـ **RooFlow Memory Bank** (GreatScottyMac/RooFlow) لبيئة Claude Code.
الهدف: استمرارية السياق عبر الجلسات — لا تكرار شرح المشروع كل مرّة، ولا فقدان
القرارات والتقدّم. الذاكرة ملفات Markdown في مجلّد `memory-bank/` بجذر المشروع.

> ملاحظة: RooFlow الأصلي مبني على إضافة Roo Code (أوضاع + YAML + Footgun) ولا
> يعمل حرفيًا في Claude Code. هذه نسخة أصلية تحاكي **مفهوم الـ Memory Bank** فقط.

## ملفات الذاكرة (`memory-bank/`)

| الملف | المحتوى |
|---|---|
| `productContext.md` | نظرة عامة عالية المستوى: أهداف المشروع، الميزات، المعمارية. (نادر التغيّر) |
| `activeContext.md` | سياق الجلسة الحالية: آخر التغييرات، الهدف الحالي، أسئلة/عوائق مفتوحة. |
| `progress.md` | المنجز · الجاري · التالي (بصيغة قوائم مهام). |
| `decisionLog.md` | القرارات المعمارية/التنفيذية: السياق، القرار، المبرّر، التنفيذ. |
| `systemPatterns.md` | الأنماط والمعايير المتكرّرة (كود، معمارية، اختبارات، RTL/i18n). |

## متى تقرأ (Read)

- **في بداية أي مهمة غير تافهة**: اقرأ `productContext.md` + `activeContext.md` +
  `progress.md` (وعند الحاجة `decisionLog.md` / `systemPatterns.md`) لاسترجاع
  السياق قبل البدء.
- إن لم يوجد مجلّد `memory-bank/`: اقترح تهيئته (أنشئ الملفات الخمسة من حالة
  المشروع الحالية).

## متى تكتب (Update)

حدّث الذاكرة **تلقائيًا** عند الأحداث المهمّة، لا بعد كل تعديل صغير:
- **`activeContext.md`**: عند تغيّر الهدف الحالي، أو ظهور/حلّ عائق، أو إنجاز خطوة بارزة.
- **`progress.md`**: عند اكتمال مهمة أو إضافة مهمة جديدة (انقل من «الجاري» إلى «المنجز»).
- **`decisionLog.md`**: عند اتخاذ قرار معماري/تقني له بدائل (سجّل: السياق · القرار · المبرّر · التنفيذ · التاريخ).
- **`systemPatterns.md`**: عند ترسيخ نمط متكرّر جديد.
- **`productContext.md`**: فقط عند تغيّر جوهري في نطاق المشروع/معماريته.

أضِف ولا تمحُ التاريخ بلا داعٍ؛ ذيّل الإدخالات الجديدة بالتاريخ `[YYYY-MM-DD]`.

## أمر UMB ("Update Memory Bank" / "حدّث الذاكرة")

عند استدعائه صراحةً: راجع الجلسة الحالية كاملة وزامن **كل** الملفات الخمسة دفعةً:
1. اقرأ الملفات الحالية.
2. استخرج من الجلسة: ما تغيّر، القرارات، التقدّم، الأنماط، العوائق.
3. حدّث كل ملف في موضعه (لا تكرار).
4. أبلغ بإيجاز بما حُدّث.

## قواعد

- الذاكرة **مصدر مساعد**، و`CLAUDE.md` يبقى مصدر الحقيقة للقواعد الإلزامية.
- اكتب بإيجاز وبصيغة قابلة للمسح السريع (قوائم، عناوين).
- لا تضع أسرارًا/مفاتيح في الذاكرة (تُرفع إلى git).
- التزم بقواعد المشروع (RTL، i18n، إلخ) عند كتابة أي محتوى ظاهر.
