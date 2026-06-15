import { orderBy, limit } from 'firebase/firestore';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money, dateTime } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';

interface Tx {
  id: string;
  orderId?: string;
  uid?: string;
  type: 'order' | 'payout' | 'topup' | 'refund' | 'commission';
  amount: number;
  createdAt?: Timestamp;
}

const TX_CLS: Record<Tx['type'], string> = {
  order: 'bg-green-100 text-green-700',
  payout: 'bg-blue-100 text-blue-700',
  topup: 'bg-cyan-100 text-cyan-700',
  refund: 'bg-amber-100 text-amber-700',
  commission: 'bg-purple-100 text-purple-700',
};

export default function Finance() {
  const { t } = useI18n();
  const { data: txs, loading } = useCol<Tx>('transactions', orderBy('createdAt', 'desc'), limit(200));

  const totals = txs.reduce<Record<string, number>>((acc, x) => {
    acc[x.type] = (acc[x.type] ?? 0) + x.amount;
    return acc;
  }, {});

  return (
    <>
      <PageHeader title={t('finance')} />

      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3 mb-6">
        {(Object.keys(TX_CLS) as Tx['type'][]).map((k) => (
          <div key={k} className="card p-4">
            <span className={`badge ${TX_CLS[k]} mb-2`}>{k}</span>
            <div className="text-lg font-extrabold tabular-nums">{money(totals[k])}</div>
          </div>
        ))}
      </div>

      {loading ? <Spinner /> : txs.length === 0 ? <EmptyState /> : (
        <Table headers={[t('date'), t('type'), 'Ref', t('amount')]}>
          {txs.map((x) => (
            <tr key={x.id} className="table-row">
              <td className="td text-ink-muted">{dateTime(x.createdAt)}</td>
              <td className="td"><span className={`badge ${TX_CLS[x.type]}`}>{x.type}</span></td>
              <td className="td font-mono text-xs">{x.orderId?.slice(0, 8) ?? x.uid?.slice(0, 8) ?? '—'}</td>
              <td className={`td font-bold tabular-nums ${x.amount < 0 ? 'text-red-600' : 'text-green-600'}`}>
                {money(x.amount)}
              </td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
