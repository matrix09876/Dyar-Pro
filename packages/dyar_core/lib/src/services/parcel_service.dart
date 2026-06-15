import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/parcel.dart';

/// الطرود: إنشاء شحنة (مع OTP) + متابعة + تأكيد التسليم برمز.
class ParcelService {
  ParcelService({FirebaseFirestore? db, FirebaseFunctions? fns})
      : _db = db ?? FirebaseFirestore.instance,
        _fns = fns ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fns;

  Future<Map<String, dynamic>> create({
    required Map<String, dynamic> sender,
    required Map<String, dynamic> recipient,
    double weightKg = 1,
    String paymentMethod = 'cash',
  }) async {
    final res = await _fns.httpsCallable('createParcel').call({
      'sender': sender,
      'recipient': recipient,
      'weightKg': weightKg,
      'paymentMethod': paymentMethod,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> confirmDelivery(String parcelId, String otp) =>
      _fns.httpsCallable('confirmParcelDelivery').call({
        'parcelId': parcelId,
        'otp': otp,
      });

  Stream<Parcel?> watch(String parcelId) => _db
      .doc('parcels/$parcelId')
      .snapshots()
      .map((d) => d.exists ? Parcel.fromDoc(d) : null);

  Stream<List<Parcel>> watchMine(String uid) => _db
      .collection('parcels')
      .where('senderUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Parcel.fromDoc).toList());
}

extension ParcelDriverOps on ParcelService {
  /// الطرود المتاحة للسائقين (pending بلا سائق)
  Stream<List<Parcel>> watchAvailable() => FirebaseFirestore.instance
      .collection('parcels')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs
          .map(Parcel.fromDoc)
          .where((p) => p.driverUid == null)
          .toList());

  Future<void> claim(String parcelId) => FirebaseFunctions.instance
      .httpsCallable('claimParcel')
      .call({'parcelId': parcelId});

  Future<void> startTransit(String parcelId) => FirebaseFunctions.instance
      .httpsCallable('startParcelTransit')
      .call({'parcelId': parcelId});
}
