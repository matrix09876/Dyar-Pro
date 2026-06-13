import { useEffect, useState } from 'react';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';
import { db, isConfigured } from '../lib/firebase';
import { useI18n } from '../lib/i18n';
import { PageHeader, Spinner } from '../components/ui';

/** مفاتيح الميزات حسب الجمهور — تطابق dyar_core kFeatureKeysByAudience. */
const GROUPS: { audience: string; emoji: string; keys: string[] }[] = [
  { audience: 'الزبون', emoji: '🛍️', keys: [
    'food', 'grocery', 'pharmacy', 'flowers', 'services', 'taxi', 'parcel',
    'marketplace', 'jobs', 'bookings', 'wholesale', 'loyalty', 'subscription',
    'referral', 'giftcards', 'voiceAgent', 'dietaryFilter',
  ] },
  { audience: 'التاجر', emoji: '🏪', keys: ['printer', 'promotions', 'menuScheduling', 'selfCampaigns'] },
  { audience: 'المندوب', emoji: '🛵', keys: ['instantPayout', 'driverPrizes', 'rides', 'heatmap'] },
  { audience: 'مقدّم الخدمة', emoji: '🛠️', keys: ['appointments', 'consultation'] },
];

const LABELS: Record<string, string> = {
  food: 'مطاعم', grocery: 'بقالة', pharmacy: 'صيدلية', flowers: 'ورود',
  services: 'خدمات', taxi: 'تاكسي', parcel: 'طرود', marketplace: 'بيع وشراء',
  jobs: 'وظائف', bookings: 'حجوزات', wholesale: 'جملة B2B', loyalty: 'نظام النقاط',
  subscription: 'Dyar+ الاشتراك', referral: 'ادعُ واربح', giftcards: 'بطاقات هدايا',
  voiceAgent: 'مساعد تاليا الصوتي', dietaryFilter: 'فلتر حلال/كوشير',
  printer: 'طابعة المطبخ', promotions: 'العروض', menuScheduling: 'جدولة المنيو',
  selfCampaigns: 'حملات ذاتية', instantPayout: 'سحب فوري', driverPrizes: 'جوائز المندوبين',
  rides: 'المشاوير', heatmap: 'خريطة حرارية', appointments: 'حجز المواعيد',
  consultation: 'الاستشارات',
};

/** إدارة إظهار/إخفاء الميزات (config/features) — عالميًا حسب الجمهور.
 *  التحكم بالمنطقة عبر صفحة المدن (رؤية الفئات لكل مدينة). */
export default function Features() {
  const { t } = useI18n();
  const [flags, setFlags] = useState<Record<string, boolean> | null>(null);

  useEffect(() => {
    if (!isConfigured) { setFlags({}); return; }
    return onSnapshot(doc(db, 'config', 'features'), (snap) => {
      const d = (snap.data() ?? {}) as Record<string, unknown>;
      const out: Record<string, boolean> = {};
      for (const [k, v] of Object.entries(d)) if (typeof v === 'boolean') out[k] = v;
      setFlags(out);
    });
  }, []);

  // الافتراضي الآمن: الميزة ظاهرة ما لم تُطفأ صراحةً
  const isOn = (k: string) => flags?.[k] ?? true;
  const toggle = (k: string) =>
    setDoc(doc(db, 'config', 'features'), { [k]: !isOn(k) }, { merge: true });

  if (flags === null) return <Spinner />;

  return (
    <>
      <PageHeader title={t('features')} />
      <p className="text-sm text-ink-muted mb-5">{t('featuresHint')}</p>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {GROUPS.map((g) => (
          <div key={g.audience} className="card p-5">
            <h2 className="font-extrabold mb-4">{g.emoji} {g.audience}</h2>
            <div className="space-y-1">
              {g.keys.map((k) => (
                <label key={k} className="flex items-center justify-between py-2 border-b border-gray-50 dark:border-gray-800 last:border-0 cursor-pointer">
                  <span className="text-sm font-semibold">{LABELS[k] ?? k}</span>
                  <button
                    onClick={() => toggle(k)}
                    className={`relative h-6 w-11 rounded-full transition-colors ${isOn(k) ? 'bg-brand-600' : 'bg-gray-300 dark:bg-gray-700'}`}
                  >
                    <span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-all ${isOn(k) ? 'start-0.5' : 'end-0.5'}`} />
                  </button>
                </label>
              ))}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
