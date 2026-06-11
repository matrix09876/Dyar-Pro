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
