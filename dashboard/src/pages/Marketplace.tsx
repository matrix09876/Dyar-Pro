import { useEffect, useState, type FormEvent } from 'react';
import { doc, getDoc, orderBy, setDoc, updateDoc } from 'firebase/firestore';
import { Check, X } from 'lucide-react';
import { db, isConfigured } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money, dateTime } from '../lib/format';
import { PageHeader, EmptyState, Spinner } from '../components/ui';
import type { MarketProduct } from '../types';

/** سوق C2C (بيع وشراء) — اعتماد/رفض منتجات المستخدمين + عمولة السوق. */
const STATUSES: MarketProduct['status'][] = ['pending', 'approved', 'rejected', 'sold'];

const STATUS_CLS: Record<MarketProduct['status'], string> = {
  pending: 'bg-amber-100 text-amber-700',
  approved: 'bg-green-100 text-green-700',
  rejected: 'bg-red-100 text-red-700',
  sold: 'bg-violet-100 text-violet-700',
};

const CATEGORY_LABEL: Record<string, string> = {
  electronics: '📱', fashion: '👗', home: '🏠', cars: '🚗', other: '📦',
};

export default function Marketplace() {
  const { t } = useI18n();
  const [tab, setTab] = useState<MarketProduct['status']>('pending');
  const { data: products, loading } =
    useCol<MarketProduct>('marketProducts', orderBy('createdAt', 'desc'));

  // عمولة السوق % — تُحفظ في config/app.marketplaceCommissionPct (افتراضي 5)
  const [pct, setPct] = useState<number>(5);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (!isConfigured) return;
    getDoc(doc(db, 'config', 'app')).then((snap) => {
      const v = snap.data()?.marketplaceCommissionPct;
      if (typeof v === 'number') setPct(v);
    });
  }, []);

  const savePct = async (e: FormEvent) => {
    e.preventDefault();
    if (!Number.isFinite(pct) || pct < 0 || pct > 50) return;
    await setDoc(doc(db, 'config', 'app'),
      { marketplaceCommissionPct: pct }, { merge: true });
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const setStatus = (p: MarketProduct, status: MarketProduct['status']) =>
    updateDoc(doc(db, 'marketProducts', p.id), { status });

  const statusLabel: Record<MarketProduct['status'], string> = {
    pending: t('st_pending'), approved: t('st_approved'),
    rejected: t('st_rejected'), sold: t('st_sold'),
  };

  const list = products.filter((p) => p.status === tab);

  return (
    <>
      <PageHeader
        title={t('marketplace')}
        action={
          <form className="flex items-center gap-2" onSubmit={savePct}>
            <span className="text-sm font-bold text-ink-muted">{t('marketplaceCommission')}</span>
            <input className="input !w-20 text-center tabular-nums" type="number"
              min={0} max={50} step={0.5} value={pct}
              onChange={(e) => setPct(Number(e.target.value))} />
            <button className="btn-primary !py-2">{saved ? '✓' : t('save')}</button>
          </form>
        }
      />

      <div className="flex gap-2 mb-5 flex-wrap">
        {STATUSES.map((st) => (
          <button key={st} onClick={() => setTab(st)}
            className={`badge !px-3 !py-1.5 ${tab === st
              ? 'bg-brand-600 text-white'
              : 'bg-gray-100 text-ink-muted dark:bg-gray-800 dark:text-gray-400'}`}>
            {statusLabel[st]} ({products.filter((p) => p.status === st).length})
          </button>
        ))}
      </div>

      {loading ? <Spinner /> : list.length === 0 ? <EmptyState /> : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {list.map((p) => (
            <div key={p.id} className="card overflow-hidden">
              {p.imageUrl
                ? <img src={p.imageUrl} className="h-36 w-full object-cover" alt="" />
                : <div className="h-36 w-full grid place-items-center bg-brand-50 dark:bg-brand-950 text-4xl">🛍️</div>}
              <div className="p-4 space-y-2">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <div className="font-bold truncate">
                      {CATEGORY_LABEL[p.category] ?? '📦'} {p.title}
                    </div>
                    <div className="text-xs text-ink-muted truncate">
                      {p.city || '—'} · {dateTime(p.createdAt)}
                    </div>
                  </div>
                  <span className={`badge shrink-0 ${STATUS_CLS[p.status]}`}>
                    {statusLabel[p.status]}
                  </span>
                </div>
                {p.description && (
                  <p className="text-xs text-ink-muted line-clamp-2">{p.description}</p>
                )}
                <div className="flex items-center justify-between gap-2">
                  <div className="font-extrabold tabular-nums text-brand-600">
                    {money(p.price)}
                  </div>
                  <div className="flex gap-2">
                    {p.status !== 'approved' && p.status !== 'sold' && (
                      <button className="btn-primary !py-1.5 !px-3 !text-xs"
                        onClick={() => setStatus(p, 'approved')}>
                        <Check size={14} /> {t('approve')}
                      </button>
                    )}
                    {p.status !== 'rejected' && p.status !== 'sold' && (
                      <button className="btn-danger !py-1.5 !px-3 !text-xs"
                        onClick={() => setStatus(p, 'rejected')}>
                        <X size={14} /> {t('reject')}
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
