import { orderBy, limit } from 'firebase/firestore';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money, dateTime } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';

interface Ride {
  id: string;
  status: string;
  tier: string;
  pickup?: { address?: string };
  dropoff?: { address?: string };
  pricing?: { total?: number; surge?: number };
  distanceKm?: number;
  createdAt?: Timestamp;
}

const RIDE_CLS: Record<string, string> = {
  searching: 'bg-amber-100 text-amber-700',
  accepted: 'bg-blue-100 text-blue-700',
  arriving: 'bg-cyan-100 text-cyan-700',
  in_progress: 'bg-sky-100 text-sky-700',
  completed: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-200 text-gray-600',
};

export default function Rides() {
  const { t } = useI18n();
  const { data: rides, loading } = useCol<Ride>('rides', orderBy('createdAt', 'desc'), limit(100));

  return (
    <>
      <PageHeader title={t('rides')} />
      {loading ? <Spinner /> : rides.length === 0 ? <EmptyState /> : (
        <Table headers={[t('date'), 'Tier', t('status'), 'KM', 'Surge', t('total')]}>
          {rides.map((r) => (
            <tr key={r.id} className="table-row">
              <td className="td text-ink-muted">{dateTime(r.createdAt)}</td>
              <td className="td font-bold">{r.tier}</td>
              <td className="td"><span className={`badge ${RIDE_CLS[r.status] ?? 'bg-gray-100 text-gray-600'}`}>{r.status}</span></td>
              <td className="td tabular-nums">{r.distanceKm ?? '—'}</td>
              <td className="td tabular-nums">{r.pricing?.surge && r.pricing.surge > 1 ? `×${r.pricing.surge}` : '—'}</td>
              <td className="td font-bold tabular-nums">{money(r.pricing?.total)}</td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
