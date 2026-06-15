import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../state/cart.dart';
import 'store_screen.dart';
import 'tracking_screen.dart';

/// طلباتي: قائمة لحظية + فتح التتبع.
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return SafeArea(
          child: EmptyState(message: s('signIn'), icon: LucideIcons.userCircle2));
    }

    return SafeArea(
      child: StreamBuilder<List<DyarOrder>>(
        stream: ref.read(orderServiceProvider).watchMine(uid),
        builder: (context, snap) {
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return EmptyState(
                message: s('noData'), icon: LucideIcons.receipt);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final o = orders[i];
              return DyarCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TrackingScreen(orderId: o.id))),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('#${o.code}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              Text(
                                  '${o.items.length} · ${o.paymentMethod}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: DyarTokens.inkMuted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusChip(
                                label: s.status(o.status.key),
                                statusKey: o.status.key),
                            const SizedBox(height: 4),
                            MoneyText(o.pricing.total),
                          ],
                        ),
                      ],
                    ),
                    // اطلب مجددًا (نمط Talabat) — يعيد بناء السلة فورًا
                    if (o.status == OrderStatus.delivered) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DyarTokens.brandDark,
                            side: const BorderSide(
                                color: DyarTokens.brand, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          label: Text(s('reorder'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                          onPressed: () {
                            final cart = ref.read(cartProvider.notifier)
                              ..clear();
                            for (final it in o.items) {
                              cart.add(
                                o.storeId,
                                MenuItem(
                                    id: it.itemId,
                                    name: it.name,
                                    price: it.unitPrice),
                                qty: it.qty,
                              );
                            }
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    StoreScreen(storeId: o.storeId)));
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
