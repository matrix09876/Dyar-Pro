import { useMemo } from 'react';
import { orderBy, limit } from 'firebase/firestore';
import { Trophy, Store as StoreIcon, Clock3, TicketPercent } from 'lucide-react';
import {
  ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid,
} from 'recharts';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money, num } from '../lib/format';
import { PageHeader, Table, EmptyState } from '../components/ui';
import type { Order, Driver } from '../types';

interface Coupon { id: string; code: string; usedCount?: number; usageLimit?: number; active?: boolean }

/** التقارير — أهم 4 من قائمة «الرسوم البيانية» في اللوحة المرجعية:
 *  أفضل المندوبين · المبيعات حسب النشاط · تحليل الأوقات · الأكواد المستخدمة.
 *  تُحسب لحظيًا من آخر 300 طلب (خفيفة بلا فهارس إضافية). */
export default function Reports() {
  const { t } = useI18n();
  const { data: orders } = useCol<Order>('orders', orderBy('createdAt', 'desc'), limit(300));
  const { data: drivers } = useCol<Driver>('drivers', orderBy('earnings.total', 'desc'), limit(10));
  const { data: coupons } = useCol<Coupon>('coupons');

  const { salesByStore, hours } = useMemo(() => {
    const byStore = new Map<string, { orders: number; revenue: number }>();
    const byHour = Array.from({ length: 24 }, (_, h) => ({ name: `${h}:00`, orders: 0 }));
    for (const o of orders) {
      if (o.status === 'delivered') {
        const k = o.storeName ?? o.storeId ?? '—';
        const b = byStore.get(k) ?? { orders: 0, revenue: 0 };
        b.orders++; b.revenue += o.pricing?.total ?? 0;
        byStore.set(k, b);
      }
      const dt = o.createdAt?.toDate?.();
      if (dt) byHour[dt.getHours()].orders++;
    }
    return {
      salesByStore: [...byStore.entries()]
        .map(([name, v]) => ({ name, ...v }))
        .sort((a, b) => b.revenue - a.revenue)
        .slice(0, 8),
      hours: byHour,
    };
  }, [orders]);

  const usedCoupons = [...coupons].sort((a, b) => (b.usedCount ?? 0) - (a.usedCount ?? 0)).slice(0, 8);

  return (
    <>
      <PageHeader title={t('reports')} />

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* أفضل المندوبين */}
        <div className="card p-5">
          <h2 className="font-bold mb-4 flex items-center gap-2"><Trophy size={18} className="text-amber-500" /> {t('topDrivers')}</h2>
          {drivers.length === 0 ? <EmptyState /> : (
            <Table headers={['#', 'ID', t('earnings'), t('deliveries')]}>
              {drivers.map((d, i) => (
                <tr key={d.id} className="table-row">
                  <td className="td font-extrabold">{i + 1}{i === 0 ? ' 🏆' : ''}</td>
                  <td className="td font-mono text-xs">{d.id.slice(0, 10)}…</td>
                  <td className="td tabular-nums font-bold text-green-600">{money(d.earnings?.total)}</td>
                  <td className="td tabular-nums">{num(d.stats?.deliveredCount ?? 0)}</td>
                </tr>
              ))}
            </Table>
          )}
        </div>

        {/* المبيعات حسب النشاط */}
        <div className="card p-5">
          <h2 className="font-bold mb-4 flex items-center gap-2"><StoreIcon size={18} className="text-brand-500" /> {t('salesByStore')}</h2>
          {salesByStore.length === 0 ? <EmptyState /> : (
            <Table headers={[t('store'), t('orders'), t('revenue')]}>
              {salesByStore.map((s) => (
                <tr key={s.name} className="table-row">
                  <td className="td font-bold">{s.name}</td>
                  <td className="td tabular-nums">{num(s.orders)}</td>
                  <td className="td tabular-nums font-bold">{money(s.revenue)}</td>
                </tr>
              ))}
            </Table>
          )}
        </div>

        {/* تحليل الأوقات */}
        <div className="card p-5">
          <h2 className="font-bold mb-4 flex items-center gap-2"><Clock3 size={18} className="text-blue-500" /> {t('timeAnalysis')}</h2>
          <div className="h-56" dir="ltr">
            <ResponsiveContainer>
              <BarChart data={hours}>
                <CartesianGrid strokeDasharray="3 3" strokeOpacity={0.15} />
                <XAxis dataKey="name" fontSize={10} interval={2} />
                <YAxis fontSize={11} allowDecimals={false} />
                <Tooltip />
                <Bar dataKey="orders" fill="#f4691e" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* الأكواد المستخدمة */}
        <div className="card p-5">
          <h2 className="font-bold mb-4 flex items-center gap-2"><TicketPercent size={18} className="text-purple-500" /> {t('couponsUsed')}</h2>
          {usedCoupons.length === 0 ? <EmptyState /> : (
            <Table headers={[t('code'), t('usage'), t('status')]}>
              {usedCoupons.map((c) => (
                <tr key={c.id} className="table-row">
                  <td className="td font-mono font-bold">{c.code}</td>
                  <td className="td tabular-nums">{c.usedCount ?? 0} / {c.usageLimit ?? '∞'}</td>
                  <td className="td">
                    <span className={`badge ${c.active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}>
                      {c.active ? t('active') : '—'}
                    </span>
                  </td>
                </tr>
              ))}
            </Table>
          )}
        </div>
      </div>
    </>
  );
}
