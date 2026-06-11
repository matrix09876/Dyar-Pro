import 'package:cloud_firestore/cloud_firestore.dart';

/// محادثة الدعم: خيط واحد لكل مستخدم (support/{uid}/messages) —
/// رسائل المستخدم تُطلق رد الـ AI تلقائيًا عبر aiSupportReply بالخادم.
class SupportService {
  SupportService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _msgs(String uid) =>
      _db.collection('support').doc(uid).collection('messages');

  Stream<List<Map<String, dynamic>>> watch(String uid) => _msgs(uid)
      .orderBy('sentAt', descending: false)
      .limitToLast(60)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> send(String uid, String text) async {
    await _db.collection('support').doc(uid).set({
      'uid': uid,
      'subject': text.length > 60 ? '${text.substring(0, 60)}…' : text,
      'status': 'open',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _msgs(uid).add({
      'senderUid': uid,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }
}
