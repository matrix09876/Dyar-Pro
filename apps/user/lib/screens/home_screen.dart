import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'store_screen.dart';
import 'taxi_screen.dart';
import 'parcel_screen.dart';

final approvedStoresProvider = StreamProvider.family<List<Store>, String?>(
    (ref, type) => ref.watch(storeServiceProvider).watchApproved(type: type));

/// الرئيسية بمعيار Dyar Ultra UI: ترويسة متدرجة + بحث عائم + بانرات عروض
/// + شبكة خدمات ملوّنة + بطاقات متاجر غنية بالصور والشارات.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _type;
  String _query = '';

  static const _grad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF8A3D), DyarTokens.brand, DyarTokens.brandDark],
  );

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final storesAsync = ref.watch(approvedStoresProvider(_type));
    final allStores = storesAsync.value ?? [];
    // بحث وظيفي: بالاسم أو الوصف (غير حسّاس لحالة الأحرف)
    final q = _query.trim().toLowerCase();
    final stores = q.isEmpty
        ? allStores
        : allStores
            .where((st) =>
                st.name.toLowerCase().contains(q) ||
                (st.description ?? '').toLowerCase().contains(q))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          // ===== الترويسة المتدرجة + البحث العائم =====
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: _grad,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(34)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('👋 ${s('appName')}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(LucideIcons.mapPin,
                                  color: Colors.white70, size: 15),
                              const SizedBox(width: 4),
                              Text(s('allYouNeed'),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ]),
                          ],
                        ),
                      ),
                      Container(
                        height: 44, width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            const Icon(LucideIcons.bell, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  start: 20, end: 20, bottom: -26,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 22,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    padding: const EdgeInsetsDirectional.only(start: 16),
                    child: Row(children: [
                      const Icon(LucideIcons.search, color: DyarTokens.brand),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: s('searchHint'),
                            hintStyle: const TextStyle(
                                color: DyarTokens.inkMuted, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _query = ''),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 46)),

          // ===== Stories — حلقات متدرجة (نمط HAAT) =====
          SliverToBoxAdapter(
            child: SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsetsDirectional.only(start: 20, end: 8),
                children: [
                  for (final st in stores.take(6))
                    _StoryRing(
                        name: st.name,
                        imageUrl: st.coverUrl,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    StoreScreen(storeId: st.id)))),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ===== بانرات العروض =====
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsetsDirectional.only(start: 20, end: 8),
                children: const [
                  _PromoBanner(
                    colors: [Color(0xFF16A34A), Color(0xFF065F46)],
                    emoji: '🚚',
                    title: 'توصيل مجاني',
                    subtitle: 'لطلبك الأول فوق ₪80',
                  ),
                  SizedBox(width: 12),
                  _PromoBanner(
                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                    emoji: '🎁',
                    title: 'DYAR10',
                    subtitle: 'خصم 10% بالكوبون',
                  ),
                  SizedBox(width: 12),
                  _PromoBanner(
                    colors: [Color(0xFF0284C7), Color(0xFF075985)],
                    emoji: '🚕',
                    title: 'تاكسي ديار',
                    subtitle: 'مشاويرك بسعر عادل',
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 22)),

          // ===== شبكة الخدمات الملوّنة =====
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsetsDirectional.only(start: 20, end: 8),
                children: [
                  _ServiceTile(null, s('home'), LucideIcons.layoutGrid,
                      const [Color(0xFFF4691E), Color(0xFFBA3A11)],
                      _type, _select),
                  _ServiceTile('restaurant', s('restaurants'),
                      LucideIcons.utensils,
                      const [Color(0xFFEF4444), Color(0xFF991B1B)],
                      _type, _select),
                  _ServiceTile('grocery', s('groceries'),
                      LucideIcons.shoppingBag,
                      const [Color(0xFF22C55E), Color(0xFF15803D)],
                      _type, _select),
                  _ServiceTile('pharmacy', s('pharmacies'), LucideIcons.pill,
                      const [Color(0xFF06B6D4), Color(0xFF0E7490)],
                      _type, _select),
                  _ServiceTile('flowers', s('flowers'), LucideIcons.flower2,
                      const [Color(0xFFEC4899), Color(0xFF9D174D)],
                      _type, _select),
                  _ServiceTile('service', s('services'), LucideIcons.wrench,
                      const [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
                      _type, _select),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),

          // ===== تاكسي + طرود =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                  child: _ActionCard(
                    emoji: '🚕',
                    label: s('taxi'),
                    sub: s('whereTo'),
                    colors: const [Color(0xFF111827), Color(0xFF374151)],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const TaxiScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    emoji: '📦',
                    label: s('parcel'),
                    sub: 'OTP · حماية ديار',
                    colors: const [Color(0xFFF59E0B), Color(0xFFB45309)],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ParcelScreen())),
                  ),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ===== عنوان قسم المتاجر =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('الأشهر بالقرب منك 🔥',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  Text('عرض الكل',
                      style: const TextStyle(
                          color: DyarTokens.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ===== بطاقات المتاجر =====
          if (storesAsync.isLoading)
            // Skeletons أثناء التحميل بدل المؤشر الدوّار
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList.separated(
                itemCount: 2,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, __) => const _StoreSkeleton(),
              ),
            )
          else if (stores.isEmpty)
            SliverToBoxAdapter(
                child:
                    EmptyState(message: s('noData'), icon: LucideIcons.store))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList.separated(
                itemCount: stores.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) => _StoreCard(store: stores[i]),
              ),
            ),
        ],
      ),
    );
  }

  void _select(String? t) => setState(() => _type = t);
}

class _StoryRing extends StatelessWidget {
  const _StoryRing({required this.name, this.imageUrl, required this.onTap});
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            height: 64, width: 64,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFC53D),
                  DyarTokens.brand,
                  Color(0xFFE91E63),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(
                child: imageUrl != null
                    ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: DyarTokens.brandLight,
                        child: const Center(child: Text('🍜'))),
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 66,
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.colors,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
  final List<Color> colors;
  final String emoji, title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 38)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile(this.type, this.label, this.icon, this.colors,
      this.selected, this.onTap);
  final String? type;
  final String label;
  final IconData icon;
  final List<Color> colors;
  final String? selected;
  final void Function(String?) onTap;

  @override
  Widget build(BuildContext context) {
    final isSel = selected == type;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: GestureDetector(
        onTap: () => onTap(type),
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 62, width: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors),
              borderRadius: BorderRadius.circular(20),
              border:
                  isSel ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: [
                BoxShadow(
                    color:
                        colors.first.withValues(alpha: isSel ? 0.55 : 0.30),
                    blurRadius: isSel ? 18 : 10,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 27),
          ),
          const SizedBox(height: 7),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w900 : FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.colors,
    required this.onTap,
  });
  final String emoji, label, sub;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: colors.first.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _StoreCard extends ConsumerWidget {
  const _StoreCard({required this.store});
  final Store store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return GestureDetector(
      onTap: store.isOpen
          ? () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StoreScreen(storeId: store.id)))
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              SizedBox(
                height: 150, width: double.infinity,
                child: store.coverUrl != null
                    ? CachedNetworkImage(imageUrl: store.coverUrl!, fit: BoxFit.cover)
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Color(0xFFFFD3B2),
                            Color(0xFFFFE6D5)
                          ]),
                        ),
                        child: const Center(
                            child:
                                Text('🍜', style: TextStyle(fontSize: 52))),
                      ),
              ),
              PositionedDirectional(
                top: 12, start: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(LucideIcons.star,
                        size: 15, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text('${store.rating}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 13)),
                    Text(' (${store.ratingCount})',
                        style: const TextStyle(
                            color: DyarTokens.inkMuted, fontSize: 11)),
                  ]),
                ),
              ),
              PositionedDirectional(
                top: 12, end: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: store.isOpen
                        ? const Color(0xFF16A34A)
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(store.isOpen ? s('open') : s('closed'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 17)),
                  if (store.description != null) ...[
                    const SizedBox(height: 2),
                    Text(store.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: DyarTokens.inkMuted, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    _Chip(
                        icon: LucideIcons.clock,
                        text: '${store.prepTimeMins}-'
                            '${store.prepTimeMins + 10} د'),
                    const SizedBox(width: 8),
                    _Chip(
                        icon: LucideIcons.bike,
                        text: MoneyText.format(store.deliveryFee)),
                    const Spacer(),
                    Container(
                      height: 34, width: 34,
                      decoration: BoxDecoration(
                        color: DyarTokens.brandLight,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.chevron_left,
                          color: DyarTokens.brandDark, size: 20),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: DyarTokens.inkMuted),
        const SizedBox(width: 5),
        Text(text,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _StoreSkeleton extends StatelessWidget {
  const _StoreSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double h, double w, [double r = 12]) => Container(
          height: h, width: w,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EAEE),
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          box(150, double.infinity, 0),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(16, 140),
                const SizedBox(height: 8),
                box(12, 220),
                const SizedBox(height: 12),
                Row(children: [
                  box(24, 70), const SizedBox(width: 8), box(24, 70),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
