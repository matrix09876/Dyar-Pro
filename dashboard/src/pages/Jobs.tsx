import { Fragment, useMemo, useState, type FormEvent } from 'react';
import { addDoc, collection, deleteDoc, doc, updateDoc, Timestamp, orderBy } from 'firebase/firestore';
import { ChevronDown, ChevronUp, Plus, Trash2, UserCheck, UserX, Star } from 'lucide-react';
import { db } from '../lib/firebase';
import { useCol } from '../hooks/useCol';
import { useI18n } from '../lib/i18n';
import { PageHeader, Table, EmptyState } from '../components/ui';

interface Job {
  id: string; title: string; description?: string;
  type: string; status: 'open' | 'closed'; createdAt?: Timestamp;
}

type AppStatus = 'new' | 'shortlisted' | 'rejected' | 'hired';

interface JobApplication {
  id: string; jobId: string; jobTitle?: string; applicantUid: string;
  name: string; phone: string; cvText: string; cvUrl?: string;
  status: AppStatus; createdAt?: Timestamp;
}

const APP_STATUS_COLORS: Record<AppStatus, string> = {
  new: 'bg-blue-100 text-blue-700',
  shortlisted: 'bg-amber-100 text-amber-700',
  rejected: 'bg-red-100 text-red-700',
  hired: 'bg-green-100 text-green-700',
};

export default function Jobs() {
  const { t } = useI18n();
  const { data: jobs } = useCol<Job>('jobs', orderBy('createdAt', 'desc'));
  const { data: applications } = useCol<JobApplication>('jobApplications', orderBy('createdAt', 'desc'));
  const [showForm, setShowForm] = useState(false);
  const [openJobId, setOpenJobId] = useState<string | null>(null);

  // تجميع المتقدمين حسب الوظيفة (عدّاد + قائمة الصف الموسّع)
  const appsByJob = useMemo(() => {
    const m = new Map<string, JobApplication[]>();
    for (const a of applications) {
      const list = m.get(a.jobId) ?? [];
      list.push(a);
      m.set(a.jobId, list);
    }
    return m;
  }, [applications]);

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

  const setAppStatus = (id: string, status: AppStatus) =>
    updateDoc(doc(db, 'jobApplications', id), { status });

  return (
    <>
      <PageHeader
        title={t('jobs')}
        action={<button className="btn-primary" onClick={() => setShowForm(true)}><Plus size={18} /> +</button>}
      />

      {jobs.length === 0 ? <EmptyState /> : (
        <Table headers={[t('name'), t('type'), t('applicants'), t('status'), t('actions')]}>
          {jobs.map((j) => {
            const apps = appsByJob.get(j.id) ?? [];
            const isOpen = openJobId === j.id;
            return (
              <Fragment key={j.id}>
                <tr className="table-row cursor-pointer" onClick={() => setOpenJobId(isOpen ? null : j.id)}>
                  <td className="td font-bold">
                    <span className="inline-flex items-center gap-2">
                      {isOpen ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
                      {j.title}
                    </span>
                  </td>
                  <td className="td">{j.type}</td>
                  <td className="td">
                    <span className="badge bg-blue-100 text-blue-700 tabular-nums">
                      {apps.length}
                      {apps.some((a) => a.status === 'new') && (
                        <span className="ms-1.5 inline-block h-2 w-2 rounded-full bg-blue-600" />
                      )}
                    </span>
                  </td>
                  <td className="td">
                    <button
                      className={`badge ${j.status === 'open' ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}
                      onClick={(e) => {
                        e.stopPropagation();
                        updateDoc(doc(db, 'jobs', j.id), { status: j.status === 'open' ? 'closed' : 'open' });
                      }}
                    >
                      {j.status}
                    </button>
                  </td>
                  <td className="td">
                    <button
                      className="btn-ghost !px-2 text-red-500"
                      onClick={(e) => { e.stopPropagation(); deleteDoc(doc(db, 'jobs', j.id)); }}
                    >
                      <Trash2 size={18} />
                    </button>
                  </td>
                </tr>

                {/* الصف الموسّع: قائمة المتقدمين + CV + إجراءات الحالة */}
                {isOpen && (
                  <tr>
                    <td colSpan={5} className="bg-gray-50 dark:bg-gray-900/40 px-6 py-4">
                      <div className="font-extrabold mb-3">{t('applicants')} ({apps.length})</div>
                      {apps.length === 0 ? (
                        <div className="text-ink-muted dark:text-gray-500 py-2">{t('noApplicants')}</div>
                      ) : (
                        <div className="space-y-3">
                          {apps.map((a) => (
                            <div key={a.id} className="card p-4">
                              <div className="flex flex-wrap items-center gap-3">
                                <div className="font-bold">{a.name}</div>
                                <a dir="ltr" className="text-sm text-ink-muted dark:text-gray-400" href={`tel:${a.phone}`}>{a.phone}</a>
                                <span className={`badge ${APP_STATUS_COLORS[a.status] ?? 'bg-gray-100 text-gray-600'}`}>
                                  {t(`st_${a.status}`)}
                                </span>
                                <div className="ms-auto flex gap-2">
                                  {a.status !== 'shortlisted' && a.status !== 'hired' && (
                                    <button
                                      className="btn-ghost !px-2.5 text-amber-600"
                                      title={t('shortlist')}
                                      onClick={() => setAppStatus(a.id, 'shortlisted')}
                                    >
                                      <Star size={17} /> {t('shortlist')}
                                    </button>
                                  )}
                                  {a.status !== 'rejected' && a.status !== 'hired' && (
                                    <button
                                      className="btn-ghost !px-2.5 text-red-500"
                                      title={t('reject')}
                                      onClick={() => setAppStatus(a.id, 'rejected')}
                                    >
                                      <UserX size={17} /> {t('reject')}
                                    </button>
                                  )}
                                  {a.status !== 'hired' && (
                                    <button
                                      className="btn-ghost !px-2.5 text-green-600"
                                      title={t('hire')}
                                      onClick={() => setAppStatus(a.id, 'hired')}
                                    >
                                      <UserCheck size={17} /> {t('hire')}
                                    </button>
                                  )}
                                </div>
                              </div>
                              {a.cvText && (
                                <div className="mt-3">
                                  <div className="text-xs font-bold text-ink-muted dark:text-gray-400 mb-1">{t('cv')}</div>
                                  <p className="text-sm whitespace-pre-wrap leading-relaxed">{a.cvText}</p>
                                </div>
                              )}
                              {a.cvUrl && (
                                <a
                                  href={a.cvUrl}
                                  target="_blank"
                                  rel="noreferrer"
                                  className="mt-2 inline-block text-sm font-bold text-brand-600 underline"
                                >
                                  {t('cv')} ↗
                                </a>
                              )}
                            </div>
                          ))}
                        </div>
                      )}
                    </td>
                  </tr>
                )}
              </Fragment>
            );
          })}
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
