import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// خدمات الموقع: طلب صلاحية المستخدم صراحةً، الحصول على موقع عالي الدقة
/// (~10م)، بثّ مستمر، وفتح الملاحة عبر Google Maps أو Waze.
class LocationService {
  /// يطلب الإذن من المستخدم (لا يعمل بدون موافقته). يعيد false إن رُفض.
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// موقع لحظي بأعلى دقة (هدف ~10م).
  Future<Position?> current() async {
    if (!await ensurePermission()) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best, // أعلى دقة متاحة
        distanceFilter: 5,
      ),
    );
  }

  /// بثّ مستمر لموقع السائق (يُستخدم لتحديث currentLocation كل بضعة أمتار).
  Stream<Position> stream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10, // تحديث كل 10م
        ),
      );

  /// فتح الملاحة — يفضّل Waze إن وُجد، وإلا Google Maps.
  Future<void> navigate(double lat, double lng, {bool preferWaze = true}) async {
    final waze = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    final wazeWeb = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    final gmaps = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (preferWaze && await canLaunchUrl(waze)) {
      await launchUrl(waze, mode: LaunchMode.externalApplication);
    } else if (preferWaze && await canLaunchUrl(wazeWeb)) {
      await launchUrl(wazeWeb, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(gmaps, mode: LaunchMode.externalApplication);
    }
  }
}
