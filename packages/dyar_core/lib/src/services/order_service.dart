import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/order.dart';

/// الطلبات: القراءة لحظية من Firestore، والكتابة الحسّاسة عبر Cloud Functions
/// (التسعير من الخادم — لا يُوثق بسعر العميل).
class OrderService {
  OrderService({FirebaseFirestore? db, FirebaseFunctions? fns})
      : _db = db ?? FirebaseFirestore.instance,
        _fns = fns ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fns;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('orders');

  /// إنشاء طلب عبر الخادم — يعيد orderId + code + total.
  Future<Map<String, dynamic>> createOrder({
    required String storeId,
    required List<Map<String, dynamic>> items,
    required String type,
    Map<String, dynamic>? address,
    String paymentMethod = 'cash',
    String? couponCode,
    int tip = 0,
    int? scheduledFor, // epoch ms — جدولة التوصيل
  }) async {
    final res = await _fns.httpsCallable('createOrder').call({
      'storeId': storeId,
      'items': items,
      'type': type,
      'address': address,
      'paymentMethod': paymentMethod,
      'couponCode': couponCode,
      'tip': tip,
      'scheduledFor': scheduledFor,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> updateStatus(String orderId, OrderStatus status) =>
      _fns.httpsCallable('updateOrderStatus').call({
        'orderId': orderId,
        'status': status.key,
      });

  /// دفع EasycardNG (VISA/Bit): يعيد رابط صفحة الدفع لفتحه بالمتصفح،
  /// والتأكيد يصل عبر الـ webhook فيتحدث payment.status لحظيًا.
  Future<String?> payWithEasycard(String orderId, String method) async {
    final res = await _fns.httpsCallable('createEasycardPayment').call({
      'orderId': orderId,
      'method': method, // 'card' | 'bit'
    });
    return res.data['paymentUrl'] as String?;
  }

  /// الدفع من ميزانية وجبات الشركة (ديار Meals) — يعيد المتبقي بالأغورة.
  Future<int> payWithMealBudget(String orderId) async {
    final res = await _fns
        .httpsCallable('payWithMealBudget')
        .call({'orderId': orderId});
    return (res.data['remaining'] ?? 0) as int;
  }

  /// التاجر يصرف رمز POS لميزانية الوجبات بمبلغ (أغورة) — يعيد المتبقي.
  Future<int> redeemMealPos(String code, int amount, {String? storeId}) async {
    final res = await _fns.httpsCallable('redeemMealPosCode').call({
      'code': code, 'amount': amount, if (storeId != null) 'storeId': storeId,
    });
    return (res.data['remaining'] ?? 0) as int;
  }

  Future<String> createPaymentIntent(String orderId) async {
    final res =
        await _fns.httpsCallable('createPaymentIntent').call({'orderId': orderId});
    return res.data['clientSecret'] as String;
  }

  Future<void> rate(String orderId, int stars, [String? comment]) =>
      _fns.httpsCallable('rateOrder').call({
        'orderId': orderId, 'stars': stars, 'comment': comment,
      });

  /// طلبات الزبون
  Stream<List<DyarOrder>> watchMine(String uid) => _col
      .where('customerUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(DyarOrder.fromDoc).toList());

  /// طلبات متجر (للتاجر) — الحية فقط أو الكل
  Stream<List<DyarOrder>> watchStore(String storeId, {bool liveOnly = true}) {
    Query<Map<String, dynamic>> q =
        _col.where('storeId', isEqualTo: storeId);
    if (liveOnly) {
      q = q.where('status', whereIn: [
        'pending', 'accepted', 'preparing', 'ready', 'assigned', 'picked_up',
      ]);
    }
    return q
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(DyarOrder.fromDoc).toList());
  }

  /// مهمة السائق الحالية
  Stream<DyarOrder?> watchOrder(String orderId) =>
      _col.doc(orderId).snapshots().map(
          (d) => d.exists ? DyarOrder.fromDoc(d) : null);

  /// الطلبات الجاهزة غير المعيّنة (متاحة للسائقين)
  Stream<List<DyarOrder>> watchAvailableForDrivers() => _col
      .where('status', isEqualTo: 'ready')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) =>
          s.docs.map(DyarOrder.fromDoc).where((o) => o.driverUid == null).toList());
}
