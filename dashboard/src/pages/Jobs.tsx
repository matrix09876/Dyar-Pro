import { useState, type FormEvent } from 'react';
import { addDoc, collection, deleteDoc, doc, updateDoc, Timestamp, orderBy } from 'firebase/firestore';
import { Plus, Trash2 } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { PageHeader, Table, EmptyState } from '../components/ui';

interface Job {
  id: string; title: string; description?: string;
  type: string; status: 'open' | 'closed'; createdAt?: Timestamp;
}

export default function Jobs() {
  const { t } = useI18n();
  const { data: jobs } = useCol<Job>('jobs', orderBy('createdAt', 'desc'));
  const [showForm, setShowForm] = useState(false);

  const addJob = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    await addDoc(collection(db, 'jobs'), {
      title: f.get('title'),
      description: f.get('description'),
      type: f.get('type'),
      status: 'open',
      createdAt: Timestamp.now(),
    });
    setShowForm(false);
  };

  return (
    <>
      <PageHeader
        title={t('jobs')}
        action={<button className="btn-primary" onClick={() => setShowForm(true)}><Plus size={18} /> +</button>}
      />

      {jobs.length === 0 ? <EmptyState /> : (
        <Table headers={[t('name'), t('type'), t('status'), t('actions')]}>
          {jobs.map((j) => (
            <tr key={j.id} className="table-row">
              <td className="td font-bold">{j.title}</td>
              <td className="td">{j.type}</td>
              <td className="td">
                <button
                  className={`badge ${j.status === 'open' ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}
                  onClick={() => updateDoc(doc(db, 'jobs', j.id), { status: j.status === 'open' ? 'closed' : 'open' })}
                >
                  {j.status}
                </button>
              </td>
              <td className="td">
                <button className="btn-ghost !px-2 text-red-500" onClick={() => deleteDoc(doc(db, 'jobs', j.id))}>
                  <Trash2 size={18} />
                </button>
              </td>
            </tr>
          ))}
        </Table>
      )}

      {showForm && (
        <div className="fixed inset-0 z-50 bg-black/40 grid place-items-center p-4" onClick={() => setShowForm(false)}>
          <form className="card w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()} onSubmit={addJob}>
            <h2 className="text-lg font-extrabold">{t('jobs')} +</h2>
            <input className="input" name="title" placeholder={t('name')} required />
            <textarea className="input" name="description" rows={3} placeholder={t('details')} />
            <select className="input" name="type" defaultValue="driver">
              <option value="driver">Driver</option>
              <option value="kitchen">Kitchen</option>
              <option value="service">Service</option>
              <option value="other">Other</option>
            </select>
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
