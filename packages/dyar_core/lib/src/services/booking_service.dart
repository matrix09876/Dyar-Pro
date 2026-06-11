import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/booking.dart';

/// الحجوزات (طاولة مطعم / موعد خدمة): الإنشاء وتغيير الحالة عبر
/// Cloud Functions (الرسوم من الخادم)، والقراءة لحظية من Firestore.
class BookingService {
  BookingService({FirebaseFirestore? db, FirebaseFunctions? fns})
      : _db = db ?? FirebaseFirestore.instance,
        _fns = fns ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fns;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');

  /// إنشاء حجز عبر الخادم — يعيد bookingId + fee.
  Future<Map<String, dynamic>> createBooking({
    required String storeId,
    required String type, // table|service
    required int slot, // epoch ms — موعد مستقبلي
    int partySize = 1,
    String? tableId,
    String? notes,
    bool reminder = true,
  }) async {
    final res = await _fns.httpsCallable('createBooking').call({
      'storeId': storeId,
      'type': type,
      'slot': slot,
      'partySize': partySize,
      'tableId': tableId,
      'notes': notes,
      'reminder': reminder,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> updateStatus(String bookingId, String status) =>
      _fns.httpsCallable('updateBookingStatus').call({
        'bookingId': bookingId,
        'status': status,
      });

  /// حجوزات الزبون
  Stream<List<Booking>> watchMine(String uid) => _col
      .where('customerUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Booking.fromDoc).toList());

  /// حجوزات متجر (للتاجر) — الحية فقط أو الكل، مرتبة بالموعد
  Stream<List<Booking>> watchStore(String storeId, {bool liveOnly = true}) {
    Query<Map<String, dynamic>> q =
        _col.where('storeId', isEqualTo: storeId);
    if (liveOnly) {
      q = q.where('status', whereIn: ['pending', 'confirmed', 'seated']);
    }
    return q
        .orderBy('slot')
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(Booking.fromDoc).toList());
  }
}
