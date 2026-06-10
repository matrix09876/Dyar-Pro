import { orderBy, limit } from 'firebase/firestore';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money, dateTime } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';

interface Booking {
  id: string;
  type: 'table' | 'service';
  partySize?: number;
  tableId?: string;
  slot?: Timestamp;
  fee?: number;
  status: string;
  reminder?: boolean;
  createdAt?: Timestamp;
}

const BOOKING_CLS: Record<string, string> = {
  pending: 'bg-amber-100 text-amber-700',
  confirmed: 'bg-blue-100 text-blue-700',
  seated: 'bg-sky-100 text-sky-700',
  completed: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-200 text-gray-600',
  no_show: 'bg-red-100 text-red-700',
};

export default function Bookings() {
  const { t } = useI18n();
  const { data: bookings, loading } = useCol<Booking>('bookings', orderBy('slot', 'desc'), limit(100));

  return (
    <>
      <PageHeader title={t('bookings')} />
      {loading ? <Spinner /> : bookings.length === 0 ? <EmptyState /> : (
        <Table headers={[t('date'), t('type'), 'طاولة / Table', '👥', t('status'), t('price')]}>
          {bookings.map((b) => (
            <tr key={b.id} className="table-row">
              <td className="td font-bold">{dateTime(b.slot)}</td>
              <td className="td">{b.type}</td>
              <td className="td">{b.tableId ?? '—'}</td>
              <td className="td tabular-nums">{b.partySize ?? '—'}</td>
              <td className="td"><span className={`badge ${BOOKING_CLS[b.status] ?? 'bg-gray-100 text-gray-600'}`}>{b.status}</span></td>
              <td className="td tabular-nums">{money(b.fee)}</td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
