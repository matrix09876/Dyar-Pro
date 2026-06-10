import { orderBy, doc, updateDoc } from 'firebase/firestore';
import { Star } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Store } from '../types';

const STORE_STATUS_CLS: Record<Store['status'], string> = {
  pending: 'bg-amber-100 text-amber-700',
  approved: 'bg-green-100 text-green-700',
  suspended: 'bg-red-100 text-red-700',
};

export default function Stores() {
  const { t } = useI18n();
  const { data: stores, loading } = useCol<Store>('stores', orderBy('createdAt', 'desc'));

  const setStatus = (s: Store, status: Store['status']) =>
    updateDoc(doc(db, 'stores', s.id), { status });

  const setCommission = async (s: Store) => {
    const v = prompt(`${t('commission')} — ${s.name}`, String(s.commissionPct ?? 10));
    if (v == null) return;
    const pct = Number(v);
    if (Number.isFinite(pct) && pct >= 0 && pct <= 50) {
      await updateDoc(doc(db, 'stores', s.id), { commissionPct: pct });
    }
  };

  const statusLabel: Record<Store['status'], string> = {
    pending: t('pendingApproval'), approved: t('approved'), suspended: t('suspended'),
  };

  return (
    <>
      <PageHeader title={t('stores')} />
      {loading ? <Spinner /> : stores.length === 0 ? <EmptyState /> : (
        <Table headers={[t('name'), t('storeType'), t('rating'), t('price'), t('commission'), t('status'), t('actions')]}>
          {stores.map((s) => (
            <tr key={s.id} className="table-row">
              <td className="td font-bold">
                <div className="flex items-center gap-3">
                  {s.logoUrl
                    ? <img src={s.logoUrl} className="h-9 w-9 rounded-xl object-cover" alt="" />
                    : <div className="h-9 w-9 rounded-xl bg-brand-100 dark:bg-brand-950 grid place-items-center text-brand-600 font-extrabold">{s.name?.[0]}</div>}
                  <div>
                    {s.name}
                    <div className={`text-xs font-normal ${s.isOpen ? 'text-green-600' : 'text-ink-muted'}`}>
                      {s.isOpen ? t('open') : t('closed')}
                    </div>
                  </div>
                </div>
              </td>
              <td className="td">{s.type}</td>
              <td className="td">
                <span className="inline-flex items-center gap-1">
                  <Star size={14} className="text-amber-500 fill-amber-500" />
                  {s.rating ?? '—'} ({s.ratingCount ?? 0})
                </span>
              </td>
              <td className="td tabular-nums">{money(s.deliveryFee)} / {money(s.minOrder)}</td>
              <td className="td">
                <button className="font-bold text-brand-600" onClick={() => setCommission(s)}>
                  {s.commissionPct ?? 10}%
                </button>
              </td>
              <td className="td"><span className={`badge ${STORE_STATUS_CLS[s.status]}`}>{statusLabel[s.status]}</span></td>
              <td className="td">
                <div className="flex gap-2">
                  {s.status !== 'approved' && (
                    <button className="btn-primary !py-1.5 !px-3 !text-xs" onClick={() => setStatus(s, 'approved')}>
                      {t('approve')}
                    </button>
                  )}
                  {s.status === 'approved' && (
                    <button className="btn-danger !py-1.5 !px-3 !text-xs" onClick={() => setStatus(s, 'suspended')}>
                      {t('suspend')}
                    </button>
                  )}
                </div>
              </td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
