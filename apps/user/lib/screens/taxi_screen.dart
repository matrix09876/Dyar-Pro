import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// طلب تاكسي: اختيار الفئة (قياسي/راحة/عائلي) → طلب مشوار بتسعير من الخادم
/// → متابعة حالة المشوار لحظيًا. زر SOS للطوارئ (ميزة حماية ديار).
class TaxiScreen extends ConsumerStatefulWidget {
  const TaxiScreen({super.key});

  @override
  ConsumerState<TaxiScreen> createState() => _TaxiScreenState();
}

class _TaxiScreenState extends ConsumerState<TaxiScreen> {
  String _tier = 'standard';
  bool _busy = false;
  String? _rideId;

  // إحداثيات تجريبية (تُستبدل بالموقع الحقيقي + اختيار خريطة)
  static const _pickup = (lat: 32.868, lng: 35.370);
  static const _drop = (lat: 32.880, lng: 35.385);

  Future<void> _request() async {
    final s = ref.read(stringsProvider);
    setState(() => _busy = true);
    try {
      final res = await ref.read(rideServiceProvider).request(
            pickupLat: _pickup.lat, pickupLng: _pickup.lng,
            dropLat: _drop.lat, dropLng: _drop.lng,
            tier: _tier,
          );
      setState(() => _rideId = res['rideId'] as String);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s('error'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    if (_rideId != null) return _RideTracking(rideId: _rideId!);

    final tiers = [
      ('standard', s('standard'), LucideIcons.car, 1200),
      ('comfort', s('comfort'), LucideIcons.car, 1800),
      ('xl', s('xl'), LucideIcons.bus, 2400),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s('taxi')),
        actions: [
          // زر الطوارئ SOS
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TextButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(s('sosTitle')),
                  content: const Text('100 / 101'),
                ),
              ),
              icon: const Icon(LucideIcons.shieldAlert, color: DyarTokens.danger),
              label: Text('SOS',
                  style: const TextStyle(
                      color: DyarTokens.danger, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DyarCard(
            child: Column(
              children: [
                Row(children: [
                  const Icon(LucideIcons.circle, size: 14, color: DyarTokens.success),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s('pickupLocation'))),
                ]),
                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 6),
                  child: SizedBox(
                      height: 22,
                      child: VerticalDivider(width: 2, thickness: 1.5)),
                ),
                Row(children: [
                  const Icon(LucideIcons.mapPin, size: 14, color: DyarTokens.brand),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s('dropoffLocation'))),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...tiers.map((t) {
            final (id, label, icon, base) = t;
            final selected = _tier == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: selected ? DyarTokens.brandLight : null,
                borderRadius: BorderRadius.circular(DyarTokens.radius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(DyarTokens.radius),
                  onTap: () => setState(() => _tier = id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: selected ? DyarTokens.brand : Colors.black12,
                          width: selected ? 2 : 1),
                      borderRadius: BorderRadius.circular(DyarTokens.radius),
                    ),
                    child: Row(children: [
                      Icon(icon, color: DyarTokens.brandDark),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      Text('~ ${MoneyText.format(base)}',
                          style: const TextStyle(color: DyarTokens.inkMuted)),
                    ]),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          CtaButton(
            label: s('requestRide'),
            icon: LucideIcons.car,
            loading: _busy,
            onPressed: _request,
          ),
        ],
      ),
    );
  }
}

class _RideTracking extends ConsumerWidget {
  const _RideTracking({required this.rideId});
  final String rideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s('taxi'))),
      body: StreamBuilder<Ride?>(
        stream: ref.read(rideServiceProvider).watch(rideId),
        builder: (context, snap) {
          final ride = snap.data;
          if (ride == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DyarCard(
                child: Column(children: [
                  if (ride.status == 'searching') ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(s('searchingDriver')),
                  ] else
                    StatusChip(label: ride.status, statusKey: ride.status),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${s('total')} (${ride.distanceKm} km)'),
                      MoneyText(ride.total),
                    ],
                  ),
                  if (ride.surge > 1)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('Surge ×${ride.surge}',
                          style: const TextStyle(
                              color: DyarTokens.warning,
                              fontWeight: FontWeight.w700)),
                    ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
