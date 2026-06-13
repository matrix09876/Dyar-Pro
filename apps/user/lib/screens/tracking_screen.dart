import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../widgets/live_map.dart';

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
              // بطاقة ETA البطلة (نمط Wolt): عدّ تنازلي حي + شريط تقدّم
              if (!order.status.isTerminal)
                _EtaHero(order: order)
              else
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
                // خريطة حية: السائق يتحرك نحو وجهة التسليم
                LiveTrackingMap(
                  destLat: (order.address?['lat'] as num?)?.toDouble() ?? 0,
                  destLng: (order.address?['lng'] as num?)?.toDouble() ?? 0,
                  driverUid: order.driverUid,
                ),
                const SizedBox(height: 12),
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

/// بطاقة الوصول المتوقع: تقدير 35 دقيقة من إنشاء الطلب (يُستبدل بـ eta
/// الخادم عند توفره) مع عدّ تنازلي يتحدث كل ثانية وشريط تقدّم.
class _EtaHero extends ConsumerStatefulWidget {
  const _EtaHero({required this.order});
  final DyarOrder order;

  @override
  ConsumerState<_EtaHero> createState() => _EtaHeroState();
}

class _EtaHeroState extends ConsumerState<_EtaHero> {
  late final Stream<int> _tick =
      Stream.periodic(const Duration(seconds: 1), (i) => i);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final created = widget.order.createdAt ?? DateTime.now();
    // 🧠 ETA متعلَّم من الخادم (متوسط تسليمات المتجر الفعلية)
    final etaMins = widget.order.etaMins ?? 35;
    final eta = created.add(Duration(minutes: etaMins));

    return StreamBuilder<int>(
      stream: _tick,
      builder: (context, _) {
        final remaining = eta.difference(DateTime.now());
        final mins = remaining.inMinutes.clamp(0, 99);
        final secs = (remaining.inSeconds % 60).clamp(0, 59);
        final progress = 1 -
            (remaining.inSeconds / Duration(minutes: etaMins).inSeconds)
                .clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFFFF8A3D),
              DyarTokens.brandDark,
            ]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: DyarTokens.brand.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${widget.order.code}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700)),
                  Text(MoneyText.format(widget.order.pricing.total),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 10),
              Text(s('etaArrives'),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              Text(
                remaining.isNegative
                    ? '🛵 ${s.status(widget.order.status.key)}'
                    : '$mins:${secs.toString().padLeft(2, '0')} ${s('minutes')}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.1),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        );
      },
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
