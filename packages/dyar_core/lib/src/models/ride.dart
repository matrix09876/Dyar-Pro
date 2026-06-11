import 'package:cloud_firestore/cloud_firestore.dart';

/// مشوار تاكسي (قياسي/راحة/عائلي) — مع دعم تسعير الذروة وSOS.
class Ride {
  final String id;
  final String customerUid;
  final String? driverUid;
  final String tier; // standard|comfort|xl
  final String status; // searching|accepted|arriving|in_progress|completed|cancelled
  final Map<String, dynamic> pickup, dropoff;
  final int total; // أغورة
  final double surge;
  final double distanceKm;
  final DateTime? createdAt;

  const Ride({
    required this.id, required this.customerUid, this.driverUid,
    this.tier = 'standard', this.status = 'searching',
    this.pickup = const {}, this.dropoff = const {},
    this.total = 0, this.surge = 1, this.distanceKm = 0, this.createdAt,
  });

  factory Ride.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Ride(
      id: doc.id,
      customerUid: d['customerUid'] ?? '',
      driverUid: d['driverUid'],
      tier: d['tier'] ?? 'standard',
      status: d['status'] ?? 'searching',
      pickup: Map<String, dynamic>.from(d['pickup'] ?? const {}),
      dropoff: Map<String, dynamic>.from(d['dropoff'] ?? const {}),
      total: (d['pricing']?['total'] ?? 0) as int,
      surge: ((d['pricing']?['surge'] ?? 1) as num).toDouble(),
      distanceKm: ((d['distanceKm'] ?? 0) as num).toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
