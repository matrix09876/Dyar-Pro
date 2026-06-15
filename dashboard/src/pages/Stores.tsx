import {
  orderBy, doc, updateDoc, addDoc, collection, serverTimestamp, arrayUnion, arrayRemove,
} from 'firebase/firestore';
import { Copy, Download, Star, BadgeCheck } from 'lucide-react';
import { auth, db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { exportCsv } from '../lib/csv';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';
import type { Store } from '../types';

const STORE_STATUS_CLS: Record<Store['status'], string> = {
  pending: 'bg-amber-100 text-amber-700',
  approved: 'bg-green-100 text-green-700',
  suspended: 'bg-red-100 text-red-700',
};

// وسوم الحِمية/التصديق (تطابق dyar_core kDietaryTags)
const DIET_TAGS: { key: string; emoji: string }[] = [
  { key: 'halal', emoji: '☪️' }, { key: 'kosher', emoji: '✡️' },
  { key: 'vegetarian', emoji: '🥗' }, { key: 'vegan', emoji: '🌱' },
  { key: 'glutenFree', emoji: '🌾' }, { key: 'spicy', emoji: '🌶️' },
];

export default function Stores() {
  const { t } = useI18n();
  const { data: stores, loading } = useCol<Store>('stores', orderBy('createdAt', 'desc'));

  const setStatus = (s: Store, status: Store['status']) =>
    updateDoc(doc(db, 'stores', s.id), { status });

  const setCommission = async (s: Store) => {
    const v = prompt(`${t('commission')} — ${s.name}`, String(s.commissionPct ?? 10));
    if (v == null) return;
    const pct = Number(v);
    if (Number.isFinite(pct) && pct >= 0 && pct <= 50) {
      await updateDoc(doc(db, 'stores', s.id), { commissionPct: pct });
    }
  };

  const statusLabel: Record<Store['status'], string> = {
    pending: t('pendingApproval'), approved: t('approved'), suspended: t('suspended'),
  };

  // تبديل وسم حِمية (التاجر يصرّح؛ هنا تحرير إداري)
  const toggleDiet = (s: Store, key: string) =>
    updateDoc(doc(db, 'stores', s.id), {
      dietary: (s.dietary ?? []).includes(key) ? arrayRemove(key) : arrayUnion(key),
    });
  // توثيق الحلال/الكوشير (admin فقط — تظهر ✓ للزبون)
  const toggleVerified = (s: Store) =>
    updateDoc(doc(db, 'stores', s.id), { dietaryVerified: !s.dietaryVerified });

  // نسخ النشاط: متجر جديد بنفس البيانات بحالة pending + سجل تدقيق
  const duplicate = async (s: Store) => {
    const { id: _id, ...rest } = s;
    void _id;
    const copy = await addDoc(collection(db, 'stores'), {
      ...rest,
      name: `${s.name} (نسخة)`,
      status: 'pending',
      rating: 0,
      ratingCount: 0,
      createdAt: serverTimestamp(),
    });
    const by = auth.currentUser?.uid;
    if (by) {
      await addDoc(collection(db, 'logs'), {
        category: 'business',
        action: `duplicate store ${s.id} → ${copy.id}`,
        entity: copy.id, by, until: null, createdAt: serverTimestamp(),
      });
    }
  };

  const downloadCsv = () =>
    exportCsv('stores',
      [t('name'), t('storeType'), t('city'), t('rating'), t('commission'), t('status')],
      stores.map((s) => [
        s.name, s.type, s.cityId ?? '', s.rating ?? '',
        s.commissionPct ?? 10, s.status,
      ]));

  return (
    <>
      <PageHeader
        title={t('stores')}
        action={
          <button className="btn-ghost" onClick={downloadCsv}>
            <Download size={18} /> CSV
          </button>
        }
      />
      {loading ? <Spinner /> : stores.length === 0 ? <EmptyState /> : (
        <Table headers={[t('name'), t('storeType'), t('rating'), t('dietaryFilter'), t('commission'), t('status'), t('actions')]}>
          {stores.map((s) => (
            <tr key={s.id} className="table-row">
              <td className="td font-bold">
                <div className="flex items-center gap-3">
                  {s.logoUrl
                    ? <img src={s.logoUrl} className="h-9 w-9 rounded-xl object-cover" alt="" />
                    : <div className="h-9 w-9 rounded-xl bg-brand-100 dark:bg-brand-950 grid place-items-center text-brand-600 font-extrabold">{s.name?.[0]}</div>}
                  <div>
                    {s.name}
                    <div className={`text-xs font-normal ${s.isOpen ? 'text-green-600' : 'text-ink-muted'}`}>
                      {s.isOpen ? t('open') : t('closed')}
                    </div>
                  </div>
                </div>
              </td>
              <td className="td">{s.type}</td>
              <td className="td">
                <span className="inline-flex items-center gap-1">
                  <Star size={14} className="text-amber-500 fill-amber-500" />
                  {s.rating ?? '—'} ({s.ratingCount ?? 0})
                </span>
              </td>
              <td className="td">
                <div className="flex flex-wrap gap-1 max-w-[200px]">
                  {DIET_TAGS.map((tag) => {
                    const on = (s.dietary ?? []).includes(tag.key);
                    return (
                      <button
                        key={tag.key}
                        title={tag.key}
                        onClick={() => toggleDiet(s, tag.key)}
                        className={`badge !px-1.5 !py-0.5 !text-xs ${on ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-400'}`}
                      >
                        {tag.emoji}
                      </button>
                    );
                  })}
                  <button
                    title="توثيق الحلال/الكوشير (✓)"
                    onClick={() => toggleVerified(s)}
                    className={`badge !px-1.5 !py-0.5 ${s.dietaryVerified ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-400'}`}
                  >
                    <BadgeCheck size={13} />
                  </button>
                </div>
              </td>
              <td className="td">
                <button className="font-bold text-brand-600" onClick={() => setCommission(s)}>
                  {s.commissionPct ?? 10}%
                </button>
              </td>
              <td className="td"><span className={`badge ${STORE_STATUS_CLS[s.status]}`}>{statusLabel[s.status]}</span></td>
              <td className="td">
                <div className="flex gap-2">
                  {s.status !== 'approved' && (
                    <button className="btn-primary !py-1.5 !px-3 !text-xs" onClick={() => setStatus(s, 'approved')}>
                      {t('approve')}
                    </button>
                  )}
                  {s.status === 'approved' && (
                    <button className="btn-danger !py-1.5 !px-3 !text-xs" onClick={() => setStatus(s, 'suspended')}>
                      {t('suspend')}
                    </button>
                  )}
                  <button className="btn-ghost !py-1.5 !px-3 !text-xs" title={t('duplicate')}
                    onClick={() => duplicate(s)}>
                    <Copy size={14} /> {t('duplicate')}
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
