import { doc, updateDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Driver } from '../types';

const DRIVER_STATUS_CLS: Record<Driver['status'], string> = {
  pending: 'bg-amber-100 text-amber-700',
  approved: 'bg-green-100 text-green-700',
  suspended: 'bg-red-100 text-red-700',
};

export default function Drivers() {
  const { t } = useI18n();
  const { data: drivers, loading } = useCol<Driver>('drivers');

  const setStatus = (d: Driver, status: Driver['status']) =>
    updateDoc(doc(db, 'drivers', d.id), { status });

  const statusLabel: Record<Driver['status'], string> = {
    pending: t('pendingApproval'), approved: t('approved'), suspended: t('suspended'),
  };

  return (
    <>
      <PageHeader title={t('drivers')} />
      {loading ? <Spinner /> : drivers.length === 0 ? <EmptyState /> : (
        <Table headers={['ID', t('vehicle'), t('online'), t('earnings'), t('rating'), t('status'), t('actions')]}>
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
    </>
  );
}
