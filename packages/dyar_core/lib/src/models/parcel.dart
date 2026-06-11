import 'package:cloud_firestore/cloud_firestore.dart';

/// طرد شحن — مع رمز تسليم OTP (ميزة حماية ديار).
class Parcel {
  final String id;
  final String senderUid;
  final String? driverUid;
  final Map<String, dynamic> sender, recipient;
  final double weightKg;
  final String status; // pending|pickup|in_transit|delivered|cancelled
  final int total; // أغورة
  final String? deliveryOtp;
  final DateTime? createdAt;

  const Parcel({
    required this.id, required this.senderUid, this.driverUid,
    this.sender = const {}, this.recipient = const {},
    this.weightKg = 0, this.status = 'pending', this.total = 0,
    this.deliveryOtp, this.createdAt,
  });

  factory Parcel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Parcel(
      id: doc.id,
      senderUid: d['senderUid'] ?? '',
      driverUid: d['driverUid'],
      sender: Map<String, dynamic>.from(d['sender'] ?? const {}),
      recipient: Map<String, dynamic>.from(d['recipient'] ?? const {}),
      weightKg: ((d['size']?['weightKg'] ?? 0) as num).toDouble(),
      status: d['status'] ?? 'pending',
      total: (d['pricing']?['total'] ?? 0) as int,
      deliveryOtp: d['deliveryOtp'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
