import { useEffect, useState, type FormEvent } from 'react';
import { doc, getDoc, setDoc } from 'firebase/firestore';
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
}

const DEFAULTS: AppConfig = {
  serviceFee: 200, defaultCommissionPct: 10, currency: 'ils',
  supportPhone: '', referralReward: 0, maintenanceMode: false, surgeEnabled: true,
};

export default function Settings() {
  const { t } = useI18n();
  const [cfg, setCfg] = useState<AppConfig | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (!isConfigured) { setCfg(DEFAULTS); return; }
    getDoc(doc(db, 'config', 'app')).then((snap) => {
      setCfg({ ...DEFAULTS, ...(snap.data() as Partial<AppConfig> | undefined) });
    });
  }, []);

  const save = async (e: FormEvent) => {
    e.preventDefault();
    if (!cfg) return;
    await setDoc(doc(db, 'config', 'app'), cfg, { merge: true });
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  if (!cfg) return <Spinner />;

  const set = <K extends keyof AppConfig>(k: K, v: AppConfig[K]) => setCfg({ ...cfg, [k]: v });

  return (
    <>
      <PageHeader title={t('settings')} />
      <form onSubmit={save} className="card p-6 max-w-xl space-y-5">
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
    </>
  );
}
