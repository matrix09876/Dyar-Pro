import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../state/cart.dart';
import 'booking_sheet.dart';
import 'checkout_screen.dart';
import 'item_sheet.dart';

/// صفحة المتجر بمعيار Ultra UI: غلاف كبير بتدرّج + بطاقة معلومات عائمة
/// (تقييم/وقت/توصيل) + أصناف بصور وعدّادات + شريط سلة لاصق متدرّج.
class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key, required this.storeId});
  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cart = ref.watch(cartProvider);
    final storeStream = ref.read(storeServiceProvider).watchStore(storeId);
    final menuStream = ref.read(storeServiceProvider).watchMenu(storeId);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: StreamBuilder<Store?>(
        stream: storeStream,
        builder: (context, storeSnap) {
          final store = storeSnap.data;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 240, width: double.infinity,
                      child: store?.coverUrl != null
                          ? CachedNetworkImage(imageUrl: store!.coverUrl!, fit: BoxFit.cover)
                          : Container(color: DyarTokens.brandLight),
                    ),
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 48, start: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 42, width: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10),
                            ],
                          ),
                          child: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 20, end: 20, bottom: -56,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 24,
                                offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(store?.name ?? '…',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(children: [
                                  const Icon(LucideIcons.star,
                                      size: 15, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 4),
                                  Text(
                                      '${store?.rating ?? '-'} (${store?.ratingCount ?? 0})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5)),
                                ]),
                              ),
                            ]),
                            if (store?.description != null) ...[
                              const SizedBox(height: 4),
                              Text(store!.description!,
                                  style: const TextStyle(
                                      color: DyarTokens.inkMuted,
                                      fontSize: 12.5)),
                            ],
                            const SizedBox(height: 12),
                            Row(children: [
                              _InfoChip(
                                  icon: LucideIcons.clock,
                                  label: '${store?.prepTimeMins ?? 25} دقيقة'),
                              const SizedBox(width: 8),
                              _InfoChip(
                                  icon: LucideIcons.bike,
                                  label: MoneyText.format(
                                      store?.deliveryFee ?? 0)),
                            ]),
                            // حجز طاولة (مطعم) / موعد (خدمة: حلاق/طبيب..)
                            if (store != null &&
                                (store.type == 'restaurant' ||
                                    store.type == 'service')) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: DyarTokens.brandDark,
                                    side: const BorderSide(
                                        color: DyarTokens.brand, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(LucideIcons.calendarDays,
                                      size: 18),
                                  label: Text(
                                      store.type == 'restaurant'
                                          ? s('bookTable')
                                          : s('bookAppointment'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  onPressed: () =>
                                      showBookingSheet(context, ref, store),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 76)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text('${s('menu')} 🍽️',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                sliver: StreamBuilder<List<MenuItem>>(
                  stream: menuStream,
                  builder: (context, menuSnap) {
                    final items = (menuSnap.data ?? [])
                        .toList();
                    if (items.isEmpty) {
                      return SliverToBoxAdapter(
                          child: EmptyState(
                              message: s('noData'),
                              icon: LucideIcons.utensils));
                    }
                    return SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _MenuTile(storeId: storeId, item: items[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: cart.isEmpty || cart.storeId != storeId
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, -6)),
                ],
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CheckoutScreen())),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFF8A3D),
                      DyarTokens.brandDark,
                    ]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: DyarTokens.brand.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(children: [
                    Container(
                      height: 30, width: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('${cart.count}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 10),
                    Text(s('checkout'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text(MoneyText.format(cart.subtotal),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: DyarTokens.brandDark),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _MenuTile extends ConsumerWidget {
  const _MenuTile({required this.storeId, required this.item});
  final String storeId;
  final MenuItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cart = ref.watch(cartProvider);
    final qty = cart.storeId == storeId ? cart.qtyOf(item.id) : 0;

    // الصنف غير المتوفر يبقى ظاهرًا بشارة (اكتمال المينيو — درس TALABI)
    if (!item.available) {
      return Opacity(
        opacity: 0.55,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: Text(item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14.5)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(s('unavailable'),
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: DyarTokens.inkMuted)),
            ),
          ]),
        ),
      );
    }

    return GestureDetector(
      // فتح نافذة الصنف بخياراته (نمط Wolt) — النقر على البطاقة كاملة
      onTap: () => showItemSheet(context, ref, storeId, item),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 78, width: 78,
            child: item.imageUrl != null
                ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                : Container(
                    color: DyarTokens.brandLight,
                    child: const Center(
                        child: Text('🍜', style: TextStyle(fontSize: 30))),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14.5)),
              if (item.description != null) ...[
                const SizedBox(height: 3),
                Text(item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: DyarTokens.inkMuted)),
              ],
              const SizedBox(height: 6),
              Text(MoneyText.format(item.price),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      color: DyarTokens.brandDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        qty == 0
            ? GestureDetector(
                onTap: () =>
                    ref.read(cartProvider.notifier).add(storeId, item),
                child: Container(
                  height: 42, width: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFF8A3D),
                      DyarTokens.brandDark,
                    ]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: DyarTokens.brand.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(LucideIcons.plus,
                      color: Colors.white, size: 22),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: DyarTokens.brandLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        ref.read(cartProvider.notifier).removeOne(item.id),
                    icon: const Icon(LucideIcons.minus,
                        size: 18, color: DyarTokens.brandDark),
                  ),
                  Text('$qty',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        ref.read(cartProvider.notifier).add(storeId, item),
                    icon: const Icon(LucideIcons.plus,
                        size: 18, color: DyarTokens.brandDark),
                  ),
                ]),
              ),
      ]),
      ),
    );
  }
}
