import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// رصيد المتجر: الحركات المالية للمالك (عمولات/تسويات) + صافي الرصيد.
class BalanceScreen extends ConsumerWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(s('wallet'))),
      body: uid == null
          ? EmptyState(message: s('signIn'), icon: LucideIcons.wallet)
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('uid', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                final net = docs.fold<int>(
                    0, (sum, d) => sum + ((d.data()['amount'] ?? 0) as int));

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // بطاقة الصافي
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFFFF8A3D), DyarTokens.brandDark,
                        ]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s('total'),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(MoneyText.format(net),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (docs.isEmpty)
                      EmptyState(
                          message: s('noData'), icon: LucideIcons.receipt)
                    else
                      ...docs.map((d) {
                        final x = d.data();
                        final amount = (x['amount'] ?? 0) as int;
                        final neg = amount < 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DyarCard(
                            child: Row(children: [
                              Icon(
                                neg
                                    ? LucideIcons.trendingUp
                                    : LucideIcons.banknote,
                                color: neg
                                    ? DyarTokens.danger
                                    : DyarTokens.success,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(x['type'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700))),
                              MoneyText(amount,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: neg
                                          ? DyarTokens.danger
                                          : DyarTokens.success)),
                            ]),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
    );
  }
}
