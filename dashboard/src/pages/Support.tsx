import { orderBy, where, doc, updateDoc } from 'firebase/firestore';
import { Users as UsersIcon, Bike, ReceiptText, MessageSquare } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { dateTime, num } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';
import type { OrderStatus } from '../types';

interface Ticket {
  id: string; uid: string; subject?: string;
  status: 'open' | 'closed'; createdAt?: Timestamp;
}

// الحالات النشطة — كل ما قبل التسليم/الإلغاء (نفس عقد types/OrderStatus)
const ACTIVE_STATUSES: OrderStatus[] = [
  'pending', 'accepted', 'preparing', 'ready', 'assigned', 'picked_up', 'on_the_way',
];

export default function Support() {
  const { t } = useI18n();
  const { data: tickets, loading } = useCol<Ticket>('support', orderBy('createdAt', 'desc'));
  // عدّادات حية أعلى الصفحة — مثل تبويبات لوحته لكن لحظية (onSnapshot)
  const { data: users } = useCol<{ id: string }>('users');
  const { data: drivers } = useCol<{ id: string }>('drivers');
  const { data: activeOrders } = useCol<{ id: string }>(
    'orders', where('status', 'in', ACTIVE_STATUSES));

  const tabs = [
    { key: 'users', label: t('users'), count: users.length, icon: UsersIcon },
    { key: 'drivers', label: t('drivers'), count: drivers.length, icon: Bike },
    { key: 'activeOrders', label: t('activeOrders'), count: activeOrders.length, icon: ReceiptText },
    { key: 'messages', label: t('messages'), count: tickets.length, icon: MessageSquare },
  ];

  return (
    <>
      <PageHeader title={t('support')} />

      {/* تبويبات بعدّادات حية */}
      <div className="flex flex-wrap gap-3 mb-5">
        {tabs.map(({ key, label, count, icon: Icon }) => (
          <div key={key}
            className="card px-4 py-3 flex items-center gap-3 min-w-[150px]">
            <Icon size={20} strokeWidth={1.8} className="text-brand-600" />
            <div>
              <div className="text-xs text-ink-muted dark:text-gray-400">{label}</div>
              <div className="text-lg font-extrabold tabular-nums">{num(count)}</div>
            </div>
          </div>
        ))}
      </div>
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
