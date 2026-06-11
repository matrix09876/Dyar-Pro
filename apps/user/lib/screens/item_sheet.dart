import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../state/cart.dart';

/// نافذة الصنف (نمط Wolt/Talabat): صورة كبيرة + وصف + مجموعات الخيارات
/// من stores/{id}/options + عدّاد كمية + زر "أضف — ₪المجموع" الحي.
/// [brand] (هوية المينيو) تصبغ زر الإضافة والخيارات بلون قالب المتجر.
Future<void> showItemSheet(
    BuildContext context, WidgetRef ref, String storeId, MenuItem item,
    {MenuBrand? brand}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ItemSheet(
        storeId: storeId, item: item, brand: brand ?? MenuBrand.dyar),
  );
}

class _ItemSheet extends ConsumerStatefulWidget {
  const _ItemSheet(
      {required this.storeId, required this.item, required this.brand});
  final String storeId;
  final MenuItem item;
  final MenuBrand brand;

  @override
  ConsumerState<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends ConsumerState<_ItemSheet> {
  int _qty = 1;
  final Set<String> _picked = {}; // أسماء الخيارات المختارة
  List<Map<String, dynamic>> _choices = []; // كل الخيارات المتاحة
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final snap = await FirebaseFirestore.instance
        .collection('stores/${widget.storeId}/options')
        .where('active', isEqualTo: true)
        .get();
    final all = <Map<String, dynamic>>[];
    for (final g in snap.docs) {
      for (final c in List<Map<String, dynamic>>.from(
          g.data()['choices'] ?? const [])) {
        if (c['active'] != false) {
          all.add({'name': c['name'], 'price': (c['price'] ?? 0) as int});
        }
      }
    }
    if (mounted) setState(() { _choices = all; _loading = false; });
  }

  int get _optionsTotal => _choices
      .where((c) => _picked.contains(c['name']))
      .fold(0, (s, c) => s + (c['price'] as int));

  int get _total => (widget.item.price + _optionsTotal) * _qty;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final item = widget.item;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة + إغلاق
            Stack(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: SizedBox(
                  height: 190, width: double.infinity,
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: widget.brand.accentSoft,
                          child: const Center(
                              child:
                                  Text('🍜', style: TextStyle(fontSize: 48))),
                        ),
                ),
              ),
              PositionedDirectional(
                top: 12, end: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 36, width: 36,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w900)),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(item.description!,
                        style: const TextStyle(
                            color: DyarTokens.inkMuted, fontSize: 13)),
                  ],
                ],
              ),
            ),

            // الخيارات
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          Center(child: CircularProgressIndicator()))
                  : _choices.isEmpty
                      ? const SizedBox(height: 12)
                      : ListView(
                          shrinkWrap: true,
                          padding:
                              const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          children: [
                            Text(s('extras'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            for (final c in _choices)
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: widget.brand.accent,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: _picked.contains(c['name']),
                                onChanged: (v) => setState(() => v == true
                                    ? _picked.add(c['name'])
                                    : _picked.remove(c['name'])),
                                title: Text(c['name'],
                                    style: const TextStyle(fontSize: 14)),
                                secondary: Text(
                                    '+${MoneyText.format(c['price'])}',
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5)),
                              ),
                          ],
                        ),
            ),

            // الكمية + زر الإضافة الحي
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    IconButton(
                        onPressed: _qty > 1
                            ? () => setState(() => _qty--)
                            : null,
                        icon: const Icon(LucideIcons.minus, size: 18)),
                    Text('$_qty',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    IconButton(
                        onPressed: () => setState(() => _qty++),
                        icon: const Icon(LucideIcons.plus, size: 18)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: FilledButton(
                      style: widget.brand.template == 'dyar'
                          ? null
                          : FilledButton.styleFrom(
                              backgroundColor: widget.brand.accentDark),
                      onPressed: () {
                        final opts = _choices
                            .where((c) => _picked.contains(c['name']))
                            .toList();
                        ref.read(cartProvider.notifier).add(
                            widget.storeId, item,
                            options: opts, qty: _qty);
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s('addToCart')),
                          Text(MoneyText.format(_total),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
