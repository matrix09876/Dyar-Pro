import { addDoc, collection, deleteDoc, doc, updateDoc } from 'firebase/firestore';
import { Plus, X } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { PageHeader } from '../components/ui';

interface Faq {
  id: string;
  audience: string; // about|users|drivers|businesses
  question: string;
  answer: string;
  active: boolean;
}

const COLUMNS = ['about', 'users', 'drivers', 'businesses'];

/** التدريب/الأسئلة الشائعة — أعمدة بحسب الجمهور، تُعرض داخل التطبيقات. */
export default function Training() {
  const { t } = useI18n();
  const { data: faqs } = useCol<Faq>('faq');

  const add = async (audience: string) => {
    const question = prompt('Q?');
    if (!question) return;
    const answer = prompt('A?') ?? '';
    await addDoc(collection(db, 'faq'), { audience, question, answer, active: true });
  };

  return (
    <>
      <PageHeader title="Training / FAQ" />
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        {COLUMNS.map((col) => (
          <div key={col} className="card p-4">
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-bold capitalize">{col}</h2>
              <button className="btn-ghost !p-1.5" onClick={() => add(col)}><Plus size={18} /></button>
            </div>
            <div className="space-y-2">
              {faqs.filter((f) => f.audience === col).map((f) => (
                <div key={f.id} className="rounded-xl border border-gray-100 dark:border-gray-800 p-3 text-sm relative">
                  <div className="font-bold mb-1 pe-6">{f.question}</div>
                  <div className="text-ink-muted text-xs">{f.answer}</div>
                  <div className="mt-2">
                    <button
                      className={`badge ${f.active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}
                      onClick={() => updateDoc(doc(db, 'faq', f.id), { active: !f.active })}
                    >
                      {f.active ? t('active') : '—'}
                    </button>
                  </div>
                  <button
                    className="absolute top-2 end-2 text-ink-muted hover:text-red-500"
                    onClick={() => deleteDoc(doc(db, 'faq', f.id))}
                  >
                    <X size={14} />
                  </button>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
