import { useState } from 'react';
import {
  collection, addDoc, deleteDoc, doc, updateDoc, orderBy, serverTimestamp,
} from 'firebase/firestore';
import { ref as sRef, uploadBytes, getDownloadURL } from 'firebase/storage';
import { Plus, Trash2, Image as ImageIcon, Film, Upload } from 'lucide-react';
import { db, storage } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { PageHeader, EmptyState } from '../components/ui';
import type { Timestamp } from 'firebase/firestore';

interface StoryItem { type: 'image' | 'video'; url: string; durationSec?: number }
interface Story {
  id: string; title: string; ringImage?: string; active?: boolean;
  sortOrder?: number; items?: StoryItem[]; createdAt?: Timestamp;
}

/** إدارة ستوريات ديار (نمط إنستجرام) — رفع فيديو + صور؛ تظهر في الرئيسية. */
export default function Stories() {
  const { t } = useI18n();
  const { data: stories } = useCol<Story>('stories', orderBy('sortOrder'));
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState('');
  const [items, setItems] = useState<StoryItem[]>([]);
  const [busy, setBusy] = useState(false);

  const upload = async (file: File) => {
    setBusy(true);
    try {
      const path = `stories/${Date.now()}_${file.name.replace(/\s+/g, '_')}`;
      const r = sRef(storage, path);
      await uploadBytes(r, file);
      const url = await getDownloadURL(r);
      const type: 'image' | 'video' = file.type.startsWith('video') ? 'video' : 'image';
      setItems((prev) => [...prev, { type, url, durationSec: type === 'image' ? 5 : 0 }]);
    } finally {
      setBusy(false);
    }
  };

  const save = async () => {
    if (!title.trim() || items.length === 0) return;
    await addDoc(collection(db, 'stories'), {
      title: title.trim(),
      ringImage: items.find((i) => i.type === 'image')?.url ?? items[0].url,
      items,
      active: true,
      sortOrder: stories.length,
      createdAt: serverTimestamp(),
    });
    setTitle(''); setItems([]); setOpen(false);
  };

  return (
    <>
      <PageHeader title={t('stories')}
        action={
          <button className="btn-primary" onClick={() => setOpen(true)}>
            <Plus size={18} /> {t('addStory')}
          </button>
        }
      />
      {stories.length === 0 ? <EmptyState /> : (
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
          {stories.map((st) => (
            <div key={st.id} className="card overflow-hidden">
              <div className="relative h-40 bg-gray-100 dark:bg-gray-800">
                {st.ringImage && <img src={st.ringImage} className="h-full w-full object-cover" alt="" />}
                <div className="absolute top-2 start-2 flex gap-1">
                  {(st.items ?? []).slice(0, 4).map((it, i) => (
                    <span key={i} className="badge bg-black/60 text-white !px-1.5">
                      {it.type === 'video' ? <Film size={11} /> : <ImageIcon size={11} />}
                    </span>
                  ))}
                </div>
              </div>
              <div className="p-3 flex items-center justify-between">
                <span className="font-bold text-sm truncate">{st.title}</span>
                <div className="flex gap-1">
                  <button
                    className={`badge ${st.active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-500'}`}
                    onClick={() => updateDoc(doc(db, 'stories', st.id), { active: !st.active })}
                  >
                    {st.active ? t('active') : '—'}
                  </button>
                  <button className="btn-ghost !px-2 text-red-500" onClick={() => deleteDoc(doc(db, 'stories', st.id))}>
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {open && (
        <div className="fixed inset-0 z-50 bg-black/40 grid place-items-center p-4" onClick={() => setOpen(false)}>
          <div className="card w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-extrabold">{t('addStory')}</h2>
            <input className="input" placeholder={t('name')} value={title} onChange={(e) => setTitle(e.target.value)} />

            <div className="flex flex-wrap gap-2">
              {items.map((it, i) => (
                <div key={i} className="relative h-16 w-16 rounded-xl overflow-hidden bg-gray-100">
                  {it.type === 'image'
                    ? <img src={it.url} className="h-full w-full object-cover" alt="" />
                    : <div className="h-full w-full grid place-items-center text-ink-muted"><Film size={20} /></div>}
                  <button className="absolute top-0.5 end-0.5 bg-black/60 text-white rounded-full p-0.5"
                    onClick={() => setItems(items.filter((_, x) => x !== i))}>
                    <Trash2 size={11} />
                  </button>
                </div>
              ))}
              <label className="h-16 w-16 rounded-xl border-2 border-dashed border-gray-300 grid place-items-center cursor-pointer text-ink-muted hover:border-brand-400">
                {busy ? '...' : <Upload size={18} />}
                <input type="file" accept="image/*,video/*" className="hidden"
                  onChange={(e) => { const f = e.target.files?.[0]; if (f) upload(f); }} />
              </label>
            </div>
            <p className="text-xs text-ink-muted">{t('storyHint')}</p>

            <div className="flex gap-3">
              <button className="btn-ghost flex-1" onClick={() => setOpen(false)}>{t('cancel')}</button>
              <button className="btn-primary flex-1" disabled={busy || !title.trim() || items.length === 0} onClick={save}>
                {t('save')}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
