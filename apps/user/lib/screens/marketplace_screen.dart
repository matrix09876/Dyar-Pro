import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// المنتجات المعتمدة (عامة للتصفّح)
final marketApprovedProvider = StreamProvider<List<MarketProduct>>(
    (ref) => ref.watch(marketServiceProvider).watchApproved());

/// منتجاتي أنا (كل الحالات)
final myMarketProductsProvider = StreamProvider<List<MarketProduct>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(const <MarketProduct>[]);
  return ref.watch(marketServiceProvider).watchMine(uid);
});

const _marketCategories = ['electronics', 'fashion', 'home', 'cars', 'other'];

String _catLabel(S s, String category) => s(switch (category) {
      'electronics' => 'catElectronics',
      'fashion' => 'catFashion',
      'home' => 'catHome',
      'cars' => 'catCars',
      _ => 'catOther',
    });

/// سوق C2C (بيع وشراء): تصفّح المنتجات المعتمدة + إدارة منتجاتي
/// (رفع منتج → موافقة الإدارة → بيع بعمولة تُحتسب على الخادم).
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: Text('🛍️ ${s('marketplace')}'),
          bottom: TabBar(tabs: [
            Tab(text: s('browse')),
            Tab(text: s('myProducts')),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: DyarTokens.brand,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(s('addProduct')),
          onPressed: () => _openAddSheet(context),
        ),
        body: TabBarView(children: [
          _BrowseTab(
              query: _query,
              onQuery: (v) => setState(() => _query = v)),
          const _MyProductsTab(),
        ]),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final s = ref.read(stringsProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s('signIn'))));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _AddProductSheet(sellerUid: uid),
    );
  }
}

// ===== تبويب التصفّح: شبكة بطاقات المنتجات المعتمدة + بحث بالاسم =====
class _BrowseTab extends ConsumerWidget {
  const _BrowseTab({required this.query, required this.onQuery});
  final String query;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final productsAsync = ref.watch(marketApprovedProvider);
    final all = productsAsync.value ?? const <MarketProduct>[];
    final q = query.trim().toLowerCase();
    final products = q.isEmpty
        ? all
        : all.where((p) => p.title.toLowerCase().contains(q)).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          onChanged: onQuery,
          decoration: InputDecoration(
            hintText: s('searchProducts'),
            prefixIcon: const Icon(LucideIcons.search,
                size: 20, color: DyarTokens.inkMuted),
          ),
        ),
      ),
      Expanded(
        child: productsAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? EmptyState(
                    message: s('noData'), icon: LucideIcons.shoppingBag)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) =>
                        _ProductCard(product: products[i]),
                  ),
      ),
    ]);
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final MarketProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _ProductImage(url: product.imageUrl)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                MoneyText(product.price,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: DyarTokens.brand,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(LucideIcons.mapPin,
                      size: 12, color: DyarTokens.inkMuted),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                        product.city.isEmpty ? '—' : product.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: DyarTokens.inkMuted, fontSize: 11)),
                  ),
                  Text(_catLabel(s, product.category),
                      style: const TextStyle(
                          color: DyarTokens.inkMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: DyarTokens.brandLight,
        alignment: Alignment.center,
        child: const Text('🛍️', style: TextStyle(fontSize: 40)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        color: DyarTokens.brandLight,
        alignment: Alignment.center,
        child: const Text('🛍️', style: TextStyle(fontSize: 40)),
      ),
    );
  }
}

// ===== تبويب منتجاتي: الحالة + تم البيع / حذف =====
class _MyProductsTab extends ConsumerWidget {
  const _MyProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final mineAsync = ref.watch(myMarketProductsProvider);
    final mine = mineAsync.value ?? const <MarketProduct>[];

    if (mineAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (mine.isEmpty) {
      return EmptyState(message: s('noData'), icon: LucideIcons.shoppingBag);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      itemCount: mine.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _MyProductTile(product: mine[i]),
    );
  }
}

class _MyProductTile extends ConsumerStatefulWidget {
  const _MyProductTile({required this.product});
  final MarketProduct product;

  @override
  ConsumerState<_MyProductTile> createState() => _MyProductTileState();
}

class _MyProductTileState extends ConsumerState<_MyProductTile> {
  bool _busy = false;

  Future<void> _markSold() async {
    final s = ref.read(stringsProvider);
    setState(() => _busy = true);
    try {
      await ref.read(marketServiceProvider).markSold(widget.product.id);
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
    final p = widget.product;
    return DyarCard(
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
              height: 64, width: 64, child: _ProductImage(url: p.imageUrl)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 4),
              Row(children: [
                MoneyText(p.price,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: DyarTokens.brand,
                        fontSize: 13)),
                const SizedBox(width: 8),
                StatusChip(label: s(p.status), statusKey: p.status),
              ]),
            ],
          ),
        ),
        if (_busy)
          const SizedBox(
              height: 20, width: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
        else ...[
          if (p.status == 'approved')
            IconButton(
              tooltip: s('markSold'),
              icon: const Icon(LucideIcons.badgeCheck,
                  color: DyarTokens.success),
              onPressed: _markSold,
            ),
          if (p.status != 'sold')
            IconButton(
              tooltip: s('delete'),
              icon: const Icon(LucideIcons.trash2,
                  color: Color(0xFFE11D48), size: 20),
              onPressed: () =>
                  ref.read(marketServiceProvider).delete(p.id),
            ),
        ],
      ]),
    );
  }
}

// ===== نموذج إضافة منتج (→ pending بانتظار موافقة الإدارة) =====
class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet({required this.sellerUid});
  final String sellerUid;

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _imageUrl = TextEditingController();
  String _category = 'other';
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _city.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = ref.read(stringsProvider);
    final priceShekel = double.tryParse(_price.text.trim());
    if (_title.text.trim().isEmpty || priceShekel == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(marketServiceProvider).create(
            sellerUid: widget.sellerUid,
            title: _title.text.trim(),
            description: _description.text.trim(),
            price: (priceShekel * 100).round(), // أغورة
            imageUrl: _imageUrl.text.trim(),
            category: _category,
            city: _city.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s('productPending'))));
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

    Widget field(String label, TextEditingController c,
            {TextInputType? type, int lines = 1, TextDirection? dir}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: c,
            keyboardType: type,
            maxLines: lines,
            textDirection: dir,
            decoration: InputDecoration(labelText: label),
          ),
        );

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🛍️ ${s('addProduct')}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 16),
            field(s('productTitle'), _title),
            field(s('description'), _description, lines: 3),
            field(s('priceShekel'), _price,
                type: const TextInputType.numberWithOptions(decimal: true)),
            field(s('city'), _city),
            field(s('imageUrl'), _imageUrl,
                type: TextInputType.url, dir: TextDirection.ltr),
            Text(s('category'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _marketCategories)
                  ChoiceChip(
                    label: Text(_catLabel(s, c)),
                    selected: _category == c,
                    selectedColor: DyarTokens.brandLight,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            CtaButton(
              label: s('addProduct'),
              icon: LucideIcons.plus,
              loading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
