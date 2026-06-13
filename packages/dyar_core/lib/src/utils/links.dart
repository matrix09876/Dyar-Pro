/// روابط ديار الثابتة — مصدر واحد للعملاء الثلاثة والويب.
library;

/// مكالمة حية مع «تاليا» — وكيلة خدمة العملاء الصوتية (ElevenLabs،
/// منشورة Live). تُفتح بالمتصفح: تعمل اليوم على كل المنصات بلا حزم صوت.
const kTalyaTalkUrl =
    'https://elevenlabs.io/app/talk-to?agent_id=agent_8801ktyhd1yve9ybf8bn5m9y27gw';

/// تفعيل خرائط Google داخل التطبيق — يُضبط وقت البناء بعد إضافة مفتاح الخريطة
/// أصلًا (AndroidManifest + AppDelegate). حتى ذلك الحين يعرض التطبيق بديلًا
/// أنيقًا (إحداثيات + فتح بالملاحة الخارجية) دون أي تعطّل.
///   flutter build … --dart-define=DYAR_MAPS=true
const kMapsEnabled = bool.fromEnvironment('DYAR_MAPS', defaultValue: false);

/// مركز الخريطة الافتراضي — الجليل (كرمئيل/بيت هكيرم) عند غياب موقع المستخدم.
const kDefaultMapLat = 32.9171;
const kDefaultMapLng = 35.2958;
