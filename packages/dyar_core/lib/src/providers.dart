import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i18n/strings.dart';
import 'services/auth_service.dart';
import 'services/order_service.dart';
import 'services/store_service.dart';
import 'services/driver_service.dart';
import 'services/ride_service.dart';
import 'services/parcel_service.dart';
import 'services/booking_service.dart';
import 'services/user_service.dart';
import 'services/location_service.dart';
import 'services/tracking_service.dart';
import 'services/market_service.dart';

/// مزوّدات Riverpod المشتركة بين التطبيقات الثلاثة.

final authServiceProvider = Provider((_) => AuthService());
final orderServiceProvider = Provider((_) => OrderService());
final storeServiceProvider = Provider((_) => StoreService());
final driverServiceProvider = Provider((_) => DriverService());
final rideServiceProvider = Provider((_) => RideService());
final parcelServiceProvider = Provider((_) => ParcelService());
final bookingServiceProvider = Provider((_) => BookingService());
final userServiceProvider = Provider((_) => UserService());
final locationServiceProvider = Provider((_) => LocationService());
final trackingServiceProvider = Provider((_) => TrackingService());
final marketServiceProvider = Provider((_) => MarketService());

final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authServiceProvider).authState);

/// اللغة الحالية (تُحفظ في SharedPreferences على مستوى التطبيق)
final langProvider = StateProvider<DyarLang>((_) => DyarLang.ar);

/// الوضع الليلي
final darkModeProvider = StateProvider<bool>((_) => false);

final stringsProvider = Provider<S>((ref) => S(ref.watch(langProvider)));

/// قواعد الرؤية لكل مدينة — `cities/{id}.categories` من اللوحة.
/// الافتراضي الآمن: كل فئة غير مذكورة تُعتبر ظاهرة (true).
class CityConfig {
  const CityConfig(this.categories);

  /// خريطة `categories.{key} = bool` كما تكتبها اللوحة
  final Map<String, bool> categories;

  /// هل الفئة ظاهرة في هذه المدينة؟ (true إن لم تُضبط)
  bool shows(String key) => categories[key] ?? true;
}

/// وثيقة المدينة الافتراضية: `config/app.defaultCityId` أو أول مدينة
/// `active`. إن لم توجد وثيقة، يُعاد إعداد فارغ (كل شيء ظاهر).
final cityConfigProvider = StreamProvider<CityConfig>((ref) async* {
  final db = FirebaseFirestore.instance;
  String? cityId;
  try {
    final cfg = await db.doc('config/app').get();
    cityId = cfg.data()?['defaultCityId'] as String?;
    if (cityId == null) {
      final q = await db
          .collection('cities')
          .where('active', isEqualTo: true)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) cityId = q.docs.first.id;
    }
  } catch (_) {
    // تعذّر القراءة → افتراضي آمن: إظهار كل شيء
  }
  if (cityId == null) {
    yield const CityConfig({});
    return;
  }
  yield* db.doc('cities/$cityId').snapshots().map((d) {
    final raw = d.data()?['categories'];
    if (raw is! Map) return const CityConfig({});
    return CityConfig({
      for (final e in raw.entries)
        if (e.value is bool) e.key.toString(): e.value as bool,
    });
  });
});
