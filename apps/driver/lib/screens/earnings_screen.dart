import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'home_screen.dart';

/// أرباح السائق: اليوم/الأسبوع/الإجمالي.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final driver = ref.watch(myDriverProvider).value;

    Widget tile(String label, int amount, IconData icon) => DyarCard(
          child: Row(
            children: [
              Container(
                height: 44, width: 44,
                decoration: BoxDecoration(
                  color: DyarTokens.brandLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: DyarTokens.brandDark),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              MoneyText(amount,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s('earnings'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          tile(s('earningsToday'), driver?.earningsToday ?? 0,
              LucideIcons.sunrise),
          const SizedBox(height: 10),
          tile('7 ${s('history')}', driver?.earningsWeek ?? 0,
              LucideIcons.calendarDays),
          const SizedBox(height: 10),
          tile(s('total'), driver?.earningsTotal ?? 0, LucideIcons.wallet),
        ],
      ),
    );
  }
}
