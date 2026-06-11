// Dyar Cloud Functions — نقطة الدخول.
// المنطق الحسّاس كله هنا (لا يُوثَق بالعميل): الأدوار، دورة حياة الطلب،
// تعيين السائق، الدفع، الإشعارات.
import { initializeApp } from 'firebase-admin/app';
initializeApp();

export { setUserRole, onUserCreate } from './auth/roles';
export { createOrder, updateOrderStatus, assignDriver, rateOrder } from './orders/lifecycle';
export { autoAssignNearestDriver } from './drivers/assignment';
export { createPaymentIntent, stripeWebhook } from './payments/stripe';
export { createEasycardPayment, easycardWebhook } from './payments/easycard';
export { onOrderStatusNotify } from './notifications/fcm';
export { requestRide, acceptRide } from './rides/taxi';
export { createParcel, confirmParcelDelivery } from './parcels/shipping';
export { aiEta, aiSupportReply } from './ai/assistant';
export { markProductSold } from './marketplace/market';
export { resetDriverEarnings, bookingReminders, monthlySettlement } from './ops/scheduled';
