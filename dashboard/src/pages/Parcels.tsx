import { orderBy, limit } from 'firebase/firestore';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money, dateTime } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';

interface Parcel {
  id: string;
  status: string;
  sender?: { name?: string };
  recipient?: { name?: string };
  size?: { weightKg?: number };
  pricing?: { total?: number };
  createdAt?: Timestamp;
}

const PARCEL_CLS: Record<string, string> = {
  pending: 'bg-amber-100 text-amber-700',
  pickup: 'bg-blue-100 text-blue-700',
  in_transit: 'bg-sky-100 text-sky-700',
  delivered: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-200 text-gray-600',
};

export default function Parcels() {
  const { t } = useI18n();
  const { data: parcels, loading } = useCol<Parcel>('parcels', orderBy('createdAt', 'desc'), limit(100));

  return (
    <>
      <PageHeader title={t('parcels')} />
      {loading ? <Spinner /> : parcels.length === 0 ? <EmptyState /> : (
        <Table headers={[t('date'), 'من / From', 'إلى / To', 'KG', t('status'), t('total')]}>
          {parcels.map((p) => (
            <tr key={p.id} className="table-row">
              <td className="td text-ink-muted">{dateTime(p.createdAt)}</td>
              <td className="td font-bold">{p.sender?.name ?? '—'}</td>
              <td className="td font-bold">{p.recipient?.name ?? '—'}</td>
              <td className="td tabular-nums">{p.size?.weightKg ?? '—'}</td>
              <td className="td"><span className={`badge ${PARCEL_CLS[p.status] ?? 'bg-gray-100 text-gray-600'}`}>{p.status}</span></td>
              <td className="td font-bold tabular-nums">{money(p.pricing?.total)}</td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
