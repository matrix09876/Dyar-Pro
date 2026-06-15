import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// شاشة المهمة النشطة: مراحل التوصيل خطوة بخطوة + ملاحة + اتصال.
/// picked_up → on_the_way → delivered (الخادم يفرض التسلسل والأرباح).
class ActiveTaskScreen extends ConsumerWidget {
  const ActiveTaskScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final orderStream = ref.watch(orderServiceProvider).watchOrder(orderId);

    return Scaffold(
      appBar: AppBar(title: Text(s('activeTask'))),
      body: StreamBuilder<DyarOrder?>(
        stream: orderStream,
        builder: (context, snap) {
          final order = snap.data;
          if (order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (order.status.isTerminal) {
            return EmptyState(
                message: s.status(order.status.key),
                icon: LucideIcons.checkCircle2);
          }

          final next = switch (order.status) {
            OrderStatus.assigned => OrderStatus.pickedUp,
            OrderStatus.pickedUp => OrderStatus.onTheWay,
            OrderStatus.onTheWay => OrderStatus.delivered,
            _ => null,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DyarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('#${order.code}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        StatusChip(
                            label: s.status(order.status.key),
                            statusKey: order.status.key),
                      ],
                    ),
                    const Divider(height: 24),
                    ...order.items.map((it) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${it.qty}× ${it.name}'),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s('total')),
                        MoneyText(order.pricing.total),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s('earnings')),
                        MoneyText(
                            order.pricing.deliveryFee + order.pricing.tip,
                            style: const TextStyle(
                                color: DyarTokens.success,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // عنوان التوصيل + ملاحة
              if (order.address != null)
                DyarCard(
                  onTap: () {
                    final lat = order.address!['lat'], lng = order.address!['lng'];
                    if (lat != null && lng != null) {
                      // يفضّل Waze ثم Google Maps (حسب المتوفر على الجهاز)
                      ref.read(locationServiceProvider).navigate(
                          (lat as num).toDouble(), (lng as num).toDouble());
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(LucideIcons.mapPin, color: DyarTokens.brand),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(order.address!['line'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                      Text(s('navigate'),
                          style: const TextStyle(
                              color: DyarTokens.brand,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              if (next != null)
                CtaButton(
                  label: s.status(next.key),
                  icon: LucideIcons.check,
                  onPressed: () => ref
                      .read(orderServiceProvider)
                      .updateStatus(order.id, next),
                ),
            ],
          );
        },
      ),
    );
  }
}
