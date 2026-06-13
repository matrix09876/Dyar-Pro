import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../state/cart.dart';
import 'booking_sheet.dart';
import 'checkout_screen.dart';
import 'item_sheet.dart';

/// صفحة المتجر بمعيار Ultra UI: غلاف كبير بتدرّج + بطاقة معلومات عائمة
/// (تقييم/وقت/توصيل) + أصناف بصور وعدّادات + شريط سلة لاصق متدرّج.
///
/// هوية المينيو (MenuBrand): `stores/{id}.brand` يصبغ الترويسة والبطاقات
/// وشريط السلة وفق قالب المتجر — بلا brand تبقى هوية ديار كما هي.
/// أقسام المينيو: الأصناف مجمّعة حسب categoryId مع شريط chips لاصق
/// يقفز للقسم (الأصناف بلا categoryId تحت "الأشهر").
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key, required this.storeId});
  final String storeId;

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  static const _popular = 'الأشهر';

  final _scroll = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  String? _active;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// تجميع الأصناف حسب categoryId بترتيب أول ظهور — "الأشهر" أولًا.
  Map<String, List<MenuItem>> _group(List<MenuItem> items) {
    final map = <String, List<MenuItem>>{};
    for (final it in items) {
      final k = (it.categoryId == null || it.categoryId!.isEmpty)
          ? _popular
          : it.categoryId!;
      (map[k] ??= []).add(it);
    }
    if (map.length > 1 && map.containsKey(_popular)) {
      final p = map.remove(_popular)!;
      return {_popular: p, ...map};
    }
    return map;
  }

  /// قفزة سلسة لقسم — تعويض ارتفاع شريط الـ chips اللاصق.
  void _jumpTo(String section) {
    setState(() => _active = section);
    final ctx = _sectionKeys[section]?.currentContext;
    final render = ctx?.findRenderObject();
    if (render == null) return;
    final viewport = RenderAbstractViewport.of(render);
    final target = viewport.getOffsetToReveal(render, 0).offset -
        _SectionChipsDelegate.barHeight -
        6;
    _scroll.animateTo(
      target.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final cart = ref.watch(cartProvider);
    final storeId = widget.storeId;
    final storeStream = ref.read(storeServiceProvider).watchStore(storeId);
    final menuStream = ref.read(storeServiceProvider).watchMenu(storeId);

    return StreamBuilder<Store?>(
      stream: storeStream,
      builder: (context, storeSnap) {
        final store = storeSnap.data;
        final brand = MenuBrand.of(store?.brand);
        // أسعار الجملة مخفية لغير التجار (B2B): يُعرض قفل + طلب عرض سعر
        final wholesaleLocked = store?.type == 'wholesale' &&
            ref.watch(appUserProvider).value?.merchant != true;
        return Scaffold(
          backgroundColor: brand.pageBackground,
          body: StreamBuilder<List<MenuItem>>(
            stream: menuStream,
            builder: (context, menuSnap) {
              final items = menuSnap.data ?? const <MenuItem>[];
              final sections = _group(items);
              for (final name in sections.keys) {
                _sectionKeys.putIfAbsent(name, GlobalKey.new);
              }
              final showSections = sections.length > 1;
              final active = sections.containsKey(_active)
                  ? _active
                  : (sections.isEmpty ? null : sections.keys.first);

              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(child: _Header(store: store, brand: brand)),
                  const SliverToBoxAdapter(child: SizedBox(height: 76)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text('${s('menu')} 🍽️',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  // شريط أقسام لاصق — يظهر فقط عند وجود أكثر من قسم
                  if (showSections)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SectionChipsDelegate(
                        sections: sections.keys.toList(),
                        active: active,
                        brand: brand,
                        onTap: _jumpTo,
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
                    sliver: items.isEmpty
                        ? SliverToBoxAdapter(
                            child: EmptyState(
                                message: s('noData'),
                                icon: LucideIcons.utensils))
                        : SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final e in sections.entries) ...[
                                  if (showSections)
                                    Padding(
                                      key: _sectionKeys[e.key],
                                      padding: const EdgeInsets.fromLTRB(
                                          4, 14, 4, 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(e.key,
                                              style: const TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight:
                                                      FontWeight.w900)),
                                          const SizedBox(height: 6),
                                          brand.sectionDivider(),
                                        ],
                                      ),
                                    ),
                                  for (final it in e.value)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _MenuTile(
                                          storeId: storeId,
                                          item: it,
                                          brand: brand,
                                          wholesaleLocked: wholesaleLocked),
                                    ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
          bottomSheet: cart.isEmpty || cart.storeId != storeId
              ? null
              : _CartBar(brand: brand),
        );
      },
    );
  }
}

/// الغلاف + التدرج + زر الرجوع + بطاقة المعلومات العائمة.
class _Header extends ConsumerWidget {
  const _Header({required this.store, required this.brand});
  final Store? store;
  final MenuBrand brand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 240, width: double.infinity,
          child: store?.coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: store!.coverUrl!, fit: BoxFit.cover,
                  memCacheWidth: 1080) // غلاف بعرض الشاشة
              : Container(color: brand.accentSoft),
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
                            fontSize: 20, fontWeight: FontWeight.w900)),
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
                              fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ]),
                  ),
                ]),
                if (store?.description != null) ...[
                  const SizedBox(height: 4),
                  Text(store!.description!,
                      style: const TextStyle(
                          color: DyarTokens.inkMuted, fontSize: 12.5)),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  _InfoChip(
                      icon: LucideIcons.clock,
                      color: brand.accentDark,
                      label: '${store?.prepTimeMins ?? 25} دقيقة'),
                  const SizedBox(width: 8),
                  _InfoChip(
                      icon: LucideIcons.bike,
                      color: brand.accentDark,
                      label: MoneyText.format(store?.deliveryFee ?? 0)),
                ]),
                // حجز طاولة (مطعم) / موعد (خدمة: حلاق/طبيب..)
                if (store != null &&
                    (store!.type == 'restaurant' ||
                        store!.type == 'service')) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brand.accentDark,
                        side: BorderSide(color: brand.accent, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(LucideIcons.calendarDays, size: 18),
                      label: Text(
                          store!.type == 'restaurant'
                              ? s('bookTable')
                              : s('bookAppointment'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: () =>
                          showBookingSheet(context, ref, store!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// شريط chips الأقسام اللاصق — يقفز للقسم بالنقر (فجوة TALABI الكبرى).
class _SectionChipsDelegate extends SliverPersistentHeaderDelegate {
  _SectionChipsDelegate({
    required this.sections,
    required this.active,
    required this.brand,
    required this.onTap,
  });

  static const barHeight = 54.0;

  final List<String> sections;
  final String? active;
  final MenuBrand brand;
  final ValueChanged<String> onTap;

  @override
  double get minExtent => barHeight;
  @override
  double get maxExtent => barHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: brand.pageBackground,
      alignment: AlignmentDirectional.centerStart,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final name = sections[i];
          final selected = name == active;
          return GestureDetector(
            onTap: () => onTap(name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? brand.accent : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: selected
                    ? null
                    : Border.all(color: const Color(0x14000000)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: brand.accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ]
                    : null,
              ),
              child: Text(name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : DyarTokens.ink)),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_SectionChipsDelegate old) =>
      old.active != active ||
      old.brand != brand ||
      old.sections.length != sections.length;
}

/// شريط السلة اللاصق — يتدرج بلون هوية المتجر.
class _CartBar extends ConsumerWidget {
  const _CartBar({required this.brand});
  final MenuBrand brand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cart = ref.watch(cartProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6)),
        ],
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CheckoutScreen())),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: brand.headerGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: brand.accent.withValues(alpha: 0.45),
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
                      color: Colors.white, fontWeight: FontWeight.w900)),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _MenuTile extends ConsumerWidget {
  const _MenuTile(
      {required this.storeId,
      required this.item,
      required this.brand,
      this.wholesaleLocked = false});
  final String storeId;
  final MenuItem item;
  final MenuBrand brand;
  final bool wholesaleLocked; // سعر جملة مخفي لغير التجار

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
            color: brand.cardColor,
            borderRadius: brand.cardBorderRadius,
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

    // السعر: شارة ملوّنة وفق القالب، أو نص عادي في الهوية الافتراضية.
    // في متاجر الجملة لغير التجار يُخفى السعر (قفل) — اطلب عرض سعر.
    final price = wholesaleLocked
        ? const Icon(LucideIcons.lock, size: 16, color: DyarTokens.inkMuted)
        : Text(MoneyText.format(item.price),
            textDirection: TextDirection.ltr,
            style: TextStyle(
                color: brand.priceColor,
                fontWeight: FontWeight.w900,
                fontSize: brand.priceBadgeBg == null ? 15 : 13.5));

    return GestureDetector(
      // فتح نافذة الصنف بخياراته (نمط Wolt) — النقر على البطاقة كاملة.
      // في الجملة لغير التاجر: لا سلة مباشرة — وجّهه لطلب عرض سعر.
      onTap: () => wholesaleLocked
          ? ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s('b2bMerchantOnly'))))
          : showItemSheet(context, ref, storeId, item, brand: brand),
      child: Container(
        decoration: BoxDecoration(
          color: brand.cardColor,
          borderRadius: brand.cardBorderRadius,
          boxShadow: brand.cardShadow,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 78, width: 78,
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: brand.accentSoft,
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
                brand.priceBadgeBg == null
                    ? price
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: brand.priceBadgeBg,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: price,
                      ),
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
                      gradient: brand.headerGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: brand.accent.withValues(alpha: 0.4),
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
                    color: brand.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          ref.read(cartProvider.notifier).removeOne(item.id),
                      icon: Icon(LucideIcons.minus,
                          size: 18, color: brand.accentDark),
                    ),
                    Text('$qty',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          ref.read(cartProvider.notifier).add(storeId, item),
                      icon: Icon(LucideIcons.plus,
                          size: 18, color: brand.accentDark),
                    ),
                  ]),
                ),
        ]),
      ),
    );
  }
}
