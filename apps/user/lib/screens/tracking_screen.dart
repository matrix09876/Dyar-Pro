import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// تتبع الطلب الحي: خط زمني للمراحل يتحدث لحظيًا + تقييم بعد التسليم.
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s('trackOrder'))),
      body: StreamBuilder<DyarOrder?>(
        stream: ref.read(orderServiceProvider).watchOrder(orderId),
        builder: (context, snap) {
          final order = snap.data;
          if (order == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // مكافئ المرحلة الحالية للخط الزمني
          final current = switch (order.status) {
            OrderStatus.assigned ||
            OrderStatus.pickedUp => OrderStatus.ready,
            _ => order.status,
          };
          final idx = _steps.indexOf(current);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DyarCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${order.code}',
                        style:
                            const TextStyle(fontWeight: FontWeight.w800)),
                    MoneyText(order.pricing.total),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (order.status == OrderStatus.cancelled ||
                  order.status == OrderStatus.rejected)
                EmptyState(
                    message: s.status(order.status.key),
                    icon: LucideIcons.xCircle)
              else
                ..._steps.asMap().entries.map((e) {
                  final done = idx >= e.key;
                  final isCurrent = idx == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Column(children: [
                          Container(
                            height: 28, width: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? DyarTokens.brand
                                  : Colors.grey.shade300,
                            ),
                            child: Icon(
                                done
                                    ? LucideIcons.check
                                    : LucideIcons.circle,
                                size: 16,
                                color: Colors.white),
                          ),
                          if (e.key != _steps.length - 1)
                            Container(
                                height: 26, width: 2.5,
                                color: done
                                    ? DyarTokens.brand
                                    : Colors.grey.shade300),
                        ]),
                        const SizedBox(width: 12),
                        Text(
                          s.status(e.value.key),
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: done ? null : DyarTokens.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              // البث الحي لموقع السائق (مثل المنافسين)
              if (order.driverUid != null &&
                  !order.status.isTerminal &&
                  idx >= 3) ...[
                const SizedBox(height: 16),
                StreamBuilder<Map<String, dynamic>?>(
                  stream: ref
                      .read(trackingServiceProvider)
                      .watchDriverLocation(order.driverUid!),
                  builder: (context, locSnap) {
                    final loc = locSnap.data;
                    return DyarCard(
                      child: Row(children: [
                        const Icon(LucideIcons.navigation,
                            color: DyarTokens.brand),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc == null
                                ? s('searchingDriver')
                                : '${s('driver')} • ${loc['lat']?.toStringAsFixed(4)}, ${loc['lng']?.toStringAsFixed(4)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(LucideIcons.radio,
                            color: DyarTokens.success, size: 18),
                      ]),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),
              if (order.status == OrderStatus.delivered)
                _RateCard(orderId: order.id),
            ],
          );
        },
      ),
    );
  }
}

class _RateCard extends ConsumerStatefulWidget {
  const _RateCard({required this.orderId});
  final String orderId;

  @override
  ConsumerState<_RateCard> createState() => _RateCardState();
}

class _RateCardState extends ConsumerState<_RateCard> {
  int _stars = 0;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    if (_sent) {
      return DyarCard(
          child: Row(children: [
        const Icon(LucideIcons.checkCircle2, color: DyarTokens.success),
        const SizedBox(width: 10),
        Text(s('orderPlaced')),
      ]));
    }
    return DyarCard(
      child: Column(
        children: [
          Text(s('rateOrder'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return IconButton(
                onPressed: () => setState(() => _stars = i + 1),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: DyarTokens.warning, size: 34,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          CtaButton(
            label: s('continue'),
            onPressed: _stars == 0
                ? null
                : () async {
                    await ref
                        .read(orderServiceProvider)
                        .rate(widget.orderId, _stars);
                    if (mounted) setState(() => _sent = true);
                  },
          ),
        ],
      ),
    );
  }
}
