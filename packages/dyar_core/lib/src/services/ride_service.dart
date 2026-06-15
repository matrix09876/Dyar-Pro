import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/ride.dart';

/// التاكسي: طلب مشوار (تسعير من الخادم) + متابعة حالته لحظيًا.
class RideService {
  RideService({FirebaseFirestore? db, FirebaseFunctions? fns})
      : _db = db ?? FirebaseFirestore.instance,
        _fns = fns ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fns;

  Future<Map<String, dynamic>> request({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    String tier = 'standard',
    String paymentMethod = 'cash',
    String? pickupAddress,
    String? dropAddress,
  }) async {
    final res = await _fns.httpsCallable('requestRide').call({
      'pickup': {'lat': pickupLat, 'lng': pickupLng, 'address': pickupAddress},
      'dropoff': {'lat': dropLat, 'lng': dropLng, 'address': dropAddress},
      'tier': tier,
      'paymentMethod': paymentMethod,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> accept(String rideId) =>
      _fns.httpsCallable('acceptRide').call({'rideId': rideId});

  Stream<Ride?> watch(String rideId) => _db
      .doc('rides/$rideId')
      .snapshots()
      .map((d) => d.exists ? Ride.fromDoc(d) : null);

  Stream<List<Ride>> watchSearching() => _db
      .collection('rides')
      .where('status', isEqualTo: 'searching')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(Ride.fromDoc).toList());
}

extension RideDriverOps on RideService {
  /// المشاوير الباحثة عن سائق
  Stream<List<Ride>> watchSearching() => FirebaseFirestore.instance
      .collection('rides')
      .where('status', isEqualTo: 'searching')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(Ride.fromDoc).toList());

  Future<void> accept(String rideId) => FirebaseFunctions.instance
      .httpsCallable('acceptRide')
      .call({'rideId': rideId});

  /// accepted → arriving → in_progress → completed (الخادم يفرض التسلسل)
  Future<void> updateStatus(String rideId, String status) =>
      FirebaseFunctions.instance
          .httpsCallable('updateRideStatus')
          .call({'rideId': rideId, 'status': status});
}
