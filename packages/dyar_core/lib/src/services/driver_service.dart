import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_profile.dart';

class DriverService {
  DriverService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('drivers').doc(uid);

  Stream<DriverProfile?> watchProfile(String uid) => _doc(uid)
      .snapshots()
      .map((d) => d.exists ? DriverProfile.fromDoc(d) : null);

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
