import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// السجل: كل ما سلّمه السائق (طلبات) مع أرباح كل توصيلة وتاريخها.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(driverServiceProvider).watchDeliveredOrders(uid),
        builder: (context, snap) {
          final orders = snap.data ?? const [];
          if (orders.isEmpty) {
            return EmptyState(
                message: s('noData'), icon: LucideIcons.packageCheck);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(s('history'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final o in orders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DyarCard(
                    child: Row(children: [
                      Container(
                        height: 42, width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.packageCheck,
                            color: Color(0xFF15803D), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#${o['code'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(
                              _date(o['createdAt']),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: DyarTokens.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      MoneyText(
                        ((o['pricing']?['deliveryFee'] ?? 0) as int) +
                            ((o['pricing']?['tip'] ?? 0) as int),
                        style: const TextStyle(
                            color: DyarTokens.success,
                            fontWeight: FontWeight.w900),
                      ),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _date(dynamic ts) {
    try {
      final d = (ts as dynamic).toDate() as DateTime;
      return '${d.day}/${d.month} · '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
