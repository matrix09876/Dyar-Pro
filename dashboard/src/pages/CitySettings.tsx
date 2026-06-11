import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { ArrowRight } from 'lucide-react';
import { db } from '../lib/firebase';
import { useI18n } from '../lib/i18n';
import { PageHeader, Spinner } from '../components/ui';

/** إعدادات المدينة — مطابق للوحة الحالية: ساعات، Dynamic fare،
 *  شرائح المناطق، الإسناد الآلي، إلغاء غير المقبول. */
interface CityCfg {
  hoursOpen: string; hoursClose: string;
  orderNotifyEmail: string;
  dynamicFareEnabled: boolean; demandLevel: string;
  basePct: number; secondPct: number; thirdPct: number; fourthPct: number;
  autoAssignment: boolean; cancelIfNotAccepted: boolean;
}

const DEFAULTS: CityCfg = {
  hoursOpen: '08:00', hoursClose: '23:59',
  orderNotifyEmail: '',
  dynamicFareEnabled: false, demandLevel: 'high',
  basePct: 5, secondPct: 20, thirdPct: 15, fourthPct: 30,
  autoAssignment: true, cancelIfNotAccepted: true,
};

export default function CitySettings() {
  const { id } = useParams<{ id: string }>();
  const { t } = useI18n();
  const [name, setName] = useState('');
  const [cfg, setCfg] = useState<CityCfg | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (!id) return;
    getDoc(doc(db, 'cities', id)).then((snap) => {
      const d = snap.data() ?? {};
      setName(d.name ?? id);
      setCfg({
        ...DEFAULTS,
        hoursOpen: d.hours?.open ?? DEFAULTS.hoursOpen,
        hoursClose: d.hours?.close ?? DEFAULTS.hoursClose,
        orderNotifyEmail: d.orderNotifyEmail ?? '',
        dynamicFareEnabled: d.dynamicFare?.enabled ?? false,
        demandLevel: d.dynamicFare?.demandLevel ?? 'high',
        basePct: d.zoneTiers?.basePct ?? 5,
        secondPct: d.zoneTiers?.secondPct ?? 20,
        thirdPct: d.zoneTiers?.thirdPct ?? 15,
        fourthPct: d.zoneTiers?.fourthPct ?? 30,
        autoAssignment: d.autoAssignment ?? true,
        cancelIfNotAccepted: d.cancelIfNotAccepted ?? true,
      });
    });
  }, [id]);

  if (!cfg) return <Spinner />;
  const set = <K extends keyof CityCfg>(k: K, v: CityCfg[K]) =>
    setCfg({ ...cfg, [k]: v });

  const save = async () => {
    await setDoc(doc(db, 'cities', id!), {
      hours: { open: cfg.hoursOpen, close: cfg.hoursClose },
      orderNotifyEmail: cfg.orderNotifyEmail,
      dynamicFare: { enabled: cfg.dynamicFareEnabled, demandLevel: cfg.demandLevel },
      zoneTiers: {
        basePct: cfg.basePct, secondPct: cfg.secondPct,
        thirdPct: cfg.thirdPct, fourthPct: cfg.fourthPct,
      },
      autoAssignment: cfg.autoAssignment,
      cancelIfNotAccepted: cfg.cancelIfNotAccepted,
    }, { merge: true });
    setSaved(true); setTimeout(() => setSaved(false), 2000);
  };

  const Toggle = ({ k, label }: { k: keyof CityCfg; label: string }) => (
    <div className="flex items-center justify-between">
      <span className="text-sm font-bold">{label}</span>
      <input type="checkbox" className="h-5 w-5 accent-brand-600"
        checked={cfg[k] as boolean}
        onChange={(e) => set(k, e.target.checked as CityCfg[typeof k])} />
    </div>
  );

  return (
    <>
      <PageHeader
        title={`${t('settings')} — ${name}`}
        action={<Link to="/cities" className="btn-ghost"><ArrowRight size={18} /> {t('city')}</Link>}
      />
      <div className="grid lg:grid-cols-2 gap-5 max-w-4xl">
        <div className="card p-6 space-y-4">
          <h2 className="font-extrabold">{t('workHours')}</h2>
          <div className="flex gap-3">
            <input className="input" type="time" value={cfg.hoursOpen}
              onChange={(e) => set('hoursOpen', e.target.value)} />
            <input className="input" type="time" value={cfg.hoursClose}
              onChange={(e) => set('hoursClose', e.target.value)} />
          </div>
          <label className="block">
            <span className="text-sm font-bold">{t('email')}</span>
            <input className="input mt-1" dir="ltr" value={cfg.orderNotifyEmail}
              placeholder="orders@dyar.app"
              onChange={(e) => set('orderNotifyEmail', e.target.value)} />
          </label>
          <Toggle k="autoAssignment" label="Automatic Assignment" />
          <Toggle k="cancelIfNotAccepted" label="Cancel order if not accepted" />
        </div>

        <div className="card p-6 space-y-4">
          <h2 className="font-extrabold">Dynamic fare</h2>
          <Toggle k="dynamicFareEnabled" label={t('active')} />
          <select className="input" value={cfg.demandLevel}
            onChange={(e) => set('demandLevel', e.target.value)}>
            <option value="normal">Normal</option>
            <option value="high">The demand is high</option>
            <option value="very_high">Very high</option>
          </select>

          <h2 className="font-extrabold pt-2">Zones settings — % increase</h2>
          <div className="grid grid-cols-4 gap-2">
            {(['basePct', 'secondPct', 'thirdPct', 'fourthPct'] as const).map((k, i) => (
              <label key={k} className="block">
                <span className="text-xs text-ink-muted">Area {i + 1}</span>
                <input className="input mt-1" type="number" value={cfg[k]}
                  onChange={(e) => set(k, Number(e.target.value))} />
              </label>
            ))}
          </div>
        </div>
      </div>
      <button className="btn-primary mt-5" onClick={save}>
        {saved ? '✓' : t('save')}
      </button>
    </>
  );
}
