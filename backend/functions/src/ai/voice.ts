// صوت ديار — ElevenLabs TTS بأربع شخصيات مهنية (مجرَّب حيًا 12/06/2026:
// عينات عربية ✓ بأصوات بشرية أصلية أُضيفت لحساب المالك).
// الشخصيات (الافتراضيات قابلة للتغيير من اللوحة عبر config/voice):
//   support  — Talya  (بوت عربي شبيه بالبشر — خدمة العملاء)
//   support2 — Lina   (دافئ — الاسترداد والاعتذارات)
//   driver   — Hasawi (حيوي — تنبيهات السائق أثناء القيادة)
//   announce — Nasser (مؤسسي — الإعلانات الرسمية والعروض)
// السرّ يُحقن عند الإطلاق:
//   firebase functions:secrets:set ELEVENLABS_API_KEY
import { getFirestore } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

const ELEVENLABS_API_KEY = defineSecret('ELEVENLABS_API_KEY');

export type VoicePersona = 'support' | 'support2' | 'driver' | 'announce';

// أصوات عربية احترافية من مكتبة ElevenLabs — أُضيفت لحساب المالك
const DEFAULT_VOICES: Record<VoicePersona, string> = {
  support: 'rh16DBXwtscjdPFeMBYf', // Talya
  support2: '6ZvbKYJmZfL6zVBzLwpV', // Lina
  driver: 'kr4VZw8MSZMHE0y2m40n', // Hasawi
  announce: '3GnbqfjaW8xI6hRTVx4Y', // Nasser
};

/**
 * تحويل نص قصير إلى كلام بشخصية محددة — يعيد mp3 بترميز base64.
 * الأصوات تُدار من اللوحة (config/voice) والافتراضيات أعلاه.
 * محدود بـ300 حرف لكل نداء (حماية للرصيد) ولمستخدمين مسجلين فقط.
 */
export const speak = onCall(
  { secrets: [ELEVENLABS_API_KEY] },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError('unauthenticated', 'login required');
    const { text: raw, persona = 'support' } = req.data as {
      text?: string;
      persona?: VoicePersona;
    };
    const text = String(raw ?? '').trim();
    if (!text) throw new HttpsError('invalid-argument', 'text required');
    if (text.length > 300) {
      throw new HttpsError('invalid-argument', 'text too long (max 300 chars)');
    }
    const apiKey = ELEVENLABS_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'voice not configured yet');
    }

    // إعدادات اللوحة: تفعيل عام + استبدال صوت أي شخصية
    const cfg = (await getFirestore().doc('config/voice').get()).data() ?? {};
    if (cfg.enabled === false) {
      throw new HttpsError('failed-precondition', 'voice disabled by admin');
    }
    const voice: string =
      (cfg[persona] as string | undefined) ||
      DEFAULT_VOICES[persona] ||
      DEFAULT_VOICES.support;

    const res = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voice}?output_format=mp3_44100_128`,
      {
        method: 'POST',
        headers: { 'xi-api-key': apiKey, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text,
          model_id: 'eleven_multilingual_v2', // عربي + عبري + إنجليزي
          voice_settings: { stability: 0.5, similarity_boost: 0.8, style: 0.3 },
        }),
      },
    );
    if (!res.ok) throw new HttpsError('internal', `tts error ${res.status}`);
    const audio = Buffer.from(await res.arrayBuffer());
    return { mp3Base64: audio.toString('base64'), persona, voice };
  },
);

/**
 * جلسة الوكيل الصوتي الحي (ElevenLabs Conversational AI) — محادثة
 * فورية طبيعية كبشري لخدمة العملاء. يعيد رابط WebSocket موقّعًا
 * (المفتاح يبقى في الخادم). معرّف الوكيل من اللوحة: config/voice.agentId
 * — خطوات الإنشاء في docs/VOICE-AGENT.md.
 */
export const liveSupportUrl = onCall(
  { secrets: [ELEVENLABS_API_KEY] },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError('unauthenticated', 'login required');
    const apiKey = ELEVENLABS_API_KEY.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'voice not configured yet');
    }
    const cfg = (await getFirestore().doc('config/voice').get()).data() ?? {};
    if (cfg.enabled === false) {
      throw new HttpsError('failed-precondition', 'voice disabled by admin');
    }
    const agentId = cfg.agentId as string | undefined;
    if (!agentId) {
      throw new HttpsError(
        'failed-precondition',
        'live agent not configured — set config/voice.agentId',
      );
    }
    const res = await fetch(
      `https://api.elevenlabs.io/v1/convai/conversation/get_signed_url?agent_id=${agentId}`,
      { headers: { 'xi-api-key': apiKey } },
    );
    if (!res.ok) throw new HttpsError('internal', `agent session ${res.status}`);
    const data = (await res.json()) as { signed_url?: string };
    return { signedUrl: data.signed_url ?? null };
  },
);
