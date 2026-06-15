import { useState, type FormEvent } from 'react';
import { collection, addDoc, deleteDoc, doc, updateDoc, orderBy, serverTimestamp } from 'firebase/firestore';
import { Plus, Trash2, Building } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money } from '../lib/format';
import { PageHeader, Table, EmptyState } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';

interface Org {
  id: string; name: string; active?: boolean;
  budget?: { amount: number; period: 'daily' | 'monthly' };
  members?: string[]; createdAt?: Timestamp;
}

/** ديار Meals — إدارة الشركات وميزانيات وجبات موظفيها (نمط 10bis/Cibus). */
export default function Companies() {
  const { t } = useI18n();
  const { data: orgs } = useCol<Org>('organizations', orderBy('createdAt', 'desc'));
  const [open, setOpen] = useState(false);

  const add = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    const members = String(f.get('members') || '')
      .split(/[\s,]+/).filter(Boolean);
    await addDoc(collection(db, 'organizations'), {
      name: String(f.get('name')),
      budget: {
        amount: Math.round(Number(f.get('amount') || 0) * 100), // ₪→أغورة
        period: f.get('period') || 'daily',
      },
      members,
      active: true,
      createdAt: serverTimestamp(),
    });
    setOpen(false);
  };

  return (
    <>
      <PageHeader title={t('companies')}
        action={<button className="btn-primary" onClick={() => setOpen(true)}><Plus size={18} /> {t('addCompany')}</button>} />
      <p className="text-sm text-ink-muted mb-5">{t('companiesHint')}</p>
      {orgs.length === 0 ? <EmptyState /> : (
        <Table headers={[t('name'), t('mealBudget'), t('period'), 'الموظفون', t('status'), t('actions')]}>
          {orgs.map((o) => (
            <tr key={o.id} className="table-row">
              <td className="td font-bold"><Building size={14} className="inline me-1 text-brand-500" />{o.name}</td>
              <td className="td tabular-nums">{money(o.budget?.amount)}</td>
              <td className="td">{o.budget?.period === 'monthly' ? t('monthly') : t('daily')}</td>
              <td className="td tabular-nums">{o.members?.length ?? 0}</td>
              <td className="td">
                <button className={`badge ${o.active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-500'}`}
                  onClick={() => updateDoc(doc(db, 'organizations', o.id), { active: !o.active })}>
                  {o.active ? t('active') : '—'}
                </button>
              </td>
              <td className="td">
                <button className="btn-ghost !px-2 text-red-500" onClick={() => deleteDoc(doc(db, 'organizations', o.id))}>
                  <Trash2 size={16} />
                </button>
              </td>
            </tr>
          ))}
        </Table>
      )}

      {open && (
        <div className="fixed inset-0 z-50 bg-black/40 grid place-items-center p-4" onClick={() => setOpen(false)}>
          <form className="card w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()} onSubmit={add}>
            <h2 className="text-lg font-extrabold">{t('addCompany')}</h2>
            <input className="input" name="name" placeholder={t('name')} required />
            <div className="flex gap-3">
              <input className="input" name="amount" type="number" min={0} step="0.5" placeholder="₪ / موظف" required />
              <select className="input" name="period" defaultValue="daily">
                <option value="daily">{t('daily')}</option>
                <option value="monthly">{t('monthly')}</option>
              </select>
            </div>
            <textarea className="input" name="members" rows={3} placeholder="UIDs الموظفين (سطر/فاصلة)" dir="ltr" />
            <div className="flex gap-3">
              <button type="button" className="btn-ghost flex-1" onClick={() => setOpen(false)}>{t('cancel')}</button>
              <button className="btn-primary flex-1">{t('save')}</button>
            </div>
          </form>
        </div>
      )}
    </>
  );
}
