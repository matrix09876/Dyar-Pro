import 'package:cloud_firestore/cloud_firestore.dart';

/// حجز طاولة/موعد خدمة — مع تذكير قبل 30 دقيقة.
class Booking {
  final String id;
  final String customerUid;
  final String storeId;
  final String type; // table|service
  final int partySize;
  final String? tableId, notes;
  final DateTime? slot;
  final bool reminder;
  final int fee; // أغورة
  final String status; // pending|confirmed|seated|completed|cancelled|no_show

  const Booking({
    required this.id, required this.customerUid, required this.storeId,
    this.type = 'table', this.partySize = 1, this.tableId, this.notes,
    this.slot, this.reminder = false, this.fee = 0, this.status = 'pending',
  });

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Booking(
      id: doc.id,
      customerUid: d['customerUid'] ?? '',
      storeId: d['storeId'] ?? '',
      type: d['type'] ?? 'table',
      partySize: (d['partySize'] ?? 1) as int,
      tableId: d['tableId'],
      notes: d['notes'],
      slot: (d['slot'] as Timestamp?)?.toDate(),
      reminder: d['reminder'] ?? false,
      fee: (d['fee'] ?? 0) as int,
      status: d['status'] ?? 'pending',
    );
  }
}
