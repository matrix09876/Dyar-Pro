import { useEffect, useState, type FormEvent } from 'react';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { Plus, Trash2 } from 'lucide-react';
import { db, isConfigured } from '../lib/firebase';
import { useI18n } from '../lib/i18n';
import { PageHeader, Spinner } from '../components/ui';

interface AppConfig {
  serviceFee: number;
  defaultCommissionPct: number;
  currency: string;
  supportPhone: string;
  referralReward: number;
  maintenanceMode: boolean;
  surgeEnabled: boolean;
  platformName: string;
  brandColor: string;
  phoneCode: string;
  mapsEnabled: boolean;
  newUserGift: number; // أغورة — هدية المستخدم الجديد
}

/** صوت ديار — config/voice: 4 شخصيات ElevenLabs (انظر DATA-MODEL). */
interface VoiceCfg {
  enabled: boolean;
  agentId: string; // وكيل المحادثة الحية (ElevenLabs ConvAI)
  support: string; support2: string; driver: string; announce: string;
}
const VOICE_DEFAULTS: VoiceCfg = {
  enabled: true,
  agentId: 'agent_8801ktyhd1yve9ybf8bn5m9y27gw', // تاليا — منشورة Live 12/06
  support: 'rh16DBXwtscjdPFeMBYf',   // Talya
  support2: '6ZvbKYJmZfL6zVBzLwpV',  // Lina
  driver: 'kr4VZw8MSZMHE0y2m40n',    // Hasawi
  announce: '3GnbqfjaW8xI6hRTVx4Y',  // Nasser
};

/** نظام النقاط — config/loyalty (انظر docs/DATA-MODEL.md). */
interface LoyaltyCfg {
  enabled: boolean;
  earnPerShekel: number; // نقاط لكل ₪1
  redeemRate: number;    // أغورة لكل نقطة عند الاستبدال
}

const LOYALTY_DEFAULTS: LoyaltyCfg = { enabled: false, earnPerShekel: 1, redeemRate: 10 };

/** قاعدة عمولة ذكية — انظر docs/DATA-MODEL.md (config/app.commissionRules).
 *  قائمة مرتبة بالأولوية: أول قاعدة مطابقة تفوز، والشرائح تبقى الافتراضي. */
interface CommissionRule {
  scope: 'store' | 'city' | 'country' | 'storeType';
  match: string;
  pct: number;
  peakPct?: number;
  peakHours?: { from: string; to: string };
}

/** صف قابل للتحرير في الجدول (الذروة كحقول مسطّحة اختيارية). */
interface RuleRow {
  scope: CommissionRule['scope'];
  match: string;
  pct: number;
  peakFrom: string;
  peakTo: string;
  peakPct: string; // نص حتى يُسمح بتركه فارغًا
}

const DEFAULTS: AppConfig = {
  serviceFee: 200, defaultCommissionPct: 10, currency: 'ILS',
  supportPhone: '', referralReward: 0, maintenanceMode: false, surgeEnabled: true,
  platformName: 'Dyar', brandColor: '#0ea5e9', phoneCode: '+972',
  mapsEnabled: true, newUserGift: 0,
};

const SCOPES: { value: RuleRow['scope']; label: string }[] = [
  { value: 'store', label: 'متجر' },
  { value: 'city', label: 'مدينة' },
  { value: 'country', label: 'بلد' },
  { value: 'storeType', label: 'نوع المتجر' },
];

const toRow = (r: CommissionRule): RuleRow => ({
  scope: r.scope, match: r.match ?? '', pct: r.pct ?? 0,
  peakFrom: r.peakHours?.from ?? '', peakTo: r.peakHours?.to ?? '',
  peakPct: typeof r.peakPct === 'number' ? String(r.peakPct) : '',
});

const toRule = (r: RuleRow): CommissionRule => ({
  scope: r.scope, match: r.match.trim(), pct: Number(r.pct) || 0,
  ...(r.peakPct !== '' ? { peakPct: Number(r.peakPct) } : {}),
  ...(r.peakFrom && r.peakTo
    ? { peakHours: { from: r.peakFrom, to: r.peakTo } } : {}),
});

export default function Settings() {
  const { t } = useI18n();
  const [cfg, setCfg] = useState<AppConfig | null>(null);
  const [rules, setRules] = useState<RuleRow[]>([]);
  const [saved, setSaved] = useState(false);
  const [rulesSaved, setRulesSaved] = useState(false);
  const [loyalty, setLoyalty] = useState<LoyaltyCfg>(LOYALTY_DEFAULTS);
  const [loyaltySaved, setLoyaltySaved] = useState(false);
  const [voice, setVoice] = useState<VoiceCfg>(VOICE_DEFAULTS);
  const [voiceSaved, setVoiceSaved] = useState(false);

  useEffect(() => {
    if (!isConfigured) { setCfg(DEFAULTS); return; }
    getDoc(doc(db, 'config', 'app')).then((snap) => {
      const data = snap.data() as
        (Partial<AppConfig> & { commissionRules?: CommissionRule[] }) | undefined;
      setCfg({ ...DEFAULTS, ...data });
      setRules((data?.commissionRules ?? []).map(toRow));
    });
    getDoc(doc(db, 'config', 'loyalty')).then((snap) => {
      setLoyalty({ ...LOYALTY_DEFAULTS, ...(snap.data() as Partial<LoyaltyCfg> | undefined) });
    });
    getDoc(doc(db, 'config', 'voice')).then((snap) => {
      setVoice({ ...VOICE_DEFAULTS, ...(snap.data() as Partial<VoiceCfg> | undefined) });
    });
  }, []);

  const save = async (e: FormEvent) => {
    e.preventDefault();
    if (!cfg) return;
    await setDoc(doc(db, 'config', 'app'), cfg, { merge: true });
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const saveLoyalty = async () => {
    await setDoc(doc(db, 'config', 'loyalty'), loyalty, { merge: true });
    setLoyaltySaved(true);
    setTimeout(() => setLoyaltySaved(false), 2000);
  };

  const saveVoice = async () => {
    await setDoc(doc(db, 'config', 'voice'), voice, { merge: true });
    setVoiceSaved(true);
    setTimeout(() => setVoiceSaved(false), 2000);
  };

  const saveRules = async () => {
    const clean = rules.map(toRule).filter((r) => r.match !== '');
    await setDoc(doc(db, 'config', 'app'),
      { commissionRules: clean }, { merge: true });
    setRules(clean.map(toRow));
    setRulesSaved(true);
    setTimeout(() => setRulesSaved(false), 2000);
  };

  if (!cfg) return <Spinner />;

  const set = <K extends keyof AppConfig>(k: K, v: AppConfig[K]) => setCfg({ ...cfg, [k]: v });
  const setRule = <K extends keyof RuleRow>(i: number, k: K, v: RuleRow[K]) =>
    setRules(rules.map((r, idx) => (idx === i ? { ...r, [k]: v } : r)));

  return (
    <>
      <PageHeader title={t('settings')} />
      <form onSubmit={save} className="card p-6 max-w-xl space-y-5">
        <label className="block">
          <span className="text-sm font-bold">{t('platformName')}</span>
          <input className="input mt-1" value={cfg.platformName}
            onChange={(e) => set('platformName', e.target.value)} />
        </label>
        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-sm font-bold">{t('brandColor')}</span>
            <input className="input mt-1 h-11 p-1 cursor-pointer" type="color"
              value={cfg.brandColor}
              onChange={(e) => set('brandColor', e.target.value)} />
          </label>
          <label className="block">
            <span className="text-sm font-bold">{t('currency')}</span>
            <input className="input mt-1" dir="ltr" value={cfg.currency}
              placeholder="ILS"
              onChange={(e) => set('currency', e.target.value.toUpperCase())} />
          </label>
        </div>
        <label className="block">
          <span className="text-sm font-bold">{t('phoneCode')}</span>
          <input className="input mt-1" dir="ltr" value={cfg.phoneCode}
            placeholder="+972"
            onChange={(e) => set('phoneCode', e.target.value)} />
        </label>
        <label className="block">
          <span className="text-sm font-bold">{t('newUserGift')}</span>
          <input className="input mt-1" type="number" min={0} value={cfg.newUserGift}
            onChange={(e) => set('newUserGift', Number(e.target.value))} />
        </label>
        <div className="flex items-center justify-between">
          <span className="text-sm font-bold">{t('mapsEnabled')}</span>
          <input type="checkbox" className="h-5 w-5 accent-brand-600" checked={cfg.mapsEnabled}
            onChange={(e) => set('mapsEnabled', e.target.checked)} />
        </div>
        <label className="block">
          <span className="text-sm font-bold">{t('serviceFee')}</span>
          <input className="input mt-1" type="number" value={cfg.serviceFee}
            onChange={(e) => set('serviceFee', Number(e.target.value))} />
        </label>
        <label className="block">
          <span className="text-sm font-bold">{t('defaultCommission')}</span>
          <input className="input mt-1" type="number" value={cfg.defaultCommissionPct}
            onChange={(e) => set('defaultCommissionPct', Number(e.target.value))} />
        </label>
        <label className="block">
          <span className="text-sm font-bold">{t('referralReward')}</span>
          <input className="input mt-1" type="number" value={cfg.referralReward}
            onChange={(e) => set('referralReward', Number(e.target.value))} />
        </label>
        <label className="block">
          <span className="text-sm font-bold">{t('phone')}</span>
          <input className="input mt-1" dir="ltr" value={cfg.supportPhone}
            onChange={(e) => set('supportPhone', e.target.value)} />
        </label>

        <div className="flex items-center justify-between">
          <span className="text-sm font-bold">Surge (تسعير الذروة)</span>
          <input type="checkbox" className="h-5 w-5 accent-brand-600" checked={cfg.surgeEnabled}
            onChange={(e) => set('surgeEnabled', e.target.checked)} />
        </div>
        <div className="flex items-center justify-between">
          <span className="text-sm font-bold">{t('maintenanceMode')}</span>
          <input type="checkbox" className="h-5 w-5 accent-brand-600" checked={cfg.maintenanceMode}
            onChange={(e) => set('maintenanceMode', e.target.checked)} />
        </div>

        <button className="btn-cta">{saved ? '✓' : t('save')}</button>
      </form>

      {/* نظام النقاط — config/loyalty: كسب عند delivered + معدل استبدال */}
      <div className="card p-6 mt-5 max-w-xl space-y-5">
        <h2 className="font-extrabold">{t('loyalty')}</h2>
        <div className="flex items-center justify-between">
          <span className="text-sm font-bold">{t('loyaltyEnabled')}</span>
          <input type="checkbox" className="h-5 w-5 accent-brand-600"
            checked={loyalty.enabled}
            onChange={(e) => setLoyalty({ ...loyalty, enabled: e.target.checked })} />
        </div>
        <label className="block">
          <span className="text-sm font-bold">{t('earnPerShekel')}</span>
          <input className="input mt-1" type="number" min={0} step="0.1"
            value={loyalty.earnPerShekel}
            onChange={(e) => setLoyalty({ ...loyalty, earnPerShekel: Number(e.target.value) })} />
        </label>
        <label className="block">
          <span className="text-sm font-bold">{t('redeemRate')}</span>
          <input className="input mt-1" type="number" min={0}
            value={loyalty.redeemRate}
            onChange={(e) => setLoyalty({ ...loyalty, redeemRate: Number(e.target.value) })} />
        </label>
        <button type="button" className="btn-primary" onClick={saveLoyalty}>
          {loyaltySaved ? '✓' : t('save')}
        </button>
      </div>

      {/* صوت ديار — config/voice: 4 شخصيات ElevenLabs تديرها اللوحة */}
      <div className="card p-6 mt-5 max-w-xl space-y-5">
        <h2 className="font-extrabold">🔊 {t('dyarVoice')}</h2>
        <p className="text-xs text-ink-muted">{t('dyarVoiceHint')}</p>
        <div className="flex items-center justify-between">
          <span className="text-sm font-bold">{t('voiceEnabled')}</span>
          <input type="checkbox" className="h-5 w-5 accent-brand-600"
            checked={voice.enabled}
            onChange={(e) => setVoice({ ...voice, enabled: e.target.checked })} />
        </div>
        {([
          ['support', t('voiceSupport'), 'Talya'],
          ['support2', t('voiceSupport2'), 'Lina'],
          ['driver', t('voiceDriver'), 'Hasawi'],
          ['announce', t('voiceAnnounce'), 'Nasser'],
        ] as const).map(([k, label, def]) => (
          <label key={k} className="block">
            <span className="text-sm font-bold">{label} <span className="text-ink-muted font-normal">({def})</span></span>
            <input className="input mt-1 font-mono text-xs" dir="ltr"
              value={voice[k]}
              onChange={(e) => setVoice({ ...voice, [k]: e.target.value })} />
          </label>
        ))}
        <label className="block">
          <span className="text-sm font-bold">{t('voiceAgentId')}</span>
          <input className="input mt-1 font-mono text-xs" dir="ltr"
            placeholder="agent_…"
            value={voice.agentId}
            onChange={(e) => setVoice({ ...voice, agentId: e.target.value })} />
          <span className="text-xs text-ink-muted">{t('voiceAgentHint')}</span>
        </label>
        <button type="button" className="btn-primary" onClick={saveVoice}>
          {voiceSaved ? '✓' : t('save')}
        </button>
      </div>

      {/* قواعد العمولة الذكية — مرتبة بالأولوية، أول قاعدة مطابقة تفوز،
          والشرائح (commissionTiers) تبقى الافتراضي الأخير */}
      <div className="card p-6 mt-5 max-w-5xl space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="font-extrabold">قواعد العمولة</h2>
          <button type="button" className="btn-ghost"
            onClick={() => setRules([...rules,
              { scope: 'city', match: '', pct: 10, peakFrom: '', peakTo: '', peakPct: '' }])}>
            <Plus size={18} /> إضافة قاعدة
          </button>
        </div>
        <p className="text-xs text-ink-muted">
          مرتبة بالأولوية (الأعلى أولًا) — أول قاعدة مطابقة تفوز. override
          المتجر وخدمات 6% أعلى منها، والشرائح الشهرية تبقى الافتراضي الأخير.
        </p>

        {rules.length === 0 ? (
          <p className="text-sm text-ink-muted">لا توجد قواعد — تُطبَّق الشرائح الافتراضية.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-start text-ink-muted">
                  <th className="text-start p-2">النطاق</th>
                  <th className="text-start p-2">المطابقة (معرّف/بلد/نوع)</th>
                  <th className="text-start p-2">النسبة %</th>
                  <th className="text-start p-2">الذروة من</th>
                  <th className="text-start p-2">إلى</th>
                  <th className="text-start p-2">نسبة الذروة %</th>
                  <th className="p-2" />
                </tr>
              </thead>
              <tbody>
                {rules.map((r, i) => (
                  <tr key={i} className="border-t border-ink-100">
                    <td className="p-2">
                      <select className="input" value={r.scope}
                        onChange={(e) => setRule(i, 'scope', e.target.value as RuleRow['scope'])}>
                        {SCOPES.map((s) => (
                          <option key={s.value} value={s.value}>{s.label}</option>
                        ))}
                      </select>
                    </td>
                    <td className="p-2">
                      <input className="input" dir="ltr" value={r.match}
                        placeholder="haifa / IL / restaurant"
                        onChange={(e) => setRule(i, 'match', e.target.value)} />
                    </td>
                    <td className="p-2">
                      <input className="input w-20" type="number" step="0.5" value={r.pct}
                        onChange={(e) => setRule(i, 'pct', Number(e.target.value))} />
                    </td>
                    <td className="p-2">
                      <input className="input" type="time" value={r.peakFrom}
                        onChange={(e) => setRule(i, 'peakFrom', e.target.value)} />
                    </td>
                    <td className="p-2">
                      <input className="input" type="time" value={r.peakTo}
                        onChange={(e) => setRule(i, 'peakTo', e.target.value)} />
                    </td>
                    <td className="p-2">
                      <input className="input w-20" type="number" step="0.5" value={r.peakPct}
                        placeholder="—"
                        onChange={(e) => setRule(i, 'peakPct', e.target.value)} />
                    </td>
                    <td className="p-2">
                      <button type="button" className="btn-ghost text-red-600"
                        title="حذف"
                        onClick={() => setRules(rules.filter((_, idx) => idx !== i))}>
                        <Trash2 size={16} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <button type="button" className="btn-primary" onClick={saveRules}>
          {rulesSaved ? '✓' : t('save')}
        </button>
      </div>
    </>
  );
}
