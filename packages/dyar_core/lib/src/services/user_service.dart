import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/app_user.dart';

/// ملف المستخدم: العناوين، المفضلة، الحساسية، الإشعارات — كلها مربوطة
/// بوثيقة users/{uid}. الرصيد للقراءة فقط (يُعدَّل عبر الخادم).
class UserService {
  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<AppUser?> watch(String uid) =>
      _doc(uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);

  // ---- العناوين ----
  Future<void> addAddress(String uid, Map<String, dynamic> address) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return _doc(uid).set({
      'addresses': FieldValue.arrayUnion([{'id': id, ...address}]),
    }, SetOptions(merge: true));
  }

  Future<void> removeAddress(String uid, Map<String, dynamic> address) =>
      _doc(uid).update({'addresses': FieldValue.arrayRemove([address])});

  // ---- المفضلة ----
  Future<void> toggleFavoriteStore(String uid, String storeId, bool fav) =>
      _doc(uid).set({
        'favorites': {
          'stores': fav
              ? FieldValue.arrayUnion([storeId])
              : FieldValue.arrayRemove([storeId]),
        },
      }, SetOptions(merge: true));

  // ---- الحساسية ----
  Future<void> setAllergies(String uid, List<String> allergies) =>
      _doc(uid).set({'allergies': allergies}, SetOptions(merge: true));

  // ---- الإشعارات ----
  Stream<List<Map<String, dynamic>>> watchNotifications(String uid) => _db
      .collection('notifications')
      .where('uid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> markNotificationRead(String id) =>
      _db.collection('notifications').doc(id).update({'read': true});

  // ---- بطاقات الهدايا (خادميًا بالكامل: وسم + رصيد + حركة مالية) ----
  Future<int> redeemGiftCard(String uid, String code) async {
    final res = await FirebaseFunctions.instance
        .httpsCallable('redeemGiftCard')
        .call({'code': code});
    return (res.data['amount'] ?? 0) as int;
  }
}
