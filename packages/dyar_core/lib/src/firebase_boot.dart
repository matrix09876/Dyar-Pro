import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// وضع الديمو: تشغيل التطبيقات على محاكيات Firebase بلا أي مفاتيح.
/// التفعيل: flutter run --dart-define=DYAR_EMU=true
const bool kDyarEmulators = bool.fromEnvironment('DYAR_EMU');

Future<void> initDyarFirebase() async {
  if (kDyarEmulators) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo-key',
        appId: '1:000000000000:web:demo',
        messagingSenderId: '000000000000',
        projectId: 'demo-dyar',
        authDomain: 'demo-dyar.firebaseapp.com',
      ),
    );
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
  } else {
    // الإنتاج: إعدادات المشروع الحقيقية (flutterfire configure)
    await Firebase.initializeApp();
  }
}
