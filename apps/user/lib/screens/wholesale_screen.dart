import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'home_screen.dart' show approvedStoresProvider;
import 'store_screen.dart';

/// فئة تجار الجملة B2B — تظهر فقط لحسابات التجار (users.merchant من
/// اللوحة). متاجر type=='wholesale' بأسعار جملة وحد أدنى للكميات.
class WholesaleScreen extends ConsumerWidget {
  const WholesaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final storesAsync = ref.watch(approvedStoresProvider('wholesale'));
    final stores = storesAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 42, width: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🏪 ${s('wholesale')}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(s('wholesaleSub'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ]),
          ),
        ),
        if (storesAsync.isLoading)
          const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()))
        else if (stores.isEmpty)
          SliverFillRemaining(
              child: EmptyState(
                  message: s('noData'), icon: LucideIcons.store))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            sliver: SliverList.separated(
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final st = stores[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => StoreScreen(storeId: st.id))),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(children: [
                      SizedBox(
                        height: 84, width: 84,
                        child: st.coverUrl == null
                            ? Container(
                                color: const Color(0xFFE2E8F0),
                                child: const Center(
                                    child: Text('🏪',
                                        style: TextStyle(fontSize: 30))))
                            : CachedNetworkImage(
                                imageUrl: st.coverUrl!, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(st.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.5)),
                            if (st.description != null) ...[
                              const SizedBox(height: 2),
                              Text(st.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: DyarTokens.inkMuted,
                                      fontSize: 12)),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text('B2B · أسعار جملة',
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1D4ED8))),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.chevron_left_rounded,
                            color: DyarTokens.inkMuted),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }
}
