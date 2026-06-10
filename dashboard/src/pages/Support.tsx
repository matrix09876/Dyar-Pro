import { orderBy, doc, updateDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { dateTime } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';

interface Ticket {
  id: string; uid: string; subject?: string;
  status: 'open' | 'closed'; createdAt?: Timestamp;
}

export default function Support() {
  const { t } = useI18n();
  const { data: tickets, loading } = useCol<Ticket>('support', orderBy('createdAt', 'desc'));

  return (
    <>
      <PageHeader title={t('support')} />
      {loading ? <Spinner /> : tickets.length === 0 ? <EmptyState /> : (
        <Table headers={[t('date'), t('details'), 'User', t('status')]}>
          {tickets.map((tk) => (
            <tr key={tk.id} className="table-row">
              <td className="td text-ink-muted">{dateTime(tk.createdAt)}</td>
              <td className="td font-bold">{tk.subject ?? '—'}</td>
              <td className="td font-mono text-xs">{tk.uid?.slice(0, 10)}…</td>
              <td className="td">
                <button
                  className={`badge ${tk.status === 'open' ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700'}`}
                  onClick={() => updateDoc(doc(db, 'support', tk.id), { status: tk.status === 'open' ? 'closed' : 'open' })}
                >
                  {tk.status}
                </button>
              </td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
