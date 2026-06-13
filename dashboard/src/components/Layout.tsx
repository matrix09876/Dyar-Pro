import { NavLink, Outlet } from 'react-router-dom';
import {
  LayoutDashboard, ReceiptText, CarTaxiFront, Package, CalendarCheck,
  Store, Bike, Users, BadgePercent, Wallet, Briefcase, Headset, Settings,
  Moon, Sun, LogOut, Globe, ShieldCheck, Building2, StickyNote, ScrollText,
  GraduationCap, Image, ShoppingBag, Megaphone, Ban, BarChart3, ToggleRight, Radar, Clapperboard,
  FileText,
} from 'lucide-react';
import { where } from 'firebase/firestore';
import { useAuth } from '../context/AuthContext';
import { useCol } from '../hooks/useCol';
import { useI18n, type Lang } from '../lib/i18n';

// أيقونات Lucide وفق Icon Mapping في الـ Handoff (stroke 1.8 · 22-24px)
const NAV = [
  { to: '/', key: 'overview', icon: LayoutDashboard },
  { to: '/orders', key: 'orders', icon: ReceiptText },
  { to: '/live', key: 'liveTracking', icon: Radar },
  { to: '/rides', key: 'rides', icon: CarTaxiFront },
  { to: '/parcels', key: 'parcels', icon: Package },
  { to: '/bookings', key: 'bookings', icon: CalendarCheck },
  { to: '/stores', key: 'stores', icon: Store },
  { to: '/marketplace', key: 'marketplace', icon: ShoppingBag },
  { to: '/drivers', key: 'drivers', icon: Bike },
  { to: '/users', key: 'users', icon: Users },
  { to: '/marketing', key: 'marketing', icon: BadgePercent },
  { to: '/finance', key: 'finance', icon: Wallet },
  { to: '/reports', key: 'reports', icon: BarChart3 },
  { to: '/jobs', key: 'jobs', icon: Briefcase },
  { to: '/support', key: 'support', icon: Headset },
  { to: '/cities', key: 'city', icon: Building2 },
  { to: '/companies', key: 'companies', icon: Building2 },
  { to: '/rfqs', key: 'rfqs', icon: FileText },
  { to: '/notes', key: 'notes', icon: StickyNote },
  { to: '/banners', key: 'banners', icon: Image },
  { to: '/stories', key: 'stories', icon: Clapperboard },
  { to: '/broadcast', key: 'broadcast', icon: Megaphone },
  { to: '/blocked-addresses', key: 'blockedAddresses', icon: Ban },
  { to: '/training', key: 'training', icon: GraduationCap },
  { to: '/logs', key: 'logs', icon: ScrollText },
  { to: '/team', key: 'team', icon: ShieldCheck },
  { to: '/features', key: 'features', icon: ToggleRight },
  { to: '/settings', key: 'settings', icon: Settings },
];

// أي صلاحية staff تفتح أي بنود قائمة؟ admin يرى الكل.
// خدمة العملاء (support.manage + orders.*) ترى الدعم والطلبات فقط.
const PERM_NAV: Record<string, string[]> = {
  'orders.view': ['orders', 'liveTracking'], 'orders.manage': ['orders', 'liveTracking'],
  'orders.assignDriver': ['orders'],
  'stores.view': ['stores'], 'stores.approve': ['stores'],
  'drivers.view': ['drivers'], 'drivers.approve': ['drivers'],
  'users.view': ['users'], 'users.block': ['users'],
  'marketing.manage': ['marketing', 'banners', 'stories'],
  'finance.view': ['finance', 'reports'],
  'support.manage': ['support'],
  broadcast: ['broadcast'],
  jobs: ['jobs'],
};

const LANGS: { code: Lang; label: string }[] = [
  { code: 'ar', label: 'العربية' },
  { code: 'he', label: 'עברית' },
  { code: 'en', label: 'English' },
];

export default function Layout() {
  const { logout, user, role, perms } = useAuth();
  const { t, lang, setLang, dark, toggleDark } = useI18n();

  // شارات تنبيه حية (كاللوحة المرجعية): تسجيلات مندوبين معلقة +
  // محادثات دعم مفتوحة + متاجر بانتظار الموافقة
  const { data: pendingDrivers } = useCol<{ id: string }>('drivers', where('status', '==', 'pending'));
  const { data: openTickets } = useCol<{ id: string }>('support', where('status', '==', 'open'));
  const { data: pendingStores } = useCol<{ id: string }>('stores', where('status', '==', 'pending'));
  const NAV_BADGES: Record<string, number> = {
    drivers: pendingDrivers.length,
    support: openTickets.length,
    stores: pendingStores.length,
  };

  // staff يرى فقط بنود صلاحياته (admin: القائمة كاملة)
  const visibleNav = role === 'staff'
    ? NAV.filter(({ key }) =>
        perms.some((p) => (PERM_NAV[p] ?? []).includes(key)))
    : NAV;

  return (
    <div className="min-h-screen flex">
      {/* الشريط الجانبي — start-aligned يعمل RTL/LTR تلقائيًا */}
      <aside className="w-64 shrink-0 bg-white dark:bg-surface-card border-e border-gray-100 dark:border-gray-800 flex flex-col">
        <div className="p-5 flex items-center gap-3">
          <div className="h-10 w-10 rounded-2xl bg-brand-600 text-white grid place-items-center font-extrabold text-lg">د</div>
          <div>
            <div className="font-extrabold leading-tight">{t('appName')}</div>
            <div className="text-xs text-ink-muted dark:text-gray-400">{t('adminPanel')}</div>
          </div>
        </div>

        <nav className="flex-1 px-3 space-y-0.5 overflow-y-auto">
          {visibleNav.map(({ to, key, icon: Icon }) => (
            <NavLink
              key={to} to={to} end={to === '/'}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors ${
                  isActive
                    ? 'bg-brand-50 text-brand-700 dark:bg-brand-950 dark:text-brand-300'
                    : 'text-ink-muted hover:bg-gray-50 dark:text-gray-400 dark:hover:bg-gray-800'
                }`}
            >
              <Icon size={22} strokeWidth={1.8} />
              <span className="flex-1">{t(key)}</span>
              {NAV_BADGES[key] > 0 && (
                <span className={`h-5 min-w-5 px-1 rounded-full grid place-items-center text-[10px] font-extrabold text-white ${
                  key === 'support' ? 'bg-red-500' : 'bg-brand-500'
                }`}>
                  {NAV_BADGES[key]}
                </span>
              )}
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-gray-100 dark:border-gray-800 text-center text-[11px] text-ink-muted">
          Dyar v10 · {t('adminPanel')}
        </div>
      </aside>

      <div className="flex-1 flex flex-col min-w-0">
        {/* الهيدر — ترحيب + مبدّل اللغات الثلاثي (يقلب RTL/LTR ويترجم فورًا) */}
        <header className="sticky top-0 z-40 bg-white/90 dark:bg-surface-card/90 backdrop-blur border-b border-gray-100 dark:border-gray-800 px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
          <div className="min-w-0">
            <div className="font-extrabold leading-tight truncate">
              {t('hello')} {user?.displayName ?? user?.email?.split('@')[0] ?? 'Admin'} 👋
            </div>
            <div className="text-xs text-ink-muted truncate" dir="ltr">{user?.email}</div>
          </div>

          <div className="flex items-center gap-3 shrink-0">
            <div className="flex items-center gap-2">
              <Globe size={18} className="text-ink-muted" />
              <div className="flex rounded-full bg-gray-100 dark:bg-gray-800 p-0.5">
                {LANGS.map((l) => (
                  <button
                    key={l.code}
                    onClick={() => setLang(l.code)}
                    className={`rounded-full px-3 py-1.5 text-xs font-bold transition-colors ${
                      lang === l.code ? 'bg-white dark:bg-surface-card shadow text-brand-600' : 'text-ink-muted'
                    }`}
                  >
                    {l.label}
                  </button>
                ))}
              </div>
            </div>
            <button onClick={toggleDark} className="btn-ghost !px-3" title="Dark mode">
              {dark ? <Sun size={20} /> : <Moon size={20} />}
            </button>
            <button onClick={logout} className="btn-ghost !px-3" title={t('logout')}>
              <LogOut size={20} />
            </button>
          </div>
        </header>

        <main className="flex-1 p-6 lg:p-8 overflow-x-hidden">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
