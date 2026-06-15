import { useEffect, useState } from 'react';
import {
  UtensilsCrossed, ShoppingBasket, Pill, Flower2, Wrench, CarTaxiFront,
  Package, CalendarCheck, Wallet, Gift, Moon, Sun, Apple, Play,
  Store, Bike,
} from 'lucide-react';

type Lang = 'ar' | 'he' | 'en';

const T: Record<string, Record<Lang, string>> = {
  tagline: {
    ar: 'كل ما تحتاجه في مكان واحد',
    he: 'הכל במקום אחד',
    en: 'All you need in one place',
  },
  sub: {
    ar: 'طعام، بقالة، صيدليات، ورود، خدمات، تاكسي، شحن طرود وحجوزات — بتطبيق واحد يخدم الجليل وكل البلاد.',
    he: 'אוכל, מכולת, בתי מרקחת, פרחים, שירותים, מוניות, משלוחי חבילות והזמנות — באפליקציה אחת.',
    en: 'Food, groceries, pharmacies, flowers, services, taxi, parcels & bookings — one app for everything.',
  },
  getApp: { ar: 'حمّل التطبيق', he: 'הורד את האפליקציה', en: 'Get the app' },
  becomePartner: { ar: 'سجّل متجرك', he: 'הצטרף כעסק', en: 'Become a partner' },
  becomeDriver: { ar: 'انضم كسائق', he: 'הצטרף כנהג', en: 'Become a driver' },
  servicesTitle: { ar: 'خدماتنا', he: 'השירותים שלנו', en: 'Our services' },
  food: { ar: 'مطاعم', he: 'מסעדות', en: 'Restaurants' },
  grocery: { ar: 'بقالة', he: 'מכולת', en: 'Groceries' },
  pharmacy: { ar: 'صيدليات', he: 'בתי מרקחת', en: 'Pharmacies' },
  flowers: { ar: 'ورود', he: 'פרחים', en: 'Flowers' },
  services: { ar: 'خدمات', he: 'שירותים', en: 'Services' },
  taxi: { ar: 'تاكسي', he: 'מונית', en: 'Taxi' },
  parcel: { ar: 'شحن طرود', he: 'משלוח חבילות', en: 'Parcels' },
  booking: { ar: 'حجز طاولات', he: 'הזמנת שולחן', en: 'Table booking' },
  wallet: { ar: 'محفظة ديار', he: 'ארנק דיאר', en: 'Dyar Wallet' },
  invite: { ar: 'ادعُ واربح', he: 'הזמן והרווח', en: 'Invite & earn' },
  rights: { ar: 'جميع الحقوق محفوظة', he: 'כל הזכויות שמורות', en: 'All rights reserved' },
};

export default function App() {
  const [lang, setLang] = useState<Lang>('ar');
  const [dark, setDark] = useState(false);
  const t = (k: string) => T[k]?.[lang] ?? k;

  useEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'en' ? 'ltr' : 'rtl';
  }, [lang]);
  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark);
  }, [dark]);

  const services = [
    { icon: UtensilsCrossed, key: 'food' },
    { icon: ShoppingBasket, key: 'grocery' },
    { icon: Pill, key: 'pharmacy' },
    { icon: Flower2, key: 'flowers' },
    { icon: Wrench, key: 'services' },
    { icon: CarTaxiFront, key: 'taxi' },
    { icon: Package, key: 'parcel' },
    { icon: CalendarCheck, key: 'booking' },
    { icon: Wallet, key: 'wallet' },
    { icon: Gift, key: 'invite' },
  ];

  return (
    <div className="min-h-screen">
      {/* الشريط العلوي */}
      <header className="max-w-6xl mx-auto px-6 py-5 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="h-11 w-11 rounded-2xl bg-brand-500 text-white grid place-items-center font-extrabold text-xl">د</div>
          <span className="font-extrabold text-xl">Dyar</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1 rounded-full bg-gray-100 dark:bg-gray-800 p-1">
            {(['ar', 'he', 'en'] as Lang[]).map((l) => (
              <button
                key={l}
                onClick={() => setLang(l)}
                className={`px-3 py-1 rounded-full text-sm font-bold ${
                  lang === l ? 'bg-white dark:bg-gray-700 text-brand-600 shadow' : 'text-gray-500'
                }`}
              >
                {l === 'ar' ? 'ع' : l === 'he' ? 'עב' : 'EN'}
              </button>
            ))}
          </div>
          <button
            onClick={() => setDark(!dark)}
            className="h-10 w-10 grid place-items-center rounded-full bg-gray-100 dark:bg-gray-800"
            aria-label="dark mode"
          >
            {dark ? <Sun size={18} /> : <Moon size={18} />}
          </button>
        </div>
      </header>

      {/* البطل */}
      <section className="max-w-6xl mx-auto px-6 pt-12 pb-20 text-center">
        <h1 className="text-4xl md:text-6xl font-extrabold leading-tight bg-gradient-to-l from-brand-500 to-brand-700 bg-clip-text text-transparent">
          {t('tagline')}
        </h1>
        <p className="mt-5 text-lg text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">{t('sub')}</p>

        <div className="mt-9 flex flex-wrap justify-center gap-3">
          <a
            href="https://apps.apple.com/app/dyar/id6754179699"
            className="inline-flex items-center gap-2 rounded-2xl bg-gray-900 dark:bg-white dark:text-gray-900 text-white px-6 h-14 font-bold"
          >
            <Apple size={22} /> App Store
          </a>
          <a
            href="https://play.google.com/store/apps/details?id=com.dyar.user"
            className="inline-flex items-center gap-2 rounded-2xl bg-gray-900 dark:bg-white dark:text-gray-900 text-white px-6 h-14 font-bold"
          >
            <Play size={22} /> Google Play
          </a>
        </div>

        <div className="mt-5 flex flex-wrap justify-center gap-3">
          <a href="#partner" className="inline-flex items-center gap-2 rounded-2xl border-2 border-brand-500 text-brand-600 px-6 h-12 font-bold">
            <Store size={20} /> {t('becomePartner')}
          </a>
          <a href="#driver" className="inline-flex items-center gap-2 rounded-2xl border-2 border-brand-500 text-brand-600 px-6 h-12 font-bold">
            <Bike size={20} /> {t('becomeDriver')}
          </a>
        </div>
      </section>

      {/* الخدمات */}
      <section className="bg-brand-50 dark:bg-brand-950/30 py-16">
        <div className="max-w-6xl mx-auto px-6">
          <h2 className="text-2xl md:text-3xl font-extrabold text-center mb-10">{t('servicesTitle')}</h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
            {services.map(({ icon: Icon, key }) => (
              <div key={key} className="rounded-2xl bg-white dark:bg-[#1e1e25] p-6 text-center shadow-sm">
                <div className="mx-auto h-12 w-12 rounded-2xl bg-brand-100 dark:bg-brand-950 grid place-items-center text-brand-600 mb-3">
                  <Icon size={24} strokeWidth={1.8} />
                </div>
                <div className="font-bold text-sm">{t(key)}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <footer className="py-10 text-center text-sm text-gray-500">
        © {new Date().getFullYear()} Dyar — {t('rights')}
      </footer>
    </div>
  );
}
