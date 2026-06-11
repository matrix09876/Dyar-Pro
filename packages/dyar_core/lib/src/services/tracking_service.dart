import 'package:cloud_firestore/cloud_firestore.dart';

/// البث الحي لموقع السائق إلى تطبيق المستخدم.
/// السائق يكتب موقعه في drivers/{uid}.currentLocation؛ المستخدم يقرأه
/// عبر driverUid المرتبط بطلبه — تتبّع حي على الخريطة (مثل المنافسين).
class TrackingService {
  TrackingService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  /// موقع السائق الحي (lat/lng/heading) — للعرض على خريطة المستخدم.
  Stream<Map<String, dynamic>?> watchDriverLocation(String driverUid) => _db
      .doc('drivers/$driverUid')
      .snapshots()
      .map((d) => d.data()?['currentLocation'] as Map<String, dynamic>?);

  /// تحديث موقع السائق (يستدعيه تطبيق السائق من بثّ الموقع).
  Future<void> pushLocation(
          String driverUid, double lat, double lng, double heading) =>
      _db.doc('drivers/$driverUid').update({
        'currentLocation': {
          'lat': lat,
          'lng': lng,
          'heading': heading,
          'at': FieldValue.serverTimestamp(),
        },
      });
}
