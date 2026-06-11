import { useState, type FormEvent } from 'react';
import { orderBy, limit, type Timestamp } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { Megaphone } from 'lucide-react';
import { functions } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { dateTime } from '../lib/format';
import { PageHeader, Table, EmptyState, Spinner } from '../components/ui';

type Audience = 'customers' | 'drivers' | 'partners' | 'uid';

interface BroadcastDoc {
  id: string;
  title: string;
  body: string;
  audience: Audience;
  uid?: string | null;
  sentBy: string;
  sentCount?: number;
  createdAt?: Timestamp;
}

const AUD_CLS: Record<Audience, string> = {
  customers: 'bg-green-100 text-green-700',
  drivers: 'bg-cyan-100 text-cyan-700',
  partners: 'bg-blue-100 text-blue-700',
  uid: 'bg-purple-100 text-purple-700',
};

/** بث الإشعارات — يرسل عبر sendBroadcast (FCM topics role-*) ويعرض السجل. */
export default function Broadcast() {
  const { t } = useI18n();
  const { data: history, loading } = useCol<BroadcastDoc>(
    'broadcasts', orderBy('createdAt', 'desc'), limit(100));

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [audience, setAudience] = useState<Audience>('customers');
  const [uid, setUid] = useState('');
  const [sending, setSending] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState('');

  const audLabel: Record<Audience, string> = {
    customers: t('audCustomers'), drivers: t('audDrivers'),
    partners: t('audPartners'), uid: t('audSingle'),
  };

  const send = async (e: FormEvent) => {
    e.preventDefault();
    setSending(true); setError(''); setDone(false);
    try {
      await httpsCallable(functions, 'sendBroadcast')({
        title, body, audience, ...(audience === 'uid' ? { uid: uid.trim() } : {}),
      });
      setTitle(''); setBody(''); setUid('');
      setDone(true);
      setTimeout(() => setDone(false), 2500);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setSending(false);
    }
  };

  return (
    <>
      <PageHeader title={t('broadcast')} />

      {/* المُنشئ */}
      <form onSubmit={send} className="card p-6 max-w-xl space-y-4 mb-6">
        <div className="flex items-center gap-2 font-extrabold">
          <Megaphone size={20} className="text-brand-600" /> {t('send')}
        </div>
        <label className="block">
          <span className="text-sm font-bold">{t('bcTitle')}</span>
          <input className="input mt-1" value={title} required maxLength={120}
            onChange={(e) => setTitle(e.target.value)} />
        </label>
        <label className="block">
          <span className="text-sm font-bold">{t('bcBody')}</span>
          <textarea className="input mt-1 min-h-[90px]" value={body} required
            maxLength={1000} onChange={(e) => setBody(e.target.value)} />
        </label>

        <div>
          <span className="text-sm font-bold">{t('audience')}</span>
          <div className="mt-2 grid grid-cols-2 gap-2">
            {(['customers', 'drivers', 'partners', 'uid'] as Audience[]).map((a) => (
              <label key={a}
                className={`flex items-center gap-2 rounded-xl border px-3 py-2 cursor-pointer text-sm font-bold ${
                  audience === a
                    ? 'border-brand-600 bg-brand-50 dark:bg-brand-950'
                    : 'border-gray-200 dark:border-gray-700'
                }`}>
                <input type="radio" name="audience" className="accent-brand-600"
                  checked={audience === a} onChange={() => setAudience(a)} />
                {audLabel[a]}
              </label>
            ))}
          </div>
        </div>

        {audience === 'uid' && (
          <input className="input" dir="ltr" placeholder="uid…" value={uid}
            required onChange={(e) => setUid(e.target.value)} />
        )}

        {error && <p className="text-sm text-red-600">{error}</p>}
        <button className="btn-cta" disabled={sending}>
          {sending ? t('loading') : done ? t('sent') : t('send')}
        </button>
      </form>

      {/* السجل */}
      <h2 className="font-extrabold mb-3">{t('history')}</h2>
      {loading ? <Spinner /> : history.length === 0 ? <EmptyState /> : (
        <Table headers={[t('date'), t('bcTitle'), t('bcBody'), t('audience'), t('sentBy')]}>
          {history.map((b) => (
            <tr key={b.id} className="table-row">
              <td className="td text-ink-muted whitespace-nowrap">{dateTime(b.createdAt)}</td>
              <td className="td font-bold">{b.title}</td>
              <td className="td max-w-xs truncate">{b.body}</td>
              <td className="td">
                <span className={`badge ${AUD_CLS[b.audience] ?? 'bg-gray-100 text-gray-600'}`}>
                  {audLabel[b.audience] ?? b.audience}
                  {b.audience === 'uid' && b.uid ? ` · ${b.uid.slice(0, 8)}…` : ''}
                </span>
              </td>
              <td className="td font-mono text-xs">{b.sentBy?.slice(0, 10)}…</td>
            </tr>
          ))}
        </Table>
      )}
    </>
  );
}
