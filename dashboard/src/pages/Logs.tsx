import { useState } from 'react';
import { orderBy, limit, where } from 'firebase/firestore';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { dateTime } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';

interface LogEntry {
  id: string;
  category: string; // business|menu|users|zones|timings|discounts
  action: string;
  by?: string;
  createdAt?: Timestamp;
}

const TABS = ['all', 'business', 'menu', 'users', 'zones', 'timings', 'discounts'];

/** سجل التدقيق (Audit Log) — من يكتبه: Cloud Functions عند كل عملية حساسة. */
export default function Logs() {
  const { t } = useI18n();
  const [tab, setTab] = useState('all');
  const { data: logs, loading } = useCol<LogEntry>(
    'logs',
    ...(tab === 'all' ? [] : [where('category', '==', tab)]),
    orderBy('createdAt', 'desc'),
    limit(200),
  );

  return (
    <>
      <PageHeader title="Logs" />
      <div className="flex gap-2 mb-4 flex-wrap">
        {TABS.map((k) => (
          <button
            key={k}
            onClick={() => setTab(k)}
            className={`badge !px-3 !py-1.5 ${tab === k ? 'bg-brand-600 text-white' : 'bg-gray-100 text-ink-muted dark:bg-gray-800 dark:text-gray-400'}`}
          >
            {k}
          </button>
        ))}
      </div>

      {loading ? <Spinner /> : logs.length === 0 ? <EmptyState /> : (
        <Table headers={[t('date'), 'Category', t('details'), 'By']}>
          {logs.map((l) => (
            <tr key={l.id} className="table-row">
              <td className="td text-ink-muted">{dateTime(l.createdAt)}</td>
              <td className="td"><span className="badge bg-gray-100 text-gray-600">{l.category}</span></td>
              <td className="td">{l.action}</td>
              <td className="td font-mono text-xs">{l.by?.slice(0, 10) ?? '—'}</td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
