import 'package:cloud_firestore/cloud_firestore.dart';

/// DocumentSnapshot وهمي خفيف للاختبارات — يعيد id + data() فقط،
/// وبقية الأعضاء عبر noSuchMethod (نمط Dart الرسمي للتزييف).
class FakeDoc implements DocumentSnapshot<Map<String, dynamic>> {
  FakeDoc(this.id, this._data);
  @override
  final String id;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? data() => _data;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
