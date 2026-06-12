// أنواع لوحة التحكم — مرآة لـ docs/DATA-MODEL.md. المبالغ بالأغورة (عدد صحيح).
import type { Timestamp } from 'firebase/firestore';

export type Role = 'customer' | 'driver' | 'partner' | 'staff' | 'admin';

export type OrderStatus =
  | 'pending' | 'accepted' | 'preparing' | 'ready' | 'assigned'
  | 'picked_up' | 'on_the_way' | 'delivered' | 'cancelled' | 'rejected';

export interface AppUser {
  id: string;
  role: Role;
  name?: string;
  phone?: string;
  email?: string;
  photoUrl?: string;
  walletBalance?: number;
  status?: 'active' | 'blocked';
  /** حساب تاجر B2B — يرى فئة تجار الجملة في تطبيق الزبون */
  merchant?: boolean;
  /** نقاط الولاء — تُمنح من الخادم عند delivered (config/loyalty) */
  points?: number;
  createdAt?: Timestamp;
}

export interface Store {
  id: string;
  ownerUid: string;
  name: string;
  type: string;
  logoUrl?: string;
  cityId?: string;
  rating?: number;
  ratingCount?: number;
  deliveryFee?: number;
  minOrder?: number;
  commissionPct?: number;
  isOpen?: boolean;
  status: 'pending' | 'approved' | 'suspended';
  createdAt?: Timestamp;
}

export interface Driver {
  id: string;
  vehicle?: { type: string; plate?: string; model?: string };
  isOnline?: boolean;
  status: 'pending' | 'approved' | 'suspended';
  activeOrderId?: string;
  rating?: number;
  earnings?: { today: number; week: number; total: number };
  /** إحصاءات تشغيلية — deliveredCount يحرّك جوائز المندوبين */
  stats?: { avgDeliveryMins?: number; deliveries?: number; deliveredCount?: number };
}

/** جائزة مندوبين — driverPrizes (هدف توصيلات → مكافأة بالأغورة). */
export interface DriverPrize {
  id: string;
  title: string;
  targetDeliveries: number;
  bonus: number; // أغورة
  active: boolean;
  createdAt?: Timestamp;
}

export interface OrderItem {
  itemId: string; name: string; qty: number; unitPrice: number; lineTotal: number;
}

export interface Order {
  id: string;
  code: string;
  customerUid: string;
  storeId: string;
  storeName?: string;
  driverUid?: string;
  items: OrderItem[];
  status: OrderStatus;
  type: string;
  pricing: { subtotal: number; deliveryFee: number; serviceFee: number; discount: number; tip: number; total: number };
  payment: { method: string; status: string };
  timeline?: { status: OrderStatus; at: Timestamp; by: string }[];
  etaMins?: number;
  address?: { line?: string; notes?: string };
  createdAt?: Timestamp;
}

/** منتج سوق C2C (بيع وشراء) — السعر بالأغورة. */
export interface MarketProduct {
  id: string;
  sellerUid: string;
  title: string;
  description?: string;
  price: number;
  imageUrl?: string;
  category: 'electronics' | 'fashion' | 'home' | 'cars' | 'other';
  city?: string;
  status: 'pending' | 'approved' | 'rejected' | 'sold';
  createdAt?: Timestamp;
}

export const STATUS_LABELS: Record<OrderStatus, string> = {
  pending: 'بانتظار', accepted: 'مقبول', preparing: 'قيد التحضير', ready: 'جاهز',
  assigned: 'مُعيَّن', picked_up: 'مُستلَم', on_the_way: 'في الطريق',
  delivered: 'تم التوصيل', cancelled: 'ملغي', rejected: 'مرفوض',
};

export const STATUS_COLORS: Record<OrderStatus, string> = {
  pending: 'bg-amber-100 text-amber-700', accepted: 'bg-blue-100 text-blue-700',
  preparing: 'bg-indigo-100 text-indigo-700', ready: 'bg-cyan-100 text-cyan-700',
  assigned: 'bg-violet-100 text-violet-700', picked_up: 'bg-purple-100 text-purple-700',
  on_the_way: 'bg-sky-100 text-sky-700', delivered: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-200 text-gray-600', rejected: 'bg-red-100 text-red-700',
};
