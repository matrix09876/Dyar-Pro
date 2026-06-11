import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'shell.dart';

/// طلبات المتجر الحية: قبول/رفض ثم تحضير → جاهز. لحظي عبر Firestore.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final store = ref.watch(myStoreProvider).value;
    if (store == null) {
      return EmptyState(message: s('noData'), icon: LucideIcons.store);
    }

    return StreamBuilder<List<DyarOrder>>(
      stream: ref.read(orderServiceProvider).watchStore(store.id),
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
          itemBuilder: (context, i) => _OrderCard(order: orders[i]),
        );
      },
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
  final DyarOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final svc = ref.read(orderServiceProvider);

    // أزرار الإجراء حسب الحالة (الخادم يفرض الصلاحيات والتسلسل)
    final actions = switch (order.status) {
      OrderStatus.pending => [
          (s('accept'), OrderStatus.accepted, DyarTokens.success),
          (s('reject'), OrderStatus.rejected, DyarTokens.danger),
        ],
      OrderStatus.accepted => [
          (s('preparing'), OrderStatus.preparing, DyarTokens.brand),
        ],
      OrderStatus.preparing => [
          (s('ready'), OrderStatus.ready, DyarTokens.success),
        ],
      _ => <(String, OrderStatus, Color)>[],
    };

    return DyarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${order.code}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              StatusChip(
                  label: s.status(order.status.key),
                  statusKey: order.status.key),
            ],
          ),
          const SizedBox(height: 8),
          ...order.items.map((it) => Text('${it.qty}× ${it.name}')),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${s('payCash')} · ${order.paymentMethod}',
                  style: const TextStyle(color: DyarTokens.inkMuted)),
              MoneyText(order.pricing.total,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (label, status, color) in actions) ...[
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () => svc.updateStatus(order.id, status),
                      child: Text(label),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ]..removeLast(),
            ),
          ],
        ],
      ),
    );
  }
}
