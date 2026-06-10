import { useState } from 'react';
import { orderBy, limit, where, doc, updateDoc } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { X } from 'lucide-react';
import { db, functions } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money, dateTime } from '../lib/format';
import { PageHeader, StatusBadge, Table, EmptyState, Spinner } from '../components/ui';
import type { Order, Driver, OrderStatus } from '../types';

const FILTERS: (OrderStatus | 'all')[] = [
  'all', 'pending', 'accepted', 'preparing', 'ready', 'assigned',
  'on_the_way', 'delivered', 'cancelled',
];

// التحوّلات المتاحة للإدارة من اللوحة (الباقي يفرضه الخادم)
const NEXT: Partial<Record<OrderStatus, OrderStatus[]>> = {
  pending: ['accepted', 'rejected'],
  accepted: ['preparing'],
  preparing: ['ready'],
  ready: ['assigned'],
  assigned: ['picked_up'],
  picked_up: ['on_the_way'],
  on_the_way: ['delivered'],
};

export default function Orders() {
  const { t } = useI18n();
  const [filter, setFilter] = useState<OrderStatus | 'all'>('all');
  const [selected, setSelected] = useState<Order | null>(null);

  const { data: orders, loading } = useCol<Order>(
    'orders',
    ...(filter === 'all' ? [] : [where('status', '==', filter)]),
    orderBy('createdAt', 'desc'),
    limit(100),
  );
  const { data: freeDrivers } = useCol<Driver>(
    'drivers', where('isOnline', '==', true), where('status', '==', 'approved'),
  );

  const changeStatus = async (o: Order, status: OrderStatus) => {
    // عبر اللوحة (admin) يُسمح بالتحديث المباشر؛ القواعد تتحقق من الدور
    await updateDoc(doc(db, 'orders', o.id), { status });
    setSelected(null);
  };

  const assign = async (o: Order, driverUid: string) => {
    await httpsCallable(functions, 'assignDriver')({ orderId: o.id, driverUid });
    setSelected(null);
  };

  return (
    <>
      <PageHeader title={t('orders')} />

      <div className="flex gap-2 mb-4 flex-wrap">
        {FILTERS.map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`badge !px-3 !py-1.5 transition-colors ${
              filter === f ? 'bg-brand-600 text-white' : 'bg-gray-100 text-ink-muted dark:bg-gray-800 dark:text-gray-400'
            }`}
          >
            {f === 'all' ? '•••' : t(`st_${f}`)}
          </button>
        ))}
      </div>

      {loading ? <Spinner /> : orders.length === 0 ? <EmptyState /> : (
        <Table headers={[t('orderCode'), t('date'), t('status'), t('items'), t('total'), t('payment'), '']}>
          {orders.map((o) => (
            <tr key={o.id} className="table-row cursor-pointer" onClick={() => setSelected(o)}>
              <td className="td font-bold">#{o.code}</td>
              <td className="td text-ink-muted">{dateTime(o.createdAt)}</td>
              <td className="td"><StatusBadge status={o.status} /></td>
              <td className="td">{o.items?.length ?? 0}</td>
              <td className="td font-bold tabular-nums">{money(o.pricing?.total)}</td>
              <td className="td">{o.payment?.method} · {o.payment?.status}</td>
              <td className="td text-brand-600 font-bold">{t('details')} ←</td>
            </tr>
          ))}
        </Table>
      )}

      {/* لوحة التفاصيل */}
      {selected && (
        <div className="fixed inset-0 z-50 bg-black/40 flex justify-end" onClick={() => setSelected(null)}>
          <div
            className="w-full max-w-md h-full bg-white dark:bg-surface-card p-6 overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-extrabold">#{selected.code}</h2>
              <button className="btn-ghost !px-2" onClick={() => setSelected(null)}><X /></button>
            </div>

            <div className="mb-4"><StatusBadge status={selected.status} /></div>

            <div className="card !shadow-none p-4 mb-4 space-y-2">
              {selected.items?.map((it, i) => (
                <div key={i} className="flex justify-between text-sm">
                  <span>{it.qty}× {it.name}</span>
                  <span className="tabular-nums">{money(it.lineTotal)}</span>
                </div>
              ))}
              <div className="border-t border-gray-100 dark:border-gray-800 pt-2 flex justify-between font-extrabold">
                <span>{t('total')}</span>
                <span className="tabular-nums">{money(selected.pricing?.total)}</span>
              </div>
            </div>

            {/* تغيير الحالة */}
            {(NEXT[selected.status] ?? []).length > 0 && (
              <div className="mb-4">
                <h3 className="font-bold text-sm mb-2">{t('status')}</h3>
                <div className="flex gap-2 flex-wrap">
                  {NEXT[selected.status]!.map((s) => (
                    <button key={s} className="btn-primary !py-2" onClick={() => changeStatus(selected, s)}>
                      {t(`st_${s}`)}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* تعيين سائق */}
            {['ready', 'pending', 'accepted', 'preparing'].includes(selected.status) && (
              <div>
                <h3 className="font-bold text-sm mb-2">{t('assignDriver')}</h3>
                {freeDrivers.length === 0 ? (
                  <p className="text-sm text-ink-muted">{t('noData')}</p>
                ) : (
                  <div className="space-y-2">
                    {freeDrivers.filter((d) => !d.activeOrderId).map((d) => (
                      <button
                        key={d.id}
                        className="w-full card !shadow-none p-3 flex justify-between items-center hover:border-brand-400"
                        onClick={() => assign(selected, d.id)}
                      >
                        <span className="text-sm font-semibold">{d.id.slice(0, 8)}… · {d.vehicle?.type}</span>
                        <span className="text-brand-600 font-bold text-sm">{t('assignDriver')}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}
