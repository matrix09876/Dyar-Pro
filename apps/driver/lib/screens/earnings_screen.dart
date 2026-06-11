import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'package:firebase_auth/firebase_auth.dart';

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
          const SizedBox(height: 14),

          // السحب الفوري (حتى 80% من الإجمالي) — ميزة تفوقنا على HAAT
          _InstantPayout(total: driver?.earningsTotal ?? 0),
          const SizedBox(height: 18),

          Text('💳 ${s('history')}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          _EarningsTx(),
        ],
      ),
    );
  }
}

class _InstantPayout extends ConsumerStatefulWidget {
  const _InstantPayout({required this.total});
  final int total;

  @override
  ConsumerState<_InstantPayout> createState() => _InstantPayoutState();
}

class _InstantPayoutState extends ConsumerState<_InstantPayout> {
  bool _busy = false;

  Future<void> _request() async {
    final s = ref.read(stringsProvider);
    final max = (widget.total * 0.8).floor();
    final ctrl =
        TextEditingController(text: (max / 100).toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('instantPayout')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
              labelText: s('amountAgorot'), suffixText: '₪'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s('confirm'))),
        ],
      ),
    );
    if (ok != true) return;
    final amount = ((double.tryParse(ctrl.text) ?? 0) * 100).round();
    if (amount <= 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(driverServiceProvider).requestPayout(amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s('payoutRequested'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s('error'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return CtaButton(
      label: s('instantPayout'),
      icon: LucideIcons.banknote,
      loading: _busy,
      onPressed: widget.total <= 0 ? null : _request,
    );
  }
}

class _EarningsTx extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.read(driverServiceProvider).watchEarningTx(uid),
      builder: (context, snap) {
        final txs = snap.data ?? const [];
        if (txs.isEmpty) {
          return EmptyState(message: s('noData'), icon: LucideIcons.receipt);
        }
        return Column(children: [
          for (final x in txs.take(20))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DyarCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(children: [
                  Text(
                      x['meta']?['parcelId'] != null
                          ? '📦'
                          : x['meta']?['rideId'] != null
                              ? '🚕'
                              : '🍔',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(x['type']?.toString() ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13))),
                  MoneyText((x['amount'] ?? 0) as int,
                      style: const TextStyle(
                          color: DyarTokens.success,
                          fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}
