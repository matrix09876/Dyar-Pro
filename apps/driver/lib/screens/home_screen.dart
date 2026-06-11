import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'active_task_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';

final myDriverProvider = StreamProvider<DriverProfile?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(driverServiceProvider).watchProfile(uid);
});

final availableOrdersProvider = StreamProvider<List<DyarOrder>>(
    (ref) => ref.watch(orderServiceProvider).watchAvailableForDrivers());

/// رئيسية السائق: تبديل متصل/غير متصل + بانر التعرفة الديناميكية +
/// الطلبات المتاحة + الانتقال للمهمة النشطة.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  Future<void> _toggleOnline(bool v) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final svc = ref.read(driverServiceProvider);
    await svc.setOnline(uid, v);
    if (v) {
      // إرسال الموقع الحالي عند الاتصال (التتبع الدوري عبر geolocator stream)
      try {
        final perm = await Geolocator.requestPermission();
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition();
          await svc.updateLocation(uid, pos.latitude, pos.longitude);
        }
      } catch (_) {/* الموقع اختياري في المحاكي */}
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final pages = [
      _DashboardTab(onToggle: _toggleOnline),
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
              icon: const Icon(LucideIcons.wallet), label: s('earnings')),
          NavigationDestination(
              icon: const Icon(LucideIcons.userCircle2), label: s('profile')),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab({required this.onToggle});
  final Future<void> Function(bool) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final driver = ref.watch(myDriverProvider).value;
    final available = ref.watch(availableOrdersProvider).value ?? [];
    final online = driver?.isOnline ?? false;

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
                onChanged: onToggle,
                activeLabel: s('online'),
                inactiveLabel: s('offline'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // بانر التعرفة الديناميكية (مثل التطبيق الحالي — لكن أوضح)
          if (online)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DyarTokens.success,
                borderRadius: BorderRadius.circular(DyarTokens.radius),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.trendingUp, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s('surgeActive'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // المهمة النشطة
          if (driver?.activeOrderId != null) ...[
            Text(s('activeTask'),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            DyarCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      ActiveTaskScreen(orderId: driver!.activeOrderId!))),
              child: Row(
                children: [
                  const Icon(LucideIcons.navigation, color: DyarTokens.brand),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(s('activeTask'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700))),
                  const Icon(Icons.chevron_left),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // الطلبات المتاحة
          Text(s('availableOrders'),
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (!online)
            EmptyState(message: s('offline'), icon: LucideIcons.powerOff)
          else if (available.isEmpty)
            EmptyState(message: s('noData'), icon: LucideIcons.packageSearch)
          else
            ...available.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AvailableOrderCard(order: o),
                )),
        ],
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
                      builder: (_) => ActiveTaskScreen(orderId: order.id)));
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
