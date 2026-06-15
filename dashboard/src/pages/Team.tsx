import { useState } from 'react';
import { orderBy, where } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { ShieldCheck } from 'lucide-react';
import { functions } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { AppUser } from '../types';

// صلاحيات عامل المكتب الدقيقة (تطابق backend StaffPermission)
const PERMISSIONS = [
  'orders.view', 'orders.manage', 'orders.assignDriver',
  'stores.view', 'stores.approve', 'drivers.view', 'drivers.approve',
  'users.view', 'users.block', 'marketing.manage', 'finance.view', 'support.manage',
];

interface StaffUser extends AppUser {
  permissions?: string[];
}

/** دور جاهز: خدمة العملاء — دعم + حل مشاكل الطلبات وتتبعها فقط */
const CS_PRESET = ['support.manage', 'orders.view', 'orders.manage'];

export default function Team() {
  const { t } = useI18n();
  // الموظفون = staff + admin
  const { data: staff, loading } = useCol<StaffUser>(
    'users', where('role', 'in', ['staff', 'admin']), orderBy('role'),
  );
  const [editing, setEditing] = useState<StaffUser | null>(null);
  const [perms, setPerms] = useState<string[]>([]);

  const open = (u: StaffUser) => {
    setEditing(u);
    setPerms(u.permissions ?? []);
  };

  const save = async () => {
    if (!editing) return;
    await httpsCallable(functions, 'setUserRole')({
      uid: editing.id, role: 'staff', permissions: perms,
    });
    setEditing(null);
  };

  const toggle = (p: string) =>
    setPerms((cur) => (cur.includes(p) ? cur.filter((x) => x !== p) : [...cur, p]));

  return (
    <>
      <PageHeader title={t('team')} />
      <p className="text-sm text-ink-muted mb-4">
        {t('adminOnly')} — {t('team')}
      </p>

      {loading ? <Spinner /> : staff.length === 0 ? <EmptyState /> : (
        <Table headers={[t('name'), 'Role', t('email'), t('actions')]}>
          {staff.map((u) => (
            <tr key={u.id} className="table-row">
              <td className="td font-bold">{u.name ?? '—'}</td>
              <td className="td">
                <span className={`badge ${u.role === 'admin' ? 'bg-purple-100 text-purple-700' : 'bg-cyan-100 text-cyan-700'}`}>
                  {u.role}
                </span>
              </td>
              <td className="td" dir="ltr">{u.email ?? '—'}</td>
              <td className="td">
                {u.role === 'staff' && (
                  <button className="btn-primary !py-1.5 !px-3 !text-xs" onClick={() => open(u)}>
                    <ShieldCheck size={14} /> {t('team')}
                  </button>
                )}
              </td>
            </tr>
          ))}
        </Table>
      )}

      {editing && (
        <div className="fixed inset-0 z-50 bg-black/40 grid place-items-center p-4" onClick={() => setEditing(null)}>
          <div className="card w-full max-w-lg p-6" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-extrabold mb-1">{editing.name ?? editing.email}</h2>
            <p className="text-sm text-ink-muted mb-4">{t('team')}</p>
            {/* أدوار جاهزة بنقرة */}
            <div className="flex gap-2 mb-4">
              <button
                type="button"
                className="badge !px-3 !py-1.5 bg-brand-50 text-brand-700 border border-brand-200 hover:bg-brand-100"
                onClick={() => setPerms(CS_PRESET)}
              >
                🎧 {t('csRole')}
              </button>
              <button
                type="button"
                className="badge !px-3 !py-1.5 bg-gray-100 text-ink-muted"
                onClick={() => setPerms([])}
              >
                {t('clearPerms')}
              </button>
            </div>
            <div className="grid grid-cols-2 gap-2 mb-6">
              {PERMISSIONS.map((p) => (
                <label key={p} className="flex items-center gap-2 rounded-xl border border-gray-200 dark:border-gray-700 px-3 py-2 cursor-pointer">
                  <input
                    type="checkbox" className="h-4 w-4 accent-brand-600"
                    checked={perms.includes(p)} onChange={() => toggle(p)}
                  />
                  <span className="text-xs font-mono">{p}</span>
                </label>
              ))}
            </div>
            <div className="flex gap-3">
              <button className="btn-ghost flex-1" onClick={() => setEditing(null)}>{t('cancel')}</button>
              <button className="btn-primary flex-1" onClick={save}>{t('save')}</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
