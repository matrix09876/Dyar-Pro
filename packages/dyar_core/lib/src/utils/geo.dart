import 'dart:math';

/// مسافة هافرساين بالكيلومترات — تُستخدم لفرز "الأقرب إليك" في
/// المتاجر/المزوّدين (نفس معادلة الخادم في zones/commission).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;

/// تنسيق المسافة للعرض: أقل من كيلومتر بالأمتار، وإلا بكسر واحد.
String formatKm(double km) =>
    km < 1 ? '${(km * 1000).round()} م' : '${km.toStringAsFixed(1)} كم';
