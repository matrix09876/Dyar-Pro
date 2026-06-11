import { useState, type FormEvent } from 'react';
import { addDoc, collection, deleteDoc, doc, updateDoc } from 'firebase/firestore';
import { Plus, Trash2, Settings as SettingsIcon } from 'lucide-react';
import { Link } from 'react-router-dom';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { PageHeader, Table, EmptyState } from '../components/ui';

interface City { id: string; name: string; country: string; active: boolean; }

/** المدن مجمّعة حسب الدولة — مطابق للوحة الحالية مع إضافة/تعطيل/حذف. */
export default function Cities() {
  const { t } = useI18n();
  const { data: cities } = useCol<City>('cities');
  const [showForm, setShowForm] = useState(false);
  const [q, setQ] = useState('');

  const filtered = q
    ? cities.filter((c) => c.name?.toLowerCase().includes(q.toLowerCase()))
    : cities;
  const countries = [...new Set(filtered.map((c) => c.country || '—'))];

  const add = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    await addDoc(collection(db, 'cities'), {
      name: f.get('name'), country: f.get('country'), active: true,
    });
    setShowForm(false);
  };

  return (
    <>
      <PageHeader
        title={t('city')}
        action={<button className="btn-primary" onClick={() => setShowForm(true)}><Plus size={18} /> +</button>}
      />
      <input className="input max-w-sm mb-4" placeholder={t('search')} value={q} onChange={(e) => setQ(e.target.value)} />

      {filtered.length === 0 ? <EmptyState /> : countries.map((country) => (
        <div key={country} className="mb-6">
          <h2 className="font-bold mb-2">{country} · {filtered.filter((c) => (c.country || '—') === country).length}</h2>
          <Table headers={[t('name'), t('status'), t('actions')]}>
            {filtered.filter((c) => (c.country || '—') === country).map((c) => (
              <tr key={c.id} className="table-row">
                <td className="td font-bold">{c.name}</td>
                <td className="td">
                  <button
                    className={`badge ${c.active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}
                    onClick={() => updateDoc(doc(db, 'cities', c.id), { active: !c.active })}
                  >
                    {c.active ? t('active') : '—'}
                  </button>
                </td>
                <td className="td">
                  <Link to={`/cities/${c.id}`} className="btn-ghost !px-2"><SettingsIcon size={18} /></Link>
                  <button className="btn-ghost !px-2 text-red-500" onClick={() => deleteDoc(doc(db, "cities", c.id))}>
                    <Trash2 size={18} />
                  </button>
                </td>
              </tr>
            ))}
          </Table>
        </div>
      ))}

      {showForm && (
        <div className="fixed inset-0 z-50 bg-black/40 grid place-items-center p-4" onClick={() => setShowForm(false)}>
          <form className="card w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()} onSubmit={add}>
            <h2 className="text-lg font-extrabold">{t('city')} +</h2>
            <input className="input" name="name" placeholder={t('name')} required />
            <input className="input" name="country" placeholder="Country" required />
            <div className="flex gap-3">
              <button type="button" className="btn-ghost flex-1" onClick={() => setShowForm(false)}>{t('cancel')}</button>
              <button className="btn-primary flex-1">{t('save')}</button>
            </div>
          </form>
        </div>
      )}
    </>
  );
}
