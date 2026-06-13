import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// اختيار الموقع بدقة المتر: خريطة بدبوس ثابت في المركز، يحرّك المستخدم
/// الخريطة لضبطه. يعيد {lat,lng}. مُسيّج بـ kMapsEnabled — عند تعطيل الخريطة
/// يستخدم موقع GPS الحالي مباشرة (بديل يعمل اليوم بلا مفتاح خريطة).
class PinPickerScreen extends ConsumerStatefulWidget {
  const PinPickerScreen({super.key, this.initialLat, this.initialLng});
  final double? initialLat;
  final double? initialLng;

  @override
  ConsumerState<PinPickerScreen> createState() => _PinPickerScreenState();
}

class _PinPickerScreenState extends ConsumerState<PinPickerScreen> {
  GoogleMapController? _controller;
  late LatLng _center = LatLng(
    widget.initialLat ?? kDefaultMapLat,
    widget.initialLng ?? kDefaultMapLng,
  );
  bool _gpsBusy = false;

  @override
  void initState() {
    super.initState();
    // عند تعطيل الخريطة: نلتقط موقع GPS فورًا ليكون جاهزًا للتأكيد.
    if (!kMapsEnabled) WidgetsBinding.instance.addPostFrameCallback((_) => _useGps());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() => _gpsBusy = true);
    final pos = await ref.read(locationServiceProvider).current();
    if (pos != null) {
      _center = LatLng(pos.latitude, pos.longitude);
      _controller?.animateCamera(CameraUpdate.newLatLng(_center));
    }
    if (mounted) setState(() => _gpsBusy = false);
  }

  void _confirm() => Navigator.of(context)
      .pop({'lat': _center.latitude, 'lng': _center.longitude});

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    if (!kMapsEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text(s('pickOnMap'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.locateFixed,
                    size: 48, color: DyarTokens.brand),
                const SizedBox(height: 16),
                Text(s('useCurrentLocation'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: DyarTokens.inkMuted),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: DyarTokens.ctaHeight,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _gpsBusy ? null : _useGps,
                    icon: _gpsBusy
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.locate),
                    label: Text(s('useCurrentLocation')),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: DyarTokens.ctaHeight,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _confirm,
                    child: Text(s('confirmLocation')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s('pickOnMap'))),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 16),
            onMapCreated: (c) => _controller = c,
            onCameraMove: (p) => _center = p.target,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          // الدبوس الثابت في المركز (يمثّل الموقع المختار)
          const Padding(
            padding: EdgeInsets.only(bottom: 36),
            child: Icon(LucideIcons.mapPin, size: 44, color: DyarTokens.brand),
          ),
          // زر موقعي الحالي
          PositionedDirectional(
            end: 16,
            bottom: 120,
            child: FloatingActionButton.small(
              heroTag: 'gps',
              backgroundColor: Colors.white,
              foregroundColor: DyarTokens.brand,
              onPressed: _gpsBusy ? null : _useGps,
              child: const Icon(LucideIcons.locate),
            ),
          ),
          // شريط التأكيد السفلي
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s('dragToAdjust'),
                      style: const TextStyle(color: DyarTokens.inkMuted)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: DyarTokens.ctaHeight,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(LucideIcons.check),
                      label: Text(s('confirmLocation'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
