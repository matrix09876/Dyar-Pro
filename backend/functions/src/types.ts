// Dyar — الأنواع المشتركة (مرآة لـ docs/DATA-MODEL.md).
// كل المبالغ بأصغر وحدة عملة (أغورة) كأعداد صحيحة.

export type Role = 'customer' | 'driver' | 'partner' | 'staff' | 'admin';

// صلاحيات عامل المكتب الدقيقة — يضبطها المسؤول فقط
export type StaffPermission =
  | 'orders.view' | 'orders.manage' | 'orders.assignDriver'
  | 'stores.view' | 'stores.approve'
  | 'drivers.view' | 'drivers.approve'
  | 'users.view' | 'users.block'
  | 'marketing.manage' | 'finance.view' | 'support.manage';

export type OrderStatus =
  | 'pending' | 'accepted' | 'preparing' | 'ready' | 'assigned'
  | 'picked_up' | 'on_the_way' | 'delivered' | 'cancelled' | 'rejected';

export type OrderType = 'delivery' | 'pickup' | 'dinein' | 'service';

export type PaymentMethod = 'card' | 'cash' | 'wallet' | 'paypal';
export type PaymentStatus = 'pending' | 'paid' | 'refunded' | 'failed';

export interface GeoPoint { lat: number; lng: number; }

export interface OrderItem {
  itemId: string;
  name: string;
  qty: number;
  unitPrice: number;
  options?: { name: string; price: number }[];
  lineTotal: number;
}

export interface OrderPricing {
  subtotal: number;
  deliveryFee: number;
  serviceFee: number;
  discount: number;
  tip: number;
  total: number;
}

export interface Order {
  code: string;
  customerUid: string;
  storeId: string;
  driverUid?: string;
  items: OrderItem[];
  status: OrderStatus;
  type: OrderType;
  address: { line: string; lat: number; lng: number; notes?: string };
  pricing: OrderPricing;
  payment: {
    method: PaymentMethod;
    status: PaymentStatus;
    intentId?: string;
    paidAt?: FirebaseFirestore.Timestamp;
  };
  timeline: { status: OrderStatus; at: FirebaseFirestore.Timestamp; by: string }[];
  etaMins?: number; // ETA متعلَّم (دقائق) — يُحدَّد عند الإنشاء
  eta?: FirebaseFirestore.Timestamp;
  rating?: { stars: number; comment?: string };
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

// ---- الحجوزات (طاولة مطعم / موعد خدمة) — مرآة bookings في DATA-MODEL ----
export type BookingStatus =
  | 'pending' | 'confirmed' | 'seated' | 'completed' | 'cancelled' | 'no_show';

export type BookingType = 'table' | 'service';

export interface Booking {
  customerUid: string;
  storeId: string;
  type: BookingType;
  partySize?: number;
  tableId?: string;
  slot: FirebaseFirestore.Timestamp;
  notes?: string;
  reminder: boolean;
  fee: number;
  status: BookingStatus;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

// تحوّلات حالة الحجز المسموح بها (state machine)
export const BOOKING_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['seated', 'completed', 'cancelled', 'no_show'],
  seated: ['completed', 'cancelled'],
  completed: [],
  cancelled: [],
  no_show: [],
};

// تحوّلات الحالة المسموح بها (state machine)
export const ORDER_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  pending: ['accepted', 'rejected', 'cancelled'],
  accepted: ['preparing', 'cancelled'],
  preparing: ['ready', 'cancelled'],
  ready: ['assigned', 'cancelled'],
  assigned: ['picked_up', 'cancelled'],
  picked_up: ['on_the_way', 'cancelled'],
  on_the_way: ['delivered', 'cancelled'],
  delivered: [],
  cancelled: [],
  rejected: [],
};
