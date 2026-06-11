import { useState } from 'react';
import { addDoc, collection, deleteDoc, doc, Timestamp } from 'firebase/firestore';
import { Plus, X } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { PageHeader, EmptyState } from '../components/ui';

interface City { id: string; name: string; }
interface Note { id: string; cityId: string; text: string; createdAt?: Timestamp; }

/** ملاحظات كانبان: عمود لكل مدينة — مطابق للوحة الحالية. */
export default function Notes() {
  const { t } = useI18n();
  const { data: cities } = useCol<City>('cities');
  const { data: notes } = useCol<Note>('notes');
  const [q, setQ] = useState('');

  const visibleCities = q
    ? cities.filter((c) => c.name?.toLowerCase().includes(q.toLowerCase()))
    : cities;

  const addNote = async (cityId: string) => {
    const text = prompt(t('details'));
    if (text) {
      await addDoc(collection(db, 'notes'), { cityId, text, createdAt: Timestamp.now() });
    }
  };

  return (
    <>
      <PageHeader title="Notes" />
      <input className="input max-w-sm mb-4" placeholder={t('search')} value={q} onChange={(e) => setQ(e.target.value)} />

      {visibleCities.length === 0 ? <EmptyState /> : (
        <div className="flex gap-4 overflow-x-auto pb-4">
          {visibleCities.map((c) => (
            <div key={c.id} className="card p-4 w-72 shrink-0">
              <div className="flex items-center justify-between mb-3">
                <h2 className="font-bold">{c.name}</h2>
                <button className="btn-ghost !p-1.5" onClick={() => addNote(c.id)}>
                  <Plus size={18} />
                </button>
              </div>
              <div className="space-y-2">
                {notes.filter((n) => n.cityId === c.id).map((n) => (
                  <div key={n.id} className="rounded-xl bg-amber-50 dark:bg-amber-950/40 p-3 text-sm relative">
                    {n.text}
                    <button
                      className="absolute top-1.5 end-1.5 text-ink-muted hover:text-red-500"
                      onClick={() => deleteDoc(doc(db, 'notes', n.id))}
                    >
                      <X size={14} />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
