import { orderBy } from 'firebase/firestore';
import { FileText } from 'lucide-react';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money, dateTime } from '../lib/format';
import { PageHeader, Table, EmptyState, StatCard } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';

interface RfqQuote {
  unitPrice?: number; total?: number; commission?: number;
  commissionPct?: number;
}
interface Rfq {
  id: string; merchantUid?: string; storeId?: string; storeName?: string;
  productName?: string; qty?: number; status?: string;
  quote?: RfqQuote; createdAt?: Timestamp;
}

/** ديار B2B — مراقبة طلبات عرض السعر (RFQ) وعمولة ديار المحفوظة خادميًا.
 *  أداة تدقيق «حماية العمولة»: كل صفقة جملة مقبولة تحمل عمولتها. */
export default function Rfqs() {
  const { t } = useI18n();
  const { data: rfqs } = useCol<Rfq>('rfqs', orderBy('createdAt', 'desc'));

  const accepted = rfqs.filter((r) => r.status === 'accepted');
  const totalCommission = accepted.reduce((s, r) => s + (r.quote?.commission ?? 0), 0);
  const totalVolume = accepted.reduce((s, r) => s + (r.quote?.total ?? 0), 0);

  return (
    <div className="space-y-4">
      <PageHeader title={t('rfqs')} />

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <StatCard label={t('rfqsOpen')} value={String(rfqs.filter((r) => r.status === 'open').length)} icon={<FileText size={18} />} />
        <StatCard label={t('rfqsQuoted')} value={String(rfqs.filter((r) => r.status === 'quoted').length)} icon={<FileText size={18} />} />
        <StatCard label={t('rfqsVolume')} value={money(totalVolume)} icon={<FileText size={18} />} accent="bg-emerald-50 text-emerald-600 dark:bg-emerald-950" />
        <StatCard label={t('rfqsCommission')} value={money(totalCommission)} icon={<FileText size={18} />} accent="bg-emerald-50 text-emerald-600 dark:bg-emerald-950" />
      </div>

      {rfqs.length === 0 ? (
        <EmptyState message={t('noData')} />
      ) : (
        <Table headers={[t('rfqProduct'), t('store'), t('rfqQty'), t('unitPrice'), t('rfqCommission'), t('status'), t('date')]}>
          {rfqs.map((r) => (
            <tr key={r.id} className="border-t border-slate-100 dark:border-slate-800">
              <td className="px-3 py-2 font-semibold">{r.productName}</td>
              <td className="px-3 py-2">{r.storeName}</td>
              <td className="px-3 py-2">{r.qty}</td>
              <td className="px-3 py-2">{r.quote ? money(r.quote.unitPrice) : '—'}</td>
              <td className="px-3 py-2">
                {r.quote?.commission
                  ? `${money(r.quote.commission)} (${r.quote.commissionPct}%)`
                  : '—'}
              </td>
              <td className="px-3 py-2">{t(`rfqStatus_${r.status}`)}</td>
              <td className="px-3 py-2 text-slate-500">{dateTime(r.createdAt)}</td>
            </tr>
          ))}
        </Table>
      )}
    </div>
  );
}
