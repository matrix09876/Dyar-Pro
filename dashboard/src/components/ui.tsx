import type { ReactNode } from 'react';
import { useI18n } from '../lib/i18n';
import { STATUS_COLORS, type OrderStatus } from '../types';

export function PageHeader({ title, action }: { title: string; action?: ReactNode }) {
  return (
    <div className="flex items-center justify-between mb-6">
      <h1 className="text-2xl font-extrabold">{title}</h1>
      {action}
    </div>
  );
}

export function StatCard({ label, value, icon, accent }: {
  label: string; value: ReactNode; icon: ReactNode; accent?: string;
}) {
  return (
    <div className="card p-5 flex items-center gap-4">
      <div className={`h-12 w-12 rounded-2xl flex items-center justify-center ${accent ?? 'bg-brand-50 text-brand-600 dark:bg-brand-950'}`}>
        {icon}
      </div>
      <div>
        <div className="text-sm text-ink-muted dark:text-gray-400">{label}</div>
        <div className="text-2xl font-extrabold tabular-nums">{value}</div>
      </div>
    </div>
  );
}

export function StatusBadge({ status }: { status: OrderStatus | string }) {
  const { t } = useI18n();
  const cls = STATUS_COLORS[status as OrderStatus] ?? 'bg-gray-100 text-gray-600';
  return <span className={`badge ${cls}`}>{t(`st_${status}`)}</span>;
}

export function EmptyState({ message }: { message?: string }) {
  const { t } = useI18n();
  return (
    <div className="py-16 text-center text-ink-muted dark:text-gray-500">
      <div className="text-4xl mb-3">📭</div>
      {message ?? t('noData')}
    </div>
  );
}

export function Spinner() {
  return (
    <div className="py-16 flex justify-center">
      <div className="h-8 w-8 rounded-full border-4 border-brand-200 border-t-brand-600 animate-spin" />
    </div>
  );
}

export function Table({ headers, children }: { headers: string[]; children: ReactNode }) {
  return (
    <div className="card overflow-x-auto">
      <table className="w-full min-w-[640px]">
        <thead>
          <tr>{headers.map((h) => <th key={h} className="th">{h}</th>)}</tr>
        </thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  );
}
