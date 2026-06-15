import { useState, type FormEvent } from 'react';
import {
  addDoc, collection, deleteDoc, doc, orderBy, serverTimestamp,
  type Timestamp,
} from 'firebase/firestore';
import { Plus, Trash2 } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { dateTime } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';

interface BlockedAddress {
  id: string;
  line: string;
  reason?: string;
  createdAt?: Timestamp;
}

/** العناوين المحظورة (مكافحة الاحتيال) — createOrder يرفض أي طلب
 *  يحتوي عنوانه على سطر من هذه القائمة. */
export default function BlockedAddresses() {
  const { t } = useI18n();
  const { data: addresses, loading } =
    useCol<BlockedAddress>('blockedAddresses', orderBy('createdAt', 'desc'));
  const [showForm, setShowForm] = useState(false);

  const add = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    await addDoc(collection(db, 'blockedAddresses'), {
      line: String(f.get('line') ?? '').trim(),
      reason: String(f.get('reason') ?? '').trim(),
      createdAt: serverTimestamp(),
    });
    setShowForm(false);
  };

  return (
    <>
      <PageHeader
        title={t('blockedAddresses')}
        action={
          <button className="btn-primary" onClick={() => setShowForm(true)}>
            <Plus size={18} /> {t('addAddress')}
          </button>
        }
      />
      <p className="text-sm text-ink-muted mb-4">{t('blockedAddressesHint')}</p>

      {loading ? <Spinner /> : addresses.length === 0 ? <EmptyState /> : (
        <Table headers={[t('addressLine'), t('reason'), t('date'), t('actions')]}>
          {addresses.map((a) => (
            <tr key={a.id} className="table-row">
              <td className="td font-bold">{a.line}</td>
              <td className="td">{a.reason || '—'}</td>
              <td className="td text-ink-muted">{dateTime(a.createdAt)}</td>
              <td className="td">
                <button className="btn-ghost !px-2 text-red-500" title={t('block')}
                  onClick={() => deleteDoc(doc(db, 'blockedAddresses', a.id))}>
                  <Trash2 size={18} />
                </button>
              </td>
            </tr>
          ))}
        </Table>
      )}

      {showForm && (
        <div className="fixed inset-0 z-50 bg-black/40 grid place-items-center p-4"
          onClick={() => setShowForm(false)}>
          <form className="card w-full max-w-md p-6 space-y-4"
            onClick={(e) => e.stopPropagation()} onSubmit={add}>
            <h2 className="text-lg font-extrabold">{t('addAddress')}</h2>
            <input className="input" name="line" placeholder={t('addressLine')} required />
            <input className="input" name="reason" placeholder={t('reason')} />
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
