import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/driver_profile.dart';

/// موقع حي للسائق — يُبث من تطبيق السائق ويُقرأ في خريطة تتبّع الزبون.
class DriverLocation {
  final double lat;
  final double lng;
  final double heading;
  const DriverLocation({required this.lat, required this.lng, this.heading = 0});
}

class DriverService {
  DriverService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('drivers').doc(uid);

  Stream<DriverProfile?> watchProfile(String uid) => _doc(uid)
      .snapshots()
      .map((d) => d.exists ? DriverProfile.fromDoc(d) : null);

  /// بثّ موقع السائق الحي (للخريطة في تطبيق الزبون أثناء التتبّع).
  Stream<DriverLocation?> watchLocation(String uid) =>
      _doc(uid).snapshots().map((d) {
        final l = d.data()?['currentLocation'] as Map<String, dynamic>?;
        if (l == null || l['lat'] == null || l['lng'] == null) return null;
        return DriverLocation(
          lat: (l['lat'] as num).toDouble(),
          lng: (l['lng'] as num).toDouble(),
          heading: ((l['heading'] ?? 0) as num).toDouble(),
        );
      });

  /// تسجيل سائق جديد (يبدأ pending حتى توافق الإدارة على الوثائق)
  Future<void> register(String uid, {required String vehicleType, String? plate}) =>
      _doc(uid).set({
        'vehicle': {'type': vehicleType, if (plate != null) 'plate': plate},
        'isOnline': false,
        'status': 'pending',
        'earnings': {'today': 0, 'week': 0, 'total': 0},
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// تبديل متصل/غير متصل
  Future<void> setOnline(String uid, bool online) =>
      _doc(uid).update({'isOnline': online});

  /// تحديث الموقع الحي (كل بضع ثوانٍ أثناء العمل)
  Future<void> updateLocation(String uid, double lat, double lng,
          {double heading = 0}) =>
      _doc(uid).update({
        'currentLocation': {
          'lat': lat, 'lng': lng, 'heading': heading,
          'at': FieldValue.serverTimestamp(),
        },
      });

  /// قبول مهمة متاحة (إن لم تكن معيّنة تلقائيًا)
  Future<void> claimOrder(String uid, String orderId) async {
    await _db.runTransaction((tx) async {
      final orderRef = _db.collection('orders').doc(orderId);
      final snap = await tx.get(orderRef);
      if (!snap.exists || snap.data()!['driverUid'] != null) {
        throw Exception('order already taken');
      }
      tx.update(orderRef, {
        'driverUid': uid,
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(_doc(uid), {'activeOrderId': orderId});
    });
  }
}

extension DriverKyc on DriverService {
  /// تحديث بيانات وثائق السائق (KYC) — تتحقق منها الإدارة من اللوحة.
  Future<void> updateDocuments(String uid, Map<String, dynamic> docs) =>
      FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .set({'documents': docs}, SetOptions(merge: true));
}

extension DriverHistoryOps on DriverService {
  /// طلبات سلّمها هذا السائق (السجل)
  Stream<List<Map<String, dynamic>>> watchDeliveredOrders(String uid) =>
      FirebaseFirestore.instance
          .collection('orders')
          .where('driverUid', isEqualTo: uid)
          .where('status', isEqualTo: 'delivered')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  /// حركات أرباح السائق (payout)
  Stream<List<Map<String, dynamic>>> watchEarningTx(String uid) =>
      FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  /// طلب سحب فوري (حتى 80% من الإجمالي)
  Future<int> requestPayout(int amount) async {
    final res = await FirebaseFunctions.instance
        .httpsCallable('requestPayout')
        .call({'amount': amount});
    return (res.data['available'] ?? 0) as int;
  }
}
