import { useState, type FormEvent } from 'react';
import {
  addDoc, collection, deleteDoc, doc, serverTimestamp, updateDoc,
} from 'firebase/firestore';
import { Download, Plus, Trash2, Trophy } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money } from '../lib/format';
import { exportCsv } from '../lib/csv';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Driver, DriverPrize } from '../types';

const DRIVER_STATUS_CLS: Record<Driver['status'], string> = {
  pending: 'bg-amber-100 text-amber-700',
  approved: 'bg-green-100 text-green-700',
  suspended: 'bg-red-100 text-red-700',
};

export default function Drivers() {
  const { t } = useI18n();
  const { data: drivers, loading } = useCol<Driver>('drivers');
  const { data: prizes } = useCol<DriverPrize>('driverPrizes');
  const [showPrizeForm, setShowPrizeForm] = useState(false);

  const setStatus = (d: Driver, status: Driver['status']) =>
    updateDoc(doc(db, 'drivers', d.id), { status });

  const statusLabel: Record<Driver['status'], string> = {
    pending: t('pendingApproval'), approved: t('approved'), suspended: t('suspended'),
  };

  const addPrize = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    await addDoc(collection(db, 'driverPrizes'), {
      title: String(f.get('title') ?? '').trim(),
      targetDeliveries: Number(f.get('target')),
      bonus: Number(f.get('bonus')),
      active: true,
      createdAt: serverTimestamp(),
    });
    setShowPrizeForm(false);
  };

  const downloadCsv = () =>
    exportCsv('drivers',
      ['ID', t('vehicle'), t('online'), t('earnings'), t('rating'), t('status')],
      drivers.map((d) => [
        d.id, d.vehicle?.type ?? '', d.isOnline ? 1 : 0,
        ((d.earnings?.total ?? 0) / 100).toFixed(2), d.rating ?? '', d.status,
      ]));

  // تقرير الأرباح الشهري — id + أعمدة الأرباح (اليوم/الأسبوع/الإجمالي)
  const downloadEarnings = () =>
    exportCsv(`driver-earnings-${new Date().toISOString().slice(0, 7)}`,
      ['ID', 'earnings.today ₪', 'earnings.week ₪', 'earnings.total ₪', 'deliveredCount'],
      drivers.map((d) => [
        d.id,
        ((d.earnings?.today ?? 0) / 100).toFixed(2),
        ((d.earnings?.week ?? 0) / 100).toFixed(2),
        ((d.earnings?.total ?? 0) / 100).toFixed(2),
        d.stats?.deliveredCount ?? 0,
      ]));

  return (
    <>
      <PageHeader
        title={t('drivers')}
        action={
          <div className="flex gap-2">
            <button className="btn-ghost" onClick={downloadCsv}>
              <Download size={18} /> CSV
            </button>
            <button className="btn-ghost" onClick={downloadEarnings}>
              <Download size={18} /> {t('monthlyEarningsReport')}
            </button>
          </div>
        }
      />

      {/* جوائز المندوبين 🏆 — هدف توصيلات → مكافأة تلقائية من الخادم */}
      <div className="card p-5 mb-5 space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="font-extrabold flex items-center gap-2">
            <Trophy size={20} className="text-amber-500" /> {t('driverPrizes')} 🏆
          </h2>
          <button className="btn-ghost" onClick={() => setShowPrizeForm(true)}>
            <Plus size={18} /> {t('addPrize')}
          </button>
        </div>
        {prizes.length === 0 ? (
          <p className="text-sm text-ink-muted">{t('noData')}</p>
        ) : (
          <div className="flex flex-wrap gap-3">
            {prizes.map((p) => (
              <div key={p.id}
                className={`rounded-2xl border px-4 py-3 flex items-center gap-3 ${
                  p.active
                    ? 'border-amber-300 bg-amber-50 dark:bg-amber-950/30'
                    : 'border-gray-200 dark:border-gray-700 opacity-60'
                }`}>
                <div>
                  <div className="font-bold text-sm">{p.title}</div>
                  <div className="text-xs text-ink-muted">
                    {p.targetDeliveries} 🛵 → {money(p.bonus)}
                  </div>
                </div>
                <button
                  className={`badge ${p.active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}
                  onClick={() => updateDoc(doc(db, 'driverPrizes', p.id), { active: !p.active })}>
                  {p.active ? t('active') : '—'}
                </button>
                <button className="btn-ghost !px-1.5 text-red-500"
                  onClick={() => deleteDoc(doc(db, 'driverPrizes', p.id))}>
                  <Trash2 size={16} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {loading ? <Spinner /> : drivers.length === 0 ? <EmptyState /> : (
        <Table headers={['ID', t('vehicle'), t('online'), t('earnings'), t('identity'), t('rating'), t('status'), t('actions')]}>
          {drivers.map((d) => (
            <tr key={d.id} className="table-row">
              <td className="td font-mono text-xs">{d.id.slice(0, 10)}…</td>
              <td className="td">{d.vehicle?.type ?? '—'} {d.vehicle?.plate ? `· ${d.vehicle.plate}` : ''}</td>
              <td className="td">
                <span className={`inline-flex items-center gap-1.5 text-sm font-semibold ${d.isOnline ? 'text-green-600' : 'text-ink-muted'}`}>
                  <span className={`h-2 w-2 rounded-full ${d.isOnline ? 'bg-green-500' : 'bg-gray-300'}`} />
                  {d.isOnline ? t('online') : t('offline')}
                </span>
              </td>
              <td className="td tabular-nums">{money(d.earnings?.total)}</td>
              <td className="td text-xs text-ink-muted tabular-nums" title="هوية الأداء: توصيلات · متوسط استلام/توصيل">
                🏁 {d.stats?.deliveredCount ?? 0} · ⌀{d.stats?.avgDeliverMins ?? d.stats?.avgDeliveryMins ?? '—'}د
                {d.stats?.avgPickupMins != null ? ` · 🛍${d.stats.avgPickupMins}د` : ''}
              </td>
              <td className="td">{d.rating ?? '—'}</td>
              <td className="td"><span className={`badge ${DRIVER_STATUS_CLS[d.status]}`}>{statusLabel[d.status]}</span></td>
              <td className="td">
                <div className="flex gap-2">
                  {d.status !== 'approved' && (
                    <button className="btn-primary !py-1.5 !px-3 !text-xs" onClick={() => setStatus(d, 'approved')}>{t('approve')}</button>
                  )}
                  {d.status === 'approved' && (
                    <button className="btn-danger !py-1.5 !px-3 !text-xs" onClick={() => setStatus(d, 'suspended')}>{t('suspend')}</button>
                  )}
                </div>
              </td>
            </tr>
          ))}
        </Table>
      )}

      {showPrizeForm && (
        <div className="fixed inset-0 z-50 bg-black/40 grid place-items-center p-4"
          onClick={() => setShowPrizeForm(false)}>
          <form className="card w-full max-w-md p-6 space-y-4"
            onClick={(e) => e.stopPropagation()} onSubmit={addPrize}>
            <h2 className="text-lg font-extrabold">{t('addPrize')} 🏆</h2>
            <input className="input" name="title" placeholder={t('name')} required />
            <label className="block">
              <span className="text-sm font-bold">{t('targetDeliveries')}</span>
              <input className="input mt-1" name="target" type="number" min={1} required />
            </label>
            <label className="block">
              <span className="text-sm font-bold">{t('bonus')}</span>
              <input className="input mt-1" name="bonus" type="number" min={1} required />
            </label>
            <div className="flex gap-3">
              <button type="button" className="btn-ghost flex-1"
                onClick={() => setShowPrizeForm(false)}>{t('cancel')}</button>
              <button className="btn-primary flex-1">{t('save')}</button>
            </div>
          </form>
        </div>
      )}
    </>
  );
}
