import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'active_task_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';
import 'register_screen.dart';
import 'history_screen.dart';
import 'active_parcel_screen.dart';
import 'active_ride_screen.dart';

final myDriverProvider = StreamProvider<DriverProfile?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(driverServiceProvider).watchProfile(uid);
});

final availableOrdersProvider = StreamProvider<List<DyarOrder>>(
    (ref) => ref.watch(orderServiceProvider).watchAvailableForDrivers());

final availableParcelsProvider = StreamProvider<List<Parcel>>(
    (ref) => ref.watch(parcelServiceProvider).watchAvailable());

final searchingRidesProvider = StreamProvider<List<Ride>>(
    (ref) => ref.watch(rideServiceProvider).watchSearching());

/// رئيسية السائق: تبديل متصل/غير متصل + بانر التعرفة الديناميكية +
/// الطلبات المتاحة + الانتقال للمهمة النشطة.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  StreamSubscription<Position>? _locSub;

  Future<void> _toggleOnline(bool v) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final svc = ref.read(driverServiceProvider);
    final loc = ref.read(locationServiceProvider);
    final tracking = ref.read(trackingServiceProvider);
    await svc.setOnline(uid, v);

    if (v) {
      // بثّ حيّ مستمر لموقع السائق (بموافقته) — يظهر في تطبيق المستخدم
      if (await loc.ensurePermission()) {
        final pos = await loc.current();
        if (pos != null) {
          await svc.updateLocation(uid, pos.latitude, pos.longitude);
        }
        _locSub?.cancel();
        _locSub = loc.stream().listen((p) =>
            tracking.pushLocation(uid, p.latitude, p.longitude, p.heading));
      }
    } else {
      _locSub?.cancel();
      _locSub = null;
    }
  }

  @override
  void dispose() {
    _locSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    // بوابة KYC: لا ملف سائق → التسجيل؛ pending → شاشة انتظار الموافقة
    final driverAsync = ref.watch(myDriverProvider);
    final driver = driverAsync.value;
    if (!driverAsync.isLoading && driver == null) {
      return const DriverRegisterScreen();
    }
    if (driver != null && driver.status == 'pending') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⏳', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(s('pendingApprovalNote'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: Text(s('logout'),
                    style: const TextStyle(color: DyarTokens.danger)),
              ),
            ]),
          ),
        ),
      );
    }

    final pages = [
      _DashboardTab(onToggle: _toggleOnline),
      const HistoryScreen(),
      const EarningsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(LucideIcons.bike), label: s('home')),
          NavigationDestination(
              icon: const Icon(LucideIcons.packageCheck),
              label: s('history')),
          NavigationDestination(
              icon: const Icon(LucideIcons.wallet), label: s('earnings')),
          NavigationDestination(
              icon: const Icon(LucideIcons.userCircle2), label: s('profile')),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerStatefulWidget {
  const _DashboardTab({required this.onToggle});
  final Future<void> Function(bool) onToggle;

  @override
  ConsumerState<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<_DashboardTab> {
  String _type = 'orders'; // orders | parcels | rides

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final driver = ref.watch(myDriverProvider).value;
    final online = driver?.isOnline ?? false;

    final orders = ref.watch(availableOrdersProvider).value ?? const [];
    final parcels = ref.watch(availableParcelsProvider).value ?? const [];
    final rides = ref.watch(searchingRidesProvider).value ?? const [];

    // المهمة النشطة الحالية (طلب / مشوار عبر بادئة ride: / طرد)
    final activeOrder = driver?.activeOrderId;
    final isRide = activeOrder?.startsWith('ride:') ?? false;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${s('appName')} Driver',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              ActiveToggle(
                value: online,
                onChanged: widget.onToggle,
                activeLabel: s('online'),
                inactiveLabel: s('offline'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // بانر التعرفة الديناميكية
          if (online)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFF16A34A),
                  Color(0xFF065F46),
                ]),
                borderRadius: BorderRadius.circular(DyarTokens.radius),
              ),
              child: Row(children: [
                const Icon(LucideIcons.trendingUp, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s('surgeActive'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ]),
            ),
          const SizedBox(height: 14),

          // المهام النشطة (طلب/مشوار/طرد)
          if (activeOrder != null)
            _ActiveBanner(
              emoji: isRide ? '🚕' : '🍔',
              label: s('activeTask'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => isRide
                      ? ActiveRideScreen(
                          rideId: activeOrder.substring(5))
                      : ActiveTaskScreen(orderId: activeOrder))),
            ),
          if (driver?.activeParcelId != null)
            _ActiveBanner(
              emoji: '📦',
              label: '${s('parcel')} — ${s('activeTask')}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ActiveParcelScreen(
                      parcelId: driver!.activeParcelId!))),
            ),
          if (activeOrder != null || driver?.activeParcelId != null)
            const SizedBox(height: 16),

          // أنواع المهام
          Row(children: [
            _TypeChip(
                emoji: '🍔',
                label: s('orders'),
                count: orders.length,
                selected: _type == 'orders',
                onTap: () => setState(() => _type = 'orders')),
            const SizedBox(width: 8),
            _TypeChip(
                emoji: '📦',
                label: s('parcels'),
                count: parcels.length,
                selected: _type == 'parcels',
                onTap: () => setState(() => _type = 'parcels')),
            const SizedBox(width: 8),
            _TypeChip(
                emoji: '🚕',
                label: s('taxi'),
                count: rides.length,
                selected: _type == 'rides',
                onTap: () => setState(() => _type = 'rides')),
          ]),
          const SizedBox(height: 14),

          if (!online)
            EmptyState(message: s('offline'), icon: LucideIcons.powerOff)
          else ...[
            if (_type == 'orders')
              if (orders.isEmpty)
                EmptyState(
                    message: s('noData'), icon: LucideIcons.packageSearch)
              else
                ...orders.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AvailableOrderCard(order: o),
                    )),
            if (_type == 'parcels')
              if (parcels.isEmpty)
                EmptyState(message: s('noData'), icon: LucideIcons.package)
              else
                ...parcels.map((pcl) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AvailableParcelCard(parcel: pcl),
                    )),
            if (_type == 'rides')
              if (rides.isEmpty)
                EmptyState(message: s('noData'), icon: LucideIcons.car)
              else
                ...rides.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AvailableRideCard(ride: r),
                    )),
          ],
        ],
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner(
      {required this.emoji, required this.label, required this.onTap});
  final String emoji, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFFFF8A3D),
              DyarTokens.brandDark,
            ]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: DyarTokens.brand.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800))),
            const Icon(Icons.chevron_left, color: Colors.white),
          ]),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(
      {required this.emoji,
      required this.label,
      required this.count,
      required this.selected,
      required this.onTap});
  final String emoji, label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [
                    Color(0xFFFF8A3D),
                    DyarTokens.brandDark,
                  ])
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? null
                : Border.all(color: Colors.black12),
          ),
          child: Column(children: [
            Text('$emoji $count',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : null)),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : DyarTokens.inkMuted)),
          ]),
        ),
      ),
    );
  }
}

class _AvailableOrderCard extends ConsumerWidget {
  const _AvailableOrderCard({required this.order});
  final DyarOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return DyarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${order.code}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              MoneyText(order.pricing.deliveryFee + order.pricing.tip,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: DyarTokens.success)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${order.items.length} ${s('orders')} · ${order.paymentMethod}',
              style: const TextStyle(color: DyarTokens.inkMuted)),
          const SizedBox(height: 12),
          CtaButton(
            label: s('claim'),
            icon: LucideIcons.handMetal,
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              try {
                await ref
                    .read(driverServiceProvider)
                    .claimOrder(uid, order.id);
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          ActiveTaskScreen(orderId: order.id)));
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s('error'))));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AvailableParcelCard extends ConsumerWidget {
  const _AvailableParcelCard({required this.parcel});
  final Parcel parcel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return DyarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📦 ${parcel.weightKg} كغم',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              MoneyText((parcel.total * 0.8).round(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: DyarTokens.success)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              '${parcel.sender['name'] ?? ''} ← ${parcel.recipient['name'] ?? ''}',
              style: const TextStyle(color: DyarTokens.inkMuted)),
          const SizedBox(height: 12),
          CtaButton(
            label: s('claim'),
            icon: LucideIcons.package,
            onPressed: () async {
              try {
                await ref.read(parcelServiceProvider).claim(parcel.id);
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          ActiveParcelScreen(parcelId: parcel.id)));
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s('error'))));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AvailableRideCard extends ConsumerWidget {
  const _AvailableRideCard({required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return DyarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '🚕 ${ride.distanceKm} كم'
                  '${ride.surge > 1 ? ' · ×${ride.surge}' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              MoneyText((ride.total * 0.85).round(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: DyarTokens.success)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${ride.pickup['address'] ?? '—'} ← ${ride.dropoff['address'] ?? '—'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: DyarTokens.inkMuted),
          ),
          const SizedBox(height: 12),
          CtaButton(
            label: s('claim'),
            icon: LucideIcons.car,
            onPressed: () async {
              try {
                await ref.read(rideServiceProvider).accept(ride.id);
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ActiveRideScreen(rideId: ride.id)));
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s('error'))));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
