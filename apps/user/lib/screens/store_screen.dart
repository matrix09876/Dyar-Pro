import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../state/cart.dart';
import 'checkout_screen.dart';

/// صفحة المتجر: القائمة + إضافة للسلة + شريط CTA لاصق بالمجموع
/// (StickyCTA وفق الـ Handoff).
class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key, required this.storeId});
  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cart = ref.watch(cartProvider);
    final storeStream = ref.read(storeServiceProvider).watchStore(storeId);
    final menuStream = ref.read(storeServiceProvider).watchMenu(storeId);

    return Scaffold(
      body: StreamBuilder<Store?>(
        stream: storeStream,
        builder: (context, storeSnap) {
          final store = storeSnap.data;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(store?.name ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  background: store?.coverUrl != null
                      ? Image.network(store!.coverUrl!, fit: BoxFit.cover)
                      : Container(color: DyarTokens.brandLight),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: StreamBuilder<List<MenuItem>>(
                  stream: menuStream,
                  builder: (context, menuSnap) {
                    final items = (menuSnap.data ?? [])
                        .where((i) => i.available)
                        .toList();
                    if (items.isEmpty) {
                      return SliverToBoxAdapter(
                          child: EmptyState(
                              message: s('noData'),
                              icon: LucideIcons.utensils));
                    }
                    return SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) => _MenuTile(
                          storeId: storeId, item: items[i]),
                    );
                  },
                ),
              ),
              // مساحة للشريط اللاصق
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          );
        },
      ),
      bottomSheet: cart.isEmpty || cart.storeId != storeId
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: CtaButton(
                label: '${s('cart')} (${cart.count})',
                trailing: MoneyText.format(cart.subtotal),
                icon: LucideIcons.shoppingCart,
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const CheckoutScreen())),
              ),
            ),
    );
  }
}

class _MenuTile extends ConsumerWidget {
  const _MenuTile({required this.storeId, required this.item});
  final String storeId;
  final MenuItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final qty = cart.storeId == storeId ? (cart.lines[item.id]?.qty ?? 0) : 0;

    return DyarCard(
      child: Row(
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(item.imageUrl!,
                  width: 64, height: 64, fit: BoxFit.cover),
            ),
          if (item.imageUrl != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (item.description != null)
                  Text(item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: DyarTokens.inkMuted)),
                const SizedBox(height: 4),
                MoneyText(item.price,
                    style: const TextStyle(
                        color: DyarTokens.brand,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          // عدّاد إضافة/إزالة — أهداف لمس ≥44px
          if (qty == 0)
            IconButton.filled(
              style: IconButton.styleFrom(
                  backgroundColor: DyarTokens.brand,
                  minimumSize: const Size(44, 44)),
              onPressed: () =>
                  ref.read(cartProvider.notifier).add(storeId, item),
              icon: const Icon(LucideIcons.plus, color: Colors.white),
            )
          else
            Row(children: [
              IconButton.outlined(
                style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44)),
                onPressed: () =>
                    ref.read(cartProvider.notifier).remove(item),
                icon: const Icon(LucideIcons.minus),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$qty',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                    backgroundColor: DyarTokens.brand,
                    minimumSize: const Size(44, 44)),
                onPressed: () =>
                    ref.read(cartProvider.notifier).add(storeId, item),
                icon: const Icon(LucideIcons.plus, color: Colors.white),
              ),
            ]),
        ],
      ),
    );
  }
}
