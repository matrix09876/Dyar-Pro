import { useEffect, useState } from 'react';
import { where, orderBy, limit } from 'firebase/firestore';
import { Bike, Timer, Brain, MapPin } from 'lucide-react';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { PageHeader, StatusBadge, Spinner, EmptyState } from '../components/ui';
import type { Order, Driver } from '../types';
import type { Timestamp } from 'firebase/firestore';

const ACTIVE: string[] = [
  'pending', 'accepted', 'preparing', 'ready', 'assigned', 'picked_up', 'on_the_way',
];

interface LearnDoc { id: string; type?: string; stageStats?: Record<string, number> }

/** دقائق منذ وقت معيّن (تتبّع حي). */
const elapsed = (ts?: Timestamp) =>
  ts ? Math.max(0, Math.round((Date.now() - ts.toMillis()) / 60_000)) : 0;

/** التتبّع الحي — طلبات نشطة بزمنها، مندوبون متصلون وحمولتهم، وتعلّم
 *  التوقيت حسب النوع. كل التكامل داخل لوحة ديار. */
export default function Live() {
  const { t } = useI18n();
  // ساعة تنبض كل 30ث لتحديث الأزمنة المنقضية حيًا
  const [, setTick] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setTick((n) => n + 1), 30_000);
    return () => clearInterval(id);
  }, []);

  const { data: active, loading } = useCol<Order>(
    'orders', where('status', 'in', ACTIVE), orderBy('createdAt', 'desc'), limit(80),
  );
  const { data: online } = useCol<Driver>(
    'drivers', where('isOnline', '==', true),
  );
  const { data: learn } = useCol<LearnDoc>('learning');

  const loadByDriver = (uid?: string) =>
    active.filter((o) => o.driverUid === uid).length;

  return (
    <>
      <PageHeader title={t('liveTracking')} />

      {/* خريطة المندوبين — placeholder حتى مفتاح Google Maps */}
      <div className="card p-5 mb-6 flex items-center gap-3 text-ink-muted">
        <MapPin className="text-brand-500" />
        <span className="text-sm">{t('liveMapHint')}</span>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* الطلبات النشطة + الزمن المنقضي */}
        <div className="card p-5 xl:col-span-2">
          <h2 className="font-bold mb-4 flex items-center gap-2">
            <Timer size={18} className="text-brand-500" /> {t('activeOrders')} ({active.length})
          </h2>
          {loading ? <Spinner /> : active.length === 0 ? <EmptyState /> : (
            <div className="space-y-2 max-h-[60vh] overflow-y-auto">
              {active.map((o) => {
                const mins = elapsed(o.createdAt);
                const late = o.etaMins != null && mins > o.etaMins;
                return (
                  <div key={o.id} className="flex items-center gap-3 p-2.5 rounded-xl bg-gray-50 dark:bg-gray-800/40">
                    <span className="font-bold text-sm w-16">#{o.code}</span>
                    <StatusBadge status={o.status} />
                    <span className="text-xs text-ink-muted">{o.storeName ?? o.type}</span>
                    <span className="ms-auto text-xs font-bold tabular-nums">
                      <span className={late ? 'text-red-600' : 'text-ink-muted'}>⏱ {mins}د</span>
                      {o.etaMins != null && <span className="text-ink-muted"> / {o.etaMins}د</span>}
                    </span>
                    <span className="text-[10px] font-mono text-ink-muted w-16 text-end">
                      {o.driverUid ? o.driverUid.slice(0, 6) : '—'}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* المندوبون المتصلون + حمولتهم (هوية أداء حية) */}
        <div className="card p-5">
          <h2 className="font-bold mb-4 flex items-center gap-2">
            <Bike size={18} className="text-blue-500" /> {t('onlineDrivers')} ({online.length})
          </h2>
          {online.length === 0 ? <EmptyState /> : (
            <div className="space-y-2">
              {online.map((d) => (
                <div key={d.id} className="flex items-center gap-2 p-2.5 rounded-xl bg-gray-50 dark:bg-gray-800/40">
                  <span className="h-2 w-2 rounded-full bg-green-500" />
                  <span className="font-mono text-xs">{d.id.slice(0, 8)}…</span>
                  <span className="ms-auto text-xs">
                    <span className="badge bg-brand-100 text-brand-700">{loadByDriver(d.id)} {t('orders')}</span>
                  </span>
                  <span className="text-[10px] text-ink-muted">
                    ⌀ {d.stats?.avgDeliverMins ?? d.stats?.avgDeliveryMins ?? '—'}د
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* تعلّم التوقيت حسب النوع (AI-lite) */}
      <div className="card p-5 mt-6">
        <h2 className="font-bold mb-4 flex items-center gap-2">
          <Brain size={18} className="text-purple-500" /> {t('learnByType')}
        </h2>
        {learn.length === 0 ? <p className="text-sm text-ink-muted">{t('noData')}</p> : (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
            {learn.map((l) => (
              <div key={l.id} className="rounded-xl border border-gray-100 dark:border-gray-800 p-3">
                <div className="font-bold text-sm mb-1">{l.type ?? l.id}</div>
                <div className="text-xs text-ink-muted space-y-0.5 tabular-nums">
                  <div>قبول {l.stageStats?.accept ?? '—'}د</div>
                  <div>تحضير {l.stageStats?.prep ?? '—'}د</div>
                  <div>توصيل {l.stageStats?.deliver ?? '—'}د</div>
                  <div className="font-bold text-ink">الكل {l.stageStats?.total ?? '—'}د · {l.stageStats?.count ?? 0}</div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
