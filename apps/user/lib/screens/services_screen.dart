import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'booking_sheet.dart';
import 'home_screen.dart' show approvedStoresProvider;
import 'store_screen.dart';

/// شاشة "خدمات" — شبكة المهن (سباك/كهربائي/طبيب/محامي...) بأيقونات
/// emoji كبيرة وتدرجات مميزة. النقر يعرض مقدمي تلك المهنة
/// (stores type=service و serviceCategory==key) مع حجز موعد + اتصال.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  /// تدرجات مميزة لكل مهنة (بترتيب kServiceCategories)
  static const List<List<Color>> _grads = [
    [Color(0xFF0EA5E9), Color(0xFF0369A1)], // سباك
    [Color(0xFFF59E0B), Color(0xFFB45309)], // كهربائي
    [Color(0xFFEC4899), Color(0xFF9D174D)], // دهان
    [Color(0xFF64748B), Color(0xFF334155)], // ميكانيكي
    [Color(0xFFA16207), Color(0xFF713F12)], // نجار
    [Color(0xFF10B981), Color(0xFF047857)], // محاسب
    [Color(0xFF6366F1), Color(0xFF3730A3)], // محامي
    [Color(0xFFEF4444), Color(0xFF991B1B)], // طبيب
    [Color(0xFF06B6D4), Color(0xFF0E7490)], // طبيب أسنان
    [Color(0xFF8B5CF6), Color(0xFF5B21B6)], // حلاق
    [Color(0xFFD946EF), Color(0xFF86198F)], // صالون
    [Color(0xFF22C55E), Color(0xFF15803D)], // تنظيف
    [Color(0xFF111827), Color(0xFF374151)], // إلكترونيات
    [Color(0xFF38BDF8), Color(0xFF1D4ED8)], // تكييف
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(langProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFF8A3D),
                    DyarTokens.brand,
                    DyarTokens.brandDark
                  ],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
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
                      Text('🛠️ ${s('serviceProviders')}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(s('chooseProfession'),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: kServiceCategories.length,
                (context, i) {
                  final cat = kServiceCategories[i];
                  final colors = _grads[i % _grads.length];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProvidersScreen(category: cat))),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                              color: colors.first.withValues(alpha: 0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat.emoji,
                              style: const TextStyle(fontSize: 38)),
                          const SizedBox(height: 8),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(cat.label(lang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// مقدمو مهنة واحدة — بطاقات ببادج المهنة + "حجز موعد" + اتصال.
class ProvidersScreen extends ConsumerWidget {
  const ProvidersScreen({super.key, required this.category});
  final ServiceCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(langProvider);
    final storesAsync = ref.watch(approvedStoresProvider('service'));
    final providers = (storesAsync.value ?? [])
        .where((st) => st.serviceCategory == category.key)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('${category.emoji} ${category.label(lang)}',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900)),
      ),
      body: storesAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : providers.isEmpty
              ? EmptyState(message: s('noProviders'), icon: LucideIcons.wrench)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) =>
                      _ProviderCard(store: providers[i], category: category),
                ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  const _ProviderCard({required this.store, required this.category});
  final Store store;
  final ServiceCategory category;

  Future<void> _call(BuildContext context, String snackText) async {
    final phone = store.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(snackText)));
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(langProvider);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StoreScreen(storeId: store.id))),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.coverUrl != null)
              SizedBox(
                height: 120, width: double.infinity,
                child: CachedNetworkImage(
                    imageUrl: store.coverUrl!, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(store.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: DyarTokens.brandLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                          '${category.emoji} ${category.label(lang)}',
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: DyarTokens.brandDark)),
                    ),
                  ]),
                  if (store.description != null) ...[
                    const SizedBox(height: 3),
                    Text(store.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: DyarTokens.inkMuted, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(LucideIcons.star,
                        size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text('${store.rating} (${store.ratingCount})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 12)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    // حجز موعد — يفتح BookingSheet الموجود
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFFFF8A3D),
                              DyarTokens.brandDark,
                            ]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white),
                            icon: const Icon(LucideIcons.calendarDays,
                                size: 17),
                            label: Text(s('bookAppointment'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13)),
                            onPressed: () =>
                                showBookingSheet(context, ref, store),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // اتصال tel:
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF047857),
                          side: const BorderSide(
                              color: Color(0xFF10B981), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(LucideIcons.phone, size: 16),
                        label: Text(s('call'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                        onPressed: () => _call(context, s('noData')),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
