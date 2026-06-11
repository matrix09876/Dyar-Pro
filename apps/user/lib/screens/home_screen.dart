import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'store_screen.dart';
import 'taxi_screen.dart';
import 'parcel_screen.dart';

final approvedStoresProvider = StreamProvider.family<List<Store>, String?>(
    (ref, type) => ref.watch(storeServiceProvider).watchApproved(type: type));

/// الرئيسية الموحّدة (Ultra Home): شبكة خدمات أساسية + قائمة المتاجر —
/// وفق قرار P0 #1 (grid الخدمات أساسي بدل chips).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _type; // null = الكل

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final stores = ref.watch(approvedStoresProvider(_type)).value ?? [];

    final services = [
      (null, s('home'), LucideIcons.layoutGrid),
      ('restaurant', s('restaurants'), LucideIcons.utensils),
      ('grocery', s('groceries'), LucideIcons.shoppingBag),
      ('pharmacy', s('pharmacies'), LucideIcons.pill),
      ('flowers', s('flowers'), LucideIcons.flower2),
      ('service', s('services'), LucideIcons.wrench),
      ('store', s('stores'), LucideIcons.store),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // الترويسة + البحث
          Text(s('appName'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(s('allYouNeed'),
              style: const TextStyle(color: DyarTokens.inkMuted)),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: s('searchHint'),
              prefixIcon: const Icon(LucideIcons.search),
            ),
          ),
          const SizedBox(height: 16),

          // شبكة الخدمات
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final (type, label, icon) = services[i];
                final selected = _type == type;
                return GestureDetector(
                  onTap: () => setState(() => _type = type),
                  child: Column(
                    children: [
                      Container(
                        height: 60, width: 60,
                        decoration: BoxDecoration(
                          color: selected
                              ? DyarTokens.brand
                              : DyarTokens.brandLight,
                          borderRadius:
                              BorderRadius.circular(DyarTokens.radius),
                        ),
                        child: Icon(icon,
                            color: selected
                                ? Colors.white
                                : DyarTokens.brandDark),
                      ),
                      const SizedBox(height: 6),
                      Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // مركز الخدمات الإضافية (تاكسي/طرود) — كل زر مربوط بشاشته
          Text(s('moreServices'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _HubTile(
                icon: LucideIcons.car,
                label: s('taxi'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TaxiScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HubTile(
                icon: LucideIcons.package,
                label: s('parcel'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ParcelScreen())),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // المتاجر
          if (stores.isEmpty)
            EmptyState(message: s('noData'), icon: LucideIcons.store)
          else
            ...stores.map((st) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StoreCard(store: st),
                )),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DyarCard(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: DyarTokens.brand),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700))),
        const Icon(Icons.chevron_left, size: 18),
      ]),
    );
  }
}

class _StoreCard extends ConsumerWidget {
  const _StoreCard({required this.store});
  final Store store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return DyarCard(
      padding: EdgeInsets.zero,
      onTap: store.isOpen
          ? () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StoreScreen(storeId: store.id)))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (store.coverUrl != null)
            Image.network(store.coverUrl!,
                height: 130, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(LucideIcons.star,
                            size: 14, color: DyarTokens.warning),
                        Text(' ${store.rating} (${store.ratingCount})  ·  ',
                            style: const TextStyle(fontSize: 12)),
                        const Icon(LucideIcons.clock,
                            size: 14, color: DyarTokens.inkMuted),
                        Text(' ${store.prepTimeMins}m',
                            style: const TextStyle(fontSize: 12)),
                      ]),
                    ],
                  ),
                ),
                if (!store.isOpen)
                  StatusChip(label: s('offline'), statusKey: 'cancelled')
                else
                  MoneyText(store.deliveryFee,
                      style: const TextStyle(
                          color: DyarTokens.inkMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
