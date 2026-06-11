import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// مصادقة موحّدة: هاتف/OTP (الأساسي في السوق المحلي) + بريد كاحتياط.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// إرسال OTP لرقم الهاتف. تُستدعى verificationCompleted تلقائيًا على أندرويد.
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (cred) async => _auth.signInWithCredential(cred),
      verificationFailed: (e) => onError(e.message ?? 'verification failed'),
      codeSent: (id, _) => onCodeSent(id),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> verifyOtp(String verificationId, String code) {
    final cred = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: code);
    return _auth.signInWithCredential(cred);
  }

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// إنشاء/تحديث ملف المستخدم بعد الدخول + تسجيل FCM token.
  Future<void> ensureProfile({String? name}) async {
    final u = _auth.currentUser;
    if (u == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    // 🛡️ سجل أمني: حدث تسجيل دخول (يظهر في لوحة السجلات)
    await _db.collection('logs').add({
      'category': 'security',
      'action': 'sign-in',
      'by': u.uid,
      'platform': defaultTargetPlatform.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('users').doc(u.uid).set({
      if (name != null) 'name': name,
      'phone': u.phoneNumber,
      'email': u.email,
      if (token != null) 'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() => _auth.signOut();
}
