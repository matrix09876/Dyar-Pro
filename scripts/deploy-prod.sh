#!/usr/bin/env bash
# نشر ديار للإنتاج (مشروع dyar-ai) — يُشغَّل من جهاز المالك بعد
# `firebase login`. آمن لإعادة التشغيل في أي وقت.
set -euo pipefail
cd "$(dirname "$0")/../backend"

echo "🔥 1/4 اختيار مشروع الإنتاج dyar-ai"
npx firebase use prod

echo "🛡️ 2/4 نشر قواعد الأمان + الفهارس + Storage"
npx firebase deploy --only firestore:rules,firestore:indexes,storage

echo "⚙️ 3/4 بناء ونشر كل الدوال (يطلب إدخال الأسرار الناقصة أول مرة)"
(cd functions && npm ci && npm run build)
npx firebase deploy --only functions

echo "✅ 4/4 تم. الخطوات التالية اليدوية:"
echo "   • أول مدير: أنشئ حسابك في Authentication ثم:"
echo "     npx firebase functions:shell  ← ثم نفّذ:"
echo "     setUserRole({uid:'<UID>', role:'admin'})"
echo "     (أو من اللوحة لاحقًا عبر مدير قائم)"
echo "   • التطبيقات: dart pub global activate flutterfire_cli ثم"
echo "     flutterfire configure داخل apps/user و partner و driver"
echo "   • الأسرار: EASYCARD_* · ELEVENLABS_API_KEY · SUPPORT_HOOK_SECRET"
echo "     عبر: npx firebase functions:secrets:set <NAME>"
