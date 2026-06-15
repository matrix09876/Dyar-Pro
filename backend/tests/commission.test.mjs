// اختبارات محرك العمولات الذكية — node خالص فوق lib المبنية (بلا firebase):
//   cd backend/functions && npm run test:commission
// (يبني tsc ثم يستورد resolveCommissionPct من lib/ops/commission.js)
import assert from 'node:assert/strict';
import {
  resolveCommissionPct,
  inPeakWindow,
} from '../functions/lib/ops/commission.js';

let passed = 0;
const t = (name, fn) => {
  try { fn(); passed++; console.log('  ✓', name); }
  catch (e) { console.error('  ✗', name, '\n   ', e.message); process.exitCode = 1; }
};

// تواريخ ثابتة بتوقيت القدس (يناير = UTC+2، بلا توقيت صيفي):
const at1900 = new Date('2026-01-15T17:00:00Z'); // 19:00 القدس
const at1200 = new Date('2026-01-15T10:00:00Z'); // 12:00 القدس
const at0100 = new Date('2026-01-15T23:00:00Z'); // 01:00 القدس (اليوم التالي)

const cityRule = { scope: 'city', match: 'haifa', pct: 11 };
const peakRule = {
  scope: 'city', match: 'haifa', pct: 11,
  peakPct: 18, peakHours: { from: '18:00', to: '22:00' },
};

console.log('🧮 commission engine tests');

t('override المتجر يتغلب على كل شيء (8%)', () => {
  const pct = resolveCommissionPct({
    store: { id: 's1', type: 'restaurant', cityId: 'haifa', commissionPct: 8 },
    city: { id: 'haifa', country: 'IL' },
    at: at1200,
    rules: [peakRule],
    monthlyOrders: 1000,
  });
  assert.equal(pct, 8);
});

t('مزوّد خدمة (حلاق/طبيب) → 6% قبل أي قاعدة', () => {
  const pct = resolveCommissionPct({
    store: { id: 's2', type: 'service', cityId: 'haifa' },
    at: at1200,
    rules: [cityRule],
    monthlyOrders: 10,
  });
  assert.equal(pct, 6);
});

t('قاعدة مدينة مطابقة → نسبتها (11%) بدل الشرائح', () => {
  const pct = resolveCommissionPct({
    store: { id: 's3', type: 'restaurant', cityId: 'haifa' },
    at: at1200,
    rules: [cityRule],
    monthlyOrders: 100,
  });
  assert.equal(pct, 11);
});

t('ذروة داخل النافذة 18:00-22:00 (توقيت القدس) → peakPct 18%', () => {
  const pct = resolveCommissionPct({
    store: { id: 's3', type: 'restaurant', cityId: 'haifa' },
    at: at1900,
    rules: [peakRule],
  });
  assert.equal(pct, 18);
});

t('خارج نافذة الذروة → النسبة الأساسية للقاعدة (11%)', () => {
  const pct = resolveCommissionPct({
    store: { id: 's3', type: 'restaurant', cityId: 'haifa' },
    at: at1200,
    rules: [peakRule],
  });
  assert.equal(pct, 11);
});

t('نافذة ذروة تعبر منتصف الليل (22:00→02:00) تشمل 01:00', () => {
  assert.equal(inPeakWindow(at0100, { from: '22:00', to: '02:00' }), true);
  assert.equal(inPeakWindow(at1200, { from: '22:00', to: '02:00' }), false);
});

t('قاعدة بلد (country) تُطابق عبر مدينة المتجر', () => {
  const pct = resolveCommissionPct({
    store: { id: 's4', type: 'grocery', cityId: 'haifa' },
    city: { id: 'haifa', country: 'IL' },
    at: at1200,
    rules: [{ scope: 'country', match: 'il', pct: 9 }],
    monthlyOrders: 50,
  });
  assert.equal(pct, 9);
});

t('الأولوية بالترتيب: قاعدة متجر قبل قاعدة المدينة', () => {
  const pct = resolveCommissionPct({
    store: { id: 's5', type: 'restaurant', cityId: 'haifa' },
    at: at1200,
    rules: [{ scope: 'store', match: 's5', pct: 7 }, cityRule],
  });
  assert.equal(pct, 7);
});

t('الشرائح: ≤299 → 15%، ≤500 → 13.5%، فوقها → 12%', () => {
  const base = { store: { id: 's6', type: 'restaurant' }, at: at1200, rules: [] };
  assert.equal(resolveCommissionPct({ ...base, monthlyOrders: 299 }), 15);
  assert.equal(resolveCommissionPct({ ...base, monthlyOrders: 300 }), 13.5);
  assert.equal(resolveCommissionPct({ ...base, monthlyOrders: 500 }), 13.5);
  assert.equal(resolveCommissionPct({ ...base, monthlyOrders: 501 }), 12);
});

t('الافتراضي بلا حجم شهري: defaultPct ثم أول شريحة', () => {
  const store = { id: 's7', type: 'restaurant' };
  assert.equal(
    resolveCommissionPct({ store, at: at1200, defaultPct: 10 }), 10);
  assert.equal(resolveCommissionPct({ store, at: at1200 }), 15);
});

console.log(`\n${passed} passed${process.exitCode ? ' — with failures' : ''}`);
