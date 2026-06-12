// صوت ديار — ElevenLabs TTS (مجرَّب حيًا 12/06/2026: عربي multilingual_v2 ✓)
// الاستخدامات: نطق ردود Dyar Bot، وإعلانات صوتية للسائق أثناء القيادة
// (مهمة جديدة/تغيّر حالة) — ميزة أمان وتنافسية حقيقية.
// السرّان يُحقنان عند الإطلاق:
//   firebase functions:secrets:set ELEVENLABS_API_KEY
//   (اختياري) firebase functions:secrets:set ELEVENLABS_VOICE_ID
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

const ELEVENLABS_API_KEY = defineSecret('ELEVENLABS_API_KEY');
const ELEVENLABS_VOICE_ID = defineSecret('ELEVENLABS_VOICE_ID');

// صوت افتراضي متعدد اللغات (عربي/عبري/إنجليزي) من مكتبة ElevenLabs
const DEFAULT_VOICE = 'EXAVITQu4vr4xnSDxMaL'; // Sarah — دافئ وواضح

/**
 * تحويل نص قصير إلى كلام — يعيد mp3 بترميز base64 ليُشغَّل في التطبيق.
 * محدود بـ300 حرف لكل نداء (حماية للرصيد الشهري) ولمستخدمين مسجلين فقط.
 */
export const speak = onCall(
  { secrets: [ELEVENLABS_API_KEY, ELEVENLABS_VOICE_ID] },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError('unauthenticated', 'login required');
    const text = String((req.data as { text?: string }).text ?? '').trim();
    if (!text) throw new HttpsError('invalid-argument', 'text required');
    if (text.length > 300) {
      throw new HttpsError('invalid-argument', 'text too long (max 300 chars)');
    }
    const apiKey = ELEVENLABS_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'voice not configured yet');
    }
    const voice = ELEVENLABS_VOICE_ID.value() || DEFAULT_VOICE;

    const res = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voice}?output_format=mp3_44100_128`,
      {
        method: 'POST',
        headers: { 'xi-api-key': apiKey, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text,
          model_id: 'eleven_multilingual_v2', // عربي + عبري + إنجليزي
        }),
      },
    );
    if (!res.ok) throw new HttpsError('internal', `tts error ${res.status}`);
    const audio = Buffer.from(await res.arrayBuffer());
    return { mp3Base64: audio.toString('base64') };
  },
);
