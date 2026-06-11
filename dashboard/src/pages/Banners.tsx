import { useState, type FormEvent } from 'react';
import { addDoc, collection, deleteDoc, doc, updateDoc } from 'firebase/firestore';
import { Plus, Trash2 } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { PageHeader, EmptyState } from '../components/ui';

/** البانرات — أماكن العرض كما في اللوحة الحالية + هدف (متجر/خصم/بحث). */
interface Banner {
  id: string; image: string; title?: string;
  placement: string; targetType: string; targetValue?: string;
  active: boolean;
}

const PLACEMENTS = ['stories', 'main', 'lower', 'driver',
  'restaurants', 'stores', 'groceries', 'pharmacies', 'services'];

export default function Banners() {
  const { t } = useI18n();
  const [placement, setPlacement] = useState('main');
  const { data: banners } = useCol<Banner>('banners');
  const [showForm, setShowForm] = useState(false);

  const list = banners.filter((b) => b.placement === placement);

  const add = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    await addDoc(collection(db, 'banners'), {
      image: f.get('image'), title: f.get('title') || '',
      placement,
      targetType: f.get('targetType'),
      targetValue: f.get('targetValue') || '',
      active: true,
    });
    setShowForm(false);
  };

  return (
    <>
      <PageHeader
        title="Banners"
        action={<button className="btn-primary" onClick={() => setShowForm(true)}>
          <Plus size={18} /> +
        </button>}
      />
      <div className="flex gap-2 mb-5 flex-wrap">
        {PLACEMENTS.map((p) => (
          <button key={p} onClick={() => setPlacement(p)}
            className={`badge !px-3 !py-1.5 ${placement === p
              ? 'bg-brand-600 text-white'
              : 'bg-gray-100 text-ink-muted dark:bg-gray-800 dark:text-gray-400'}`}>
            {p}
          </button>
        ))}
      </div>

      {list.length === 0 ? <EmptyState /> : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {list.map((b) => (
            <div key={b.id} className="card overflow-hidden">
              <img src={b.image} className="h-32 w-full object-cover" alt="" />
              <div className="p-4 flex items-center justify-between gap-2">
                <div className="min-w-0">
                  <div className="font-bold truncate">{b.title || '—'}</div>
                  <div className="text-xs text-ink-muted">
                    {b.targetType}{b.targetValue ? ` · ${b.targetValue}` : ''}
                  </div>
                </div>
                <div className="flex items-center gap-1">
                  <button
                    className={`badge ${b.active
                      ? 'bg-green-100 text-green-700'
                      : 'bg-gray-200 text-gray-600'}`}
                    onClick={() => updateDoc(doc(db, 'banners', b.id),
                      { active: !b.active })}>
                    {b.active ? t('active') : '—'}
                  </button>
                  <button className="btn-ghost !px-2 text-red-500"
                    onClick={() => deleteDoc(doc(db, 'banners', b.id))}>
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {showForm && (
        <div className="fixed inset-0 z-50 bg-black/40 grid place-items-center p-4"
          onClick={() => setShowForm(false)}>
          <form className="card w-full max-w-md p-6 space-y-4"
            onClick={(e) => e.stopPropagation()} onSubmit={add}>
            <h2 className="text-lg font-extrabold">Banner + · {placement}</h2>
            <input className="input" name="image" placeholder="Image URL" required dir="ltr" />
            <input className="input" name="title" placeholder={t('name')} />
            <div className="flex gap-3">
              <select className="input" name="targetType" defaultValue="none">
                <option value="none">No target</option>
                <option value="business">Business</option>
                <option value="discount">Discount</option>
                <option value="search">Search</option>
              </select>
              <input className="input" name="targetValue"
                placeholder="Business ID / query" dir="ltr" />
            </div>
            <div className="flex gap-3">
              <button type="button" className="btn-ghost flex-1"
                onClick={() => setShowForm(false)}>{t('cancel')}</button>
              <button className="btn-primary flex-1">{t('save')}</button>
            </div>
          </form>
        </div>
      )}
    </>
  );
}
