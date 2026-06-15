// اختبار عمولة الجملة B2B — node خالص فوق lib المبنية (بلا firebase):
//   cd backend/functions && npm run build && node ../tests/b2b_commission.test.mjs
import assert from 'node:assert/strict';
import { b2bCommission, DEFAULT_B2B_COMMISSION_PCT } from '../functions/lib/b2b/commission.js';

let passed = 0;
const t = (name, fn) => {
  try { fn(); passed++; console.log('  ✓', name); }
  catch (e) { console.error('  ✗', name, '\n   ', e.message); process.exitCode = 1; }
};

console.log('🧮 B2B commission tests');

t('الافتراضي 3% (الهاندوف)', () => {
  assert.equal(DEFAULT_B2B_COMMISSION_PCT, 3);
  // 25000 أغورة × 3% = 750
  assert.equal(b2bCommission(25000), 750);
});

t('نسبة المتجر تتغلّب على الافتراضي', () => {
  // 25000 × 8% = 2000
  assert.equal(b2bCommission(25000, 8), 2000);
});

t('تقريب صحيح لأقرب أغورة', () => {
  // 333 × 3% = 9.99 → 10
  assert.equal(b2bCommission(333, 3), 10);
  // 100 × 2.5% = 2.5 → 3 (round-half-up)
  assert.equal(b2bCommission(100, 2.5), 3);
});

t('إجمالي صفر/سالب → صفر', () => {
  assert.equal(b2bCommission(0, 5), 0);
  assert.equal(b2bCommission(-1000, 5), 0);
});

t('نسبة غير صالحة → الافتراضي', () => {
  // NaN → 3%: 10000 × 3% = 300
  assert.equal(b2bCommission(10000, NaN), 300);
});

console.log(`\n${passed} passed${process.exitCode ? ' — مع إخفاقات!' : ''}`);
