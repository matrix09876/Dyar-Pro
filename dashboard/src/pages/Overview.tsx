import { useMemo } from 'react';
import { orderBy, limit, where } from 'firebase/firestore';
import {
  ReceiptText, Banknote, Bike, Store as StoreIcon,
} from 'lucide-react';
import {
  ResponsiveContainer, AreaChart, Area, XAxis, YAxis, Tooltip, CartesianGrid,
} from 'recharts';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money, num } from '../lib/format';
import { PageHeader, StatCard, StatusBadge, Table, EmptyState } from '../components/ui';
import type { Order, Driver, Store } from '../types';

export default function Overview() {
  const { t, lang } = useI18n();
  // آخر 200 طلب تكفي لحساب مؤشرات اليوم + الرسم الأسبوعي
  const { data: orders } = useCol<Order>('orders', orderBy('createdAt', 'desc'), limit(200));
  const { data: onlineDrivers } = useCol<Driver>('drivers', where('isOnline', '==', true));
  const { data: pendingStores } = useCol<Store>('stores', where('status', '==', 'pending'));

  const { todayCount, todayRevenue, chart } = useMemo(() => {
    const startOfDay = new Date(); startOfDay.setHours(0, 0, 0, 0);
    let count = 0, revenue = 0;
    const days = new Map<string, { orders: number; revenue: number }>();
    for (let i = 6; i >= 0; i--) {
      const d = new Date(); d.setDate(d.getDate() - i);
      days.set(d.toLocaleDateString(lang, { weekday: 'short' }), { orders: 0, revenue: 0 });
    }
    for (const o of orders) {
      const dt = o.createdAt?.toDate?.();
      if (!dt) continue;
      if (dt >= startOfDay && o.status !== 'cancelled' && o.status !== 'rejected') {
        count++; revenue += o.pricing?.total ?? 0;
      }
      const key = dt.toLocaleDateString(lang, { weekday: 'short' });
      const bucket = days.get(key);
      if (bucket && o.status === 'delivered') { bucket.orders++; bucket.revenue += (o.pricing?.total ?? 0) / 100; }
    }
    return {
      todayCount: count,
      todayRevenue: revenue,
      chart: [...days.entries()].map(([name, v]) => ({ name, ...v })),
    };
  }, [orders, lang]);

  const live = orders.filter((o) => !['delivered', 'cancelled', 'rejected'].includes(o.status)).slice(0, 8);

  return (
    <>
      <PageHeader title={t('overview')} />

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        <StatCard label={t('todayOrders')} value={num(todayCount)} icon={<ReceiptText strokeWidth={1.8} />} />
        <StatCard label={t('todayRevenue')} value={money(todayRevenue)} icon={<Banknote strokeWidth={1.8} />}
          accent="bg-green-50 text-green-600 dark:bg-green-950" />
        <StatCard label={t('activeDrivers')} value={num(onlineDrivers.length)} icon={<Bike strokeWidth={1.8} />}
          accent="bg-blue-50 text-blue-600 dark:bg-blue-950" />
        <StatCard label={t('pendingStores')} value={num(pendingStores.length)} icon={<StoreIcon strokeWidth={1.8} />}
          accent="bg-amber-50 text-amber-600 dark:bg-amber-950" />
      </div>

      <div className="card p-5 mb-6">
        <h2 className="font-bold mb-4">{t('revenue')} — {t('last7days')}</h2>
        <div className="h-64" dir="ltr">
          <ResponsiveContainer>
            <AreaChart data={chart}>
              <defs>
                <linearGradient id="rev" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#f4691e" stopOpacity={0.35} />
                  <stop offset="100%" stopColor="#f4691e" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" strokeOpacity={0.15} />
              <XAxis dataKey="name" fontSize={12} />
              <YAxis fontSize={12} />
              <Tooltip />
              <Area type="monotone" dataKey="revenue" stroke="#f4691e" strokeWidth={2.5} fill="url(#rev)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      <h2 className="font-bold mb-3">{t('liveOrders')}</h2>
      {live.length === 0 ? (
        <EmptyState />
      ) : (
        <Table headers={[t('orderCode'), t('status'), t('total'), t('payment')]}>
          {live.map((o) => (
            <tr key={o.id} className="table-row">
              <td className="td font-bold">#{o.code}</td>
              <td className="td"><StatusBadge status={o.status} /></td>
              <td className="td tabular-nums">{money(o.pricing?.total)}</td>
              <td className="td">{o.payment?.method}</td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
