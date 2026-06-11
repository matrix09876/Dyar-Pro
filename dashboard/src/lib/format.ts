import type { Timestamp } from 'firebase/firestore';

// المبالغ مخزّنة بالأغورة (1/100). العرض بالشيكل.
export function money(agorot?: number): string {
  const v = (agorot ?? 0) / 100;
  return new Intl.NumberFormat('ar', { style: 'currency', currency: 'ILS' }).format(v);
}

export function dateTime(ts?: Timestamp): string {
  if (!ts) return '—';
  return new Intl.DateTimeFormat('ar', {
    dateStyle: 'medium', timeStyle: 'short',
  }).format(ts.toDate());
}

export function num(n?: number): string {
  return new Intl.NumberFormat('ar').format(n ?? 0);
}
