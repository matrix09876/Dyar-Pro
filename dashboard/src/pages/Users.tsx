import { useState } from 'react';
import { orderBy, limit, doc, updateDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { AppUser } from '../types';

const ROLE_CLS: Record<string, string> = {
  admin: 'bg-purple-100 text-purple-700',
  partner: 'bg-blue-100 text-blue-700',
  driver: 'bg-cyan-100 text-cyan-700',
  customer: 'bg-gray-100 text-gray-600',
};

export default function Users() {
  const { t } = useI18n();
  const [q, setQ] = useState('');
  const { data: users, loading } = useCol<AppUser>('users', orderBy('createdAt', 'desc'), limit(300));

  const filtered = q
    ? users.filter((u) =>
        [u.name, u.phone, u.email].filter(Boolean).some((v) => v!.toLowerCase().includes(q.toLowerCase())))
    : users;

  const toggleBlock = (u: AppUser) =>
    updateDoc(doc(db, 'users', u.id), { status: u.status === 'blocked' ? 'active' : 'blocked' });

  // حساب تاجر B2B: يُظهر له فئة تجار الجملة وأسعارها في تطبيق الزبون
  const toggleMerchant = (u: AppUser) =>
    updateDoc(doc(db, 'users', u.id), { merchant: !u.merchant });

  return (
    <>
      <PageHeader title={t('users')} />
      <input className="input max-w-sm mb-4" placeholder={t('search')} value={q} onChange={(e) => setQ(e.target.value)} />

      {loading ? <Spinner /> : filtered.length === 0 ? <EmptyState /> : (
        <Table headers={[t('name'), t('phone'), t('email'), 'Role', 'B2B', t('wallet'), t('status'), t('actions')]}>
          {filtered.map((u) => (
            <tr key={u.id} className="table-row">
              <td className="td font-bold">{u.name ?? '—'}</td>
              <td className="td" dir="ltr">{u.phone ?? '—'}</td>
              <td className="td" dir="ltr">{u.email ?? '—'}</td>
              <td className="td"><span className={`badge ${ROLE_CLS[u.role] ?? ROLE_CLS.customer}`}>{u.role}</span></td>
              <td className="td">
                <button
                  className={`badge ${u.merchant ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-400'}`}
                  title="تاجر جملة B2B"
                  onClick={() => toggleMerchant(u)}
                >
                  🏪 B2B
                </button>
              </td>
              <td className="td tabular-nums">{money(u.walletBalance)}</td>
              <td className="td">
                <span className={`badge ${u.status === 'blocked' ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
                  {u.status === 'blocked' ? t('block') : t('active')}
                </span>
              </td>
              <td className="td">
                <button
                  className={`!py-1.5 !px-3 !text-xs ${u.status === 'blocked' ? 'btn-primary' : 'btn-danger'}`}
                  onClick={() => toggleBlock(u)}
                >
                  {u.status === 'blocked' ? t('unblock') : t('block')}
                </button>
              </td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
