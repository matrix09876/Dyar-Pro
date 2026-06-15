// محرك العمولات الذكية — وحدة صافية (بلا أي اعتماد على firebase) حتى
// تُختبر بـ node مباشرة من lib/ المبنية (backend/tests/commission.test.mjs).
//
// ترتيب الحسم (انظر docs/DATA-MODEL.md — «قواعد العمولة الذكية»):
//   1. override المتجر (stores/{id}.commissionPct)
//   2. مزوّدو الخدمات (type === 'service') → serviceProvidersPct
//   3. أول قاعدة مطابقة من config/app.commissionRules (قائمة مرتبة
//      بالأولوية) — مع peakPct داخل نافذة الذروة بتوقيت Asia/Jerusalem
//   4. الشرائح commissionTiers حسب الحجم الشهري الممرر (الافتراضي الأخير)

export interface CommissionRule {
  scope: 'store' | 'city' | 'country' | 'storeType';
  match: string;                 // storeId | cityId | country | store.type
  pct: number;
  peakPct?: number;              // تتجاوز pct داخل النافذة
  peakHours?: { from: string; to: string };  // 'HH:mm' — Asia/Jerusalem
}

export interface CommissionTier {
  maxMonthlyOrders: number | null;
  pct: number;
}

export interface CommissionStore {
  id: string;
  type?: string;                 // 'restaurant'|'service'|...
  cityId?: string;
  commissionPct?: number;        // override يدوي من اللوحة
}

export interface CommissionCity {
  id?: string;
  country?: string;
}

export const COMMISSION_TZ = 'Asia/Jerusalem';
export const DEFAULT_SERVICE_PCT = 6;
export const DEFAULT_TIERS: CommissionTier[] = [
  { maxMonthlyOrders: 299, pct: 15 },
  { maxMonthlyOrders: 500, pct: 13.5 },
  { maxMonthlyOrders: null, pct: 12 },
];

/** دقائق اليوم (0-1439) للحظة معيّنة بتوقيت منطقة زمنية. */
function minutesOfDay(at: Date, timeZone: string): number {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone, hour: '2-digit', minute: '2-digit', hour12: false,
  }).formatToParts(at);
  const h = Number(parts.find((p) => p.type === 'hour')?.value ?? '0') % 24;
  const m = Number(parts.find((p) => p.type === 'minute')?.value ?? '0');
  return h * 60 + m;
}

function parseHHmm(s: string | undefined): number | null {
  const m = /^(\d{1,2}):(\d{2})$/.exec(s ?? '');
  if (!m) return null;
  const mins = Number(m[1]) * 60 + Number(m[2]);
  return mins >= 0 && mins < 24 * 60 ? mins : null;
}

/** هل اللحظة داخل نافذة الذروة؟ تدعم نافذة تعبر منتصف الليل (from > to). */
export function inPeakWindow(
  at: Date,
  peak: { from: string; to: string },
  timeZone: string = COMMISSION_TZ,
): boolean {
  const from = parseHHmm(peak.from);
  const to = parseHHmm(peak.to);
  if (from === null || to === null || from === to) return false;
  const now = minutesOfDay(at, timeZone);
  return from < to ? now >= from && now < to : now >= from || now < to;
}

function ruleMatches(
  rule: CommissionRule,
  store: CommissionStore,
  city?: CommissionCity | null,
): boolean {
  switch (rule.scope) {
    case 'store': return rule.match === store.id;
    case 'storeType': return !!store.type && rule.match === store.type;
    case 'city': return !!rule.match && rule.match === (store.cityId ?? city?.id);
    case 'country':
      return !!city?.country &&
        rule.match.toLowerCase() === city.country.toLowerCase();
    default: return false;
  }
}

export interface ResolveCommissionInput {
  store: CommissionStore;
  city?: CommissionCity | null;
  at?: Date;                     // لحظة الاحتساب (افتراضي: الآن)
  rules?: CommissionRule[];      // config/app.commissionRules (مرتبة)
  tiers?: CommissionTier[];      // config/app.commissionTiers
  servicePct?: number;           // config/app.serviceProvidersPct
  monthlyOrders?: number;        // حجم الشهر (للتسوية الشهرية)
  defaultPct?: number;           // config/app.defaultCommissionPct
}

/** يحسم نسبة العمولة (%) لمتجر في لحظة معيّنة وفق ترتيب الأولوية أعلاه. */
export function resolveCommissionPct(input: ResolveCommissionInput): number {
  const { store, city, at = new Date() } = input;

  // 1) override المتجر — الأعلى أولوية
  if (typeof store.commissionPct === 'number') return store.commissionPct;

  // 2) مزوّدو الخدمات (حلاق/طبيب/ميكانيكي...) — نسبة ثابتة
  if (store.type === 'service') return input.servicePct ?? DEFAULT_SERVICE_PCT;

  // 3) أول قاعدة مطابقة من القائمة المرتبة بالأولوية
  for (const rule of input.rules ?? []) {
    if (!ruleMatches(rule, store, city)) continue;
    if (typeof rule.peakPct === 'number' && rule.peakHours &&
        inPeakWindow(at, rule.peakHours)) {
      return rule.peakPct;
    }
    return rule.pct;
  }

  // 4) الشرائح حسب الحجم الشهري — وإلا الافتراضي (أعلى شريحة)
  const tiers = input.tiers?.length ? input.tiers : DEFAULT_TIERS;
  if (typeof input.monthlyOrders === 'number') {
    const tier = tiers.find((t) =>
      t.maxMonthlyOrders === null || input.monthlyOrders! <= t.maxMonthlyOrders);
    return (tier ?? tiers[tiers.length - 1]).pct;
  }
  return input.defaultPct ?? tiers[0].pct;
}
