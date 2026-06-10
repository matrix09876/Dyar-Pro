import { useState, type FormEvent } from 'react';
import { addDoc, collection, deleteDoc, doc, updateDoc, Timestamp } from 'firebase/firestore';
import { Plus, Trash2 } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { money } from '../lib/format';
import { PageHeader, Table, EmptyState } from '../components/ui';

interface Coupon {
  id: string; code: string; type: 'pct' | 'fixed'; value: number;
  minOrder?: number; usageLimit?: number; usedCount?: number;
  expiresAt?: Timestamp; active: boolean;
}
interface Promo { id: string; title: string; image?: string; active: boolean; sortOrder?: number; }
interface GiftCard { id: string; code: string; amount: number; balance: number; status: string; }

type Tab = 'coupons' | 'promotions' | 'giftcards';

export default function Marketing() {
  const { t } = useI18n();
  const [tab, setTab] = useState<Tab>('coupons');
  const { data: coupons } = useCol<Coupon>('coupons');
  const { data: promos } = useCol<Promo>('promotions');
  const { data: cards } = useCol<GiftCard>('giftcards');
  const [showForm, setShowForm] = useState(false);

  const addCoupon = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    await addDoc(collection(db, 'coupons'), {
      code: String(f.get('code')).toUpperCase(),
      type: f.get('type'),
      value: Number(f.get('value')),
      minOrder: Number(f.get('minOrder') || 0),
      usageLimit: Number(f.get('usageLimit') || 1000),
      usedCount: 0,
      active: true,
      expiresAt: Timestamp.fromDate(new Date(String(f.get('expiresAt')))),
    });
    setShowForm(false);
  };

  return (
    <>
      <PageHeader
        title={t('marketing')}
        action={tab === 'coupons' ? (
          <button className="btn-primary" onClick={() => setShowForm(true)}>
            <Plus size={18} /> {t('addCoupon')}
          </button>
        ) : undefined}
      />

      <div className="flex gap-2 mb-5">
        {(['coupons', 'promotions', 'giftcards'] as Tab[]).map((k) => (
          <button
            key={k}
            onClick={() => setTab(k)}
            className={`badge !px-4 !py-2 ${tab === k ? 'bg-brand-600 text-white' : 'bg-gray-100 text-ink-muted dark:bg-gray-800 dark:text-gray-400'}`}
          >
            {t(k)}
          </button>
        ))}
      </div>

      {tab === 'coupons' && (
        coupons.length === 0 ? <EmptyState /> : (
          <Table headers={[t('code'), t('discount'), t('usage'), t('status'), t('actions')]}>
            {coupons.map((c) => (
              <tr key={c.id} className="table-row">
                <td className="td font-mono font-bold">{c.code}</td>
                <td className="td">{c.type === 'pct' ? `${c.value}%` : money(c.value)}</td>
                <td className="td tabular-nums">{c.usedCount ?? 0} / {c.usageLimit ?? '∞'}</td>
                <td className="td">
                  <button
                    className={`badge ${c.active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}
                    onClick={() => updateDoc(doc(db, 'coupons', c.id), { active: !c.active })}
                  >
                    {c.active ? t('active') : '—'}
                  </button>
                </td>
                <td className="td">
                  <button className="btn-ghost !px-2 text-red-500" onClick={() => deleteDoc(doc(db, 'coupons', c.id))}>
                    <Trash2 size={18} />
                  </button>
                </td>
              </tr>
            ))}
          </Table>
        )
      )}

      {tab === 'promotions' && (
        promos.length === 0 ? <EmptyState /> : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {promos.map((p) => (
              <div key={p.id} className="card overflow-hidden">
                {p.image && <img src={p.image} className="h-36 w-full object-cover" alt="" />}
                <div className="p-4 flex items-center justify-between">
                  <span className="font-bold">{p.title}</span>
                  <button
                    className={`badge ${p.active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}
                    onClick={() => updateDoc(doc(db, 'promotions', p.id), { active: !p.active })}
                  >
                    {p.active ? t('active') : '—'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )
      )}

      {tab === 'giftcards' && (
        cards.length === 0 ? <EmptyState /> : (
          <Table headers={[t('code'), t('amount'), 'Balance', t('status')]}>
            {cards.map((g) => (
              <tr key={g.id} className="table-row">
                <td className="td font-mono font-bold">{g.code}</td>
                <td className="td tabular-nums">{money(g.amount)}</td>
                <td className="td tabular-nums">{money(g.balance)}</td>
                <td className="td"><span className="badge bg-gray-100 text-gray-600">{g.status}</span></td>
              </tr>
            ))}
          </Table>
        )
      )}

      {showForm && (
        <div className="fixed inset-0 z-50 bg-black/40 grid place-items-center p-4" onClick={() => setShowForm(false)}>
          <form className="card w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()} onSubmit={addCoupon}>
            <h2 className="text-lg font-extrabold">{t('addCoupon')}</h2>
            <input className="input" name="code" placeholder={t('code')} required dir="ltr" />
            <div className="flex gap-3">
              <select className="input" name="type" defaultValue="pct">
                <option value="pct">%</option>
                <option value="fixed">₪ (agorot)</option>
              </select>
              <input className="input" name="value" type="number" placeholder={t('discount')} required min={1} />
            </div>
            <div className="flex gap-3">
              <input className="input" name="minOrder" type="number" placeholder="Min (agorot)" />
              <input className="input" name="usageLimit" type="number" placeholder={t('usage')} />
            </div>
            <input className="input" name="expiresAt" type="date" required />
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
