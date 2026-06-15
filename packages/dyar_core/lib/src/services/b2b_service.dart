import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/rfq.dart';

/// ديار B2B — طلبات عرض السعر (RFQ). القراءة لحظية من Firestore، والكتابة
/// (إنشاء/تسعير/رد) عبر Cloud Functions (حماية العمولة خادميًا).
class B2bService {
  B2bService({FirebaseFirestore? db, FirebaseFunctions? fns})
      : _db = db ?? FirebaseFirestore.instance,
        _fns = fns ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fns;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('rfqs');

  /// التاجر ينشئ طلب عرض سعر — يعيد rfqId.
  Future<String> createRfq({
    required String storeId,
    required String productName,
    required int qty,
    String note = '',
  }) async {
    final res = await _fns.httpsCallable('createRfq').call({
      'storeId': storeId,
      'productName': productName,
      'qty': qty,
      'note': note,
    });
    return res.data['rfqId'] as String;
  }

  /// المورد يردّ بعرض سعر (تطبيق التاجر/الشريك).
  Future<void> quoteRfq({
    required String rfqId,
    required int unitPrice, // أغورة/وحدة
    int validHours = 48,
    String terms = '',
  }) =>
      _fns.httpsCallable('quoteRfq').call({
        'rfqId': rfqId,
        'unitPrice': unitPrice,
        'validHours': validHours,
        'terms': terms,
      });

  /// التاجر يقبل/يرفض العرض.
  Future<void> respondRfq(String rfqId, bool accept) =>
      _fns.httpsCallable('respondRfq').call({'rfqId': rfqId, 'accept': accept});

  /// طلبات التاجر (المشتري).
  Stream<List<Rfq>> watchMine(String uid) => _col
      .where('merchantUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Rfq.fromDoc).toList());

  /// طلبات واردة لمتجر مورد (تطبيق التاجر/الشريك).
  Stream<List<Rfq>> watchForStore(String storeId) => _col
      .where('storeId', isEqualTo: storeId)
      .where('status', whereIn: ['open', 'quoted'])
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Rfq.fromDoc).toList());
}
