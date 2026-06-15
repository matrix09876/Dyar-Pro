import 'package:cloud_firestore/cloud_firestore.dart';

class DriverProfile {
  final String uid;
  final String vehicleType; // car|motorcycle|bicycle
  final String? plate;
  final bool isOnline;
  final String status; // pending|approved|suspended
  final String? activeOrderId;
  final String? activeParcelId;
  final int earningsToday, earningsWeek, earningsTotal; // أغورة
  final double rating;

  const DriverProfile({
    required this.uid,
    this.vehicleType = 'car',
    this.plate,
    this.isOnline = false,
    this.status = 'pending',
    this.activeOrderId,
    this.activeParcelId,
    this.earningsToday = 0, this.earningsWeek = 0, this.earningsTotal = 0,
    this.rating = 0,
  });

  factory DriverProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final earnings = Map<String, dynamic>.from(d['earnings'] ?? const {});
    return DriverProfile(
      uid: doc.id,
      vehicleType: (d['vehicle']?['type'] ?? 'car') as String,
      plate: d['vehicle']?['plate'],
      isOnline: d['isOnline'] ?? false,
      status: d['status'] ?? 'pending',
      activeOrderId: d['activeOrderId'],
      activeParcelId: d['activeParcelId'],
      earningsToday: (earnings['today'] ?? 0) as int,
      earningsWeek: (earnings['week'] ?? 0) as int,
      earningsTotal: (earnings['total'] ?? 0) as int,
      rating: ((d['rating'] ?? 0) as num).toDouble(),
    );
  }
}
