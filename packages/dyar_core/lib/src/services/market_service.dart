import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/market_product.dart';

/// سوق C2C: تصفّح المنتجات المعتمدة، رفع منتج (pending)، تعليم البيع
/// (عبر callable يحتسب عمولة المنصّة على الخادم) وحذف.
class MarketService {
  MarketService({FirebaseFirestore? db, FirebaseFunctions? fns})
      : _db = db ?? FirebaseFirestore.instance,
        _fns = fns ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fns;

  Stream<List<MarketProduct>> watchApproved() => _db
      .collection('marketProducts')
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(MarketProduct.fromDoc).toList());

  Stream<List<MarketProduct>> watchMine(String uid) => _db
      .collection('marketProducts')
      .where('sellerUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(MarketProduct.fromDoc).toList());

  /// رفع منتج جديد — يبدأ pending دومًا (الاعتماد من الإدارة).
  Future<void> create({
    required String sellerUid,
    required String title,
    required String description,
    required int price,
    required String imageUrl,
    required String category,
    String city = '',
  }) =>
      _db.collection('marketProducts').add({
        'sellerUid': sellerUid,
        'title': title,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'city': city,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// تم البيع — العمولة تُحتسب وتُسجَّل على الخادم.
  Future<void> markSold(String productId) =>
      _fns.httpsCallable('markProductSold').call({'productId': productId});

  Future<void> delete(String productId) =>
      _db.doc('marketProducts/$productId').delete();
}
