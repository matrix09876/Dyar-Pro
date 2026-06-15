import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// خريطة تتبّع حية: موقع السائق (يتحرك لحظيًا) + وجهة التسليم.
/// مُسيّجة بـ kMapsEnabled — حتى ضبط مفتاح الخريطة الأصلي تعرض بديلًا أنيقًا
/// (وجهة + زر فتح بالملاحة الخارجية) دون أي تعطّل.
class LiveTrackingMap extends ConsumerStatefulWidget {
  const LiveTrackingMap({
    super.key,
    required this.destLat,
    required this.destLng,
    this.driverUid,
  });
  final double destLat;
  final double destLng;
  final String? driverUid;

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap> {
  GoogleMapController? _controller;
  Stream<DriverLocation?>? _stream;

  @override
  void initState() {
    super.initState();
    _bindStream();
  }

  @override
  void didUpdateWidget(LiveTrackingMap old) {
    super.didUpdateWidget(old);
    if (old.driverUid != widget.driverUid) _bindStream();
  }

  // بثّ مُخزَّن مرة واحدة (لا يُعاد الاشتراك مع كل rebuild — أداء/استقرار).
  void _bindStream() {
    _stream = (kMapsEnabled && widget.driverUid != null)
        ? ref.read(driverServiceProvider).watchLocation(widget.driverUid!)
        : Stream<DriverLocation?>.value(null);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final dest = LatLng(widget.destLat, widget.destLng);

    if (!kMapsEnabled) {
      return _MapFallback(destLat: widget.destLat, destLng: widget.destLng);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(DyarTokens.radius),
      child: SizedBox(
        height: 220,
        child: StreamBuilder<DriverLocation?>(
          stream: _stream,
          builder: (context, snap) {
            final driver = snap.data;
            if (driver != null && _controller != null) {
              // تحريك الكاميرا بعد إطار البناء (لا أثناءه).
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _controller?.animateCamera(
                  CameraUpdate.newLatLng(LatLng(driver.lat, driver.lng)),
                );
              });
            }
            final markers = <Marker>{
              Marker(
                markerId: const MarkerId('dest'),
                position: dest,
                infoWindow: InfoWindow(title: s('dropoffLocation')),
              ),
              if (driver != null)
                Marker(
                  markerId: const MarkerId('driver'),
                  position: LatLng(driver.lat, driver.lng),
                  rotation: driver.heading,
                  flat: true,
                  infoWindow: InfoWindow(title: s('driver')),
                ),
            };
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: driver != null
                    ? LatLng(driver.lat, driver.lng)
                    : dest,
                zoom: 14,
              ),
              markers: markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (c) => _controller = c,
            );
          },
        ),
      ),
    );
  }
}

/// بديل الخريطة قبل تفعيل المفتاح — وجهة + زر فتح بالملاحة الخارجية.
class _MapFallback extends ConsumerWidget {
  const _MapFallback({required this.destLat, required this.destLng});
  final double destLat;
  final double destLng;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final hasDest = destLat != 0 || destLng != 0;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: DyarTokens.brandLight,
        borderRadius: BorderRadius.circular(DyarTokens.radius),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.mapPin, color: DyarTokens.brand, size: 30),
          const SizedBox(height: 8),
          Text(s('dropoffLocation'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          if (hasDest) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(locationServiceProvider).navigate(destLat, destLng),
              icon: const Icon(LucideIcons.navigation, size: 16),
              label: Text(s('openInMaps')),
            ),
          ],
        ],
      ),
    );
  }
}
