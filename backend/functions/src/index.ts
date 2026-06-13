// Dyar Cloud Functions — نقطة الدخول.
// المنطق الحسّاس كله هنا (لا يُوثَق بالعميل): الأدوار، دورة حياة الطلب،
// تعيين السائق، الدفع، الإشعارات.
import { initializeApp } from 'firebase-admin/app';
initializeApp();

export { setUserRole, onUserCreate, claimFirstAdmin } from './auth/roles';
export { createOrder, updateOrderStatus, assignDriver, rateOrder } from './orders/lifecycle';
export { autoAssignNearestDriver } from './drivers/assignment';
export { createPaymentIntent, stripeWebhook } from './payments/stripe';
export { createEasycardPayment, easycardWebhook } from './payments/easycard';
export { speak, liveSupportUrl } from './ai/voice';
export { hookOrderStatus, hookCreateTicket, hookRefundRequest } from './ai/supportHooks';
export { redeemGiftCard } from './wallet/giftcards';
export { payWithMealBudget, grantMealBudgets } from './meals/budget';
export { requestPayout } from './wallet/payouts';
export { claimParcel, startParcelTransit } from './parcels/shipping';
export { updateRideStatus } from './rides/taxi';
export { onOrderStatusNotify } from './notifications/fcm';
export { sendBroadcast } from './notifications/broadcast';
export { requestRide, acceptRide } from './rides/taxi';
export { createParcel, confirmParcelDelivery } from './parcels/shipping';
export { createBooking, updateBookingStatus } from './bookings/booking';
export { aiEta, aiSupportReply } from './ai/assistant';
export { markProductSold } from './marketplace/market';
export { resetDriverEarnings, bookingReminders, monthlySettlement } from './ops/scheduled';
