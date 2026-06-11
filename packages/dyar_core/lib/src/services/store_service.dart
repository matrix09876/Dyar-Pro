import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store.dart';
import '../models/menu_item.dart';

class StoreService {
  StoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('stores');

  /// المتاجر المعتمدة للتصفّح (تطبيق الزبون)
  Stream<List<Store>> watchApproved({String? type}) {
    Query<Map<String, dynamic>> q = _col.where('status', isEqualTo: 'approved');
    if (type != null) q = q.where('type', isEqualTo: type);
    return q.snapshots().map((s) => s.docs.map(Store.fromDoc).toList());
  }

  Stream<Store?> watchStore(String id) => _col.doc(id).snapshots().map(
      (d) => d.exists ? Store.fromDoc(d) : null);

  /// متجر التاجر (حسب المالك)
  Stream<Store?> watchMyStore(String ownerUid) => _col
      .where('ownerUid', isEqualTo: ownerUid)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : Store.fromDoc(s.docs.first));

  Stream<List<MenuItem>> watchMenu(String storeId) => _col
      .doc(storeId)
      .collection('menu')
      .orderBy('sortOrder')
      .snapshots()
      .map((s) => s.docs.map(MenuItem.fromDoc).toList());

  /// تبديل فتح/إغلاق المتجر (زر "نشط" في تطبيق التاجر)
  Future<void> setOpen(String storeId, bool open) =>
      _col.doc(storeId).update({'isOpen': open});

  /// تبديل توفر صنف
  Future<void> setItemAvailable(String storeId, String itemId, bool v) =>
      _col.doc(storeId).collection('menu').doc(itemId).update({'available': v});

  /// تغيير سعر صنف (وضع "تغيير السعر" في إدارة القائمة)
  Future<void> setItemPrice(String storeId, String itemId, int price) =>
      _col.doc(storeId).collection('menu').doc(itemId).update({'price': price});

  Future<void> upsertItem(String storeId, String? itemId, Map<String, dynamic> data) {
    final menu = _col.doc(storeId).collection('menu');
    return itemId == null
        ? menu.add(data).then((_) {})
        : menu.doc(itemId).set(data, SetOptions(merge: true));
  }
}
