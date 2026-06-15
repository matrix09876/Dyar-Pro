// عمولة ديار للجملة B2B — دالة نقية (قابلة للاختبار بلا firebase) تُستخدم في
// quoteRfq. النسبة من المتجر (commissionPct) أو الافتراضي 3% (الهاندوف).
export const DEFAULT_B2B_COMMISSION_PCT = 3;

/** عمولة ديار بالأغورة من إجمالي الصفقة. النسبة الافتراضية 3% إن لم تُحدَّد. */
export function b2bCommission(
  total: number,
  commissionPct: number = DEFAULT_B2B_COMMISSION_PCT,
): number {
  const pct = Number.isFinite(commissionPct) ? commissionPct : DEFAULT_B2B_COMMISSION_PCT;
  return Math.round((Math.max(0, total) * pct) / 100);
}
