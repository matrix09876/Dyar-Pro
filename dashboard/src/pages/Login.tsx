import { useState, type FormEvent } from 'react';
import { Lock } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useI18n } from '../lib/i18n';
import { isConfigured } from '../lib/firebase';

export default function Login() {
  const { login } = useAuth();
  const { t } = useI18n();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setError(''); setBusy(true);
    try {
      await login(email, password);
    } catch {
      setError(t('loginError'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen grid place-items-center bg-gradient-to-br from-brand-600 via-brand-500 to-brand-400 p-4">
      <div className="card w-full max-w-md p-8">
        <div className="flex flex-col items-center mb-8">
          <div className="h-16 w-16 rounded-3xl bg-brand-600 text-white grid place-items-center font-extrabold text-3xl mb-4">د</div>
          <h1 className="text-xl font-extrabold">{t('loginTitle')}</h1>
          <p className="text-sm text-ink-muted dark:text-gray-400 mt-1">{t('loginSubtitle')}</p>
        </div>

        {!isConfigured && (
          <div className="mb-4 rounded-xl bg-amber-50 dark:bg-amber-950 text-amber-800 dark:text-amber-200 text-sm p-3">
            {t('notConfigured')}
          </div>
        )}

        <form onSubmit={submit} className="space-y-4">
          <input
            className="input" type="email" placeholder={t('email')}
            value={email} onChange={(e) => setEmail(e.target.value)} required dir="ltr"
          />
          <input
            className="input" type="password" placeholder={t('password')}
            value={password} onChange={(e) => setPassword(e.target.value)} required dir="ltr"
          />
          {error && <div className="text-sm text-red-600 font-semibold">{error}</div>}
          <button className="btn-cta" disabled={busy || !isConfigured}>
            <Lock size={18} /> {t('signIn')}
          </button>
        </form>

        <p className="text-xs text-ink-muted dark:text-gray-500 text-center mt-6">{t('adminOnly')}</p>
      </div>
    </div>
  );
}
