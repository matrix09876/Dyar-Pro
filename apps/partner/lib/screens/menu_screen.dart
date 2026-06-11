import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'shell.dart';

/// إدارة القائمة: تبديل توفر الصنف + تغيير السعر السريع —
/// أوضاع "إخفاء المنتج/تغيير السعر" من التطبيق الحالي بصياغة أبسط.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final store = ref.watch(myStoreProvider).value;
    if (store == null) {
      return EmptyState(message: s('noData'), icon: LucideIcons.store);
    }

    return StreamBuilder<List<MenuItem>>(
      stream: ref.read(storeServiceProvider).watchMenu(store.id),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return EmptyState(message: s('noData'), icon: LucideIcons.utensils);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _MenuItemCard(storeId: store.id, item: items[i]),
        );
      },
    );
  }
}

class _MenuItemCard extends ConsumerWidget {
  const _MenuItemCard({required this.storeId, required this.item});
  final String storeId;
  final MenuItem item;

  Future<void> _editPrice(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final ctrl = TextEditingController(
        text: (item.price / 100).toStringAsFixed(2));
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('changePrice')),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(suffixText: '₪'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s('reject'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(s('continue'))),
        ],
      ),
    );
    if (v == null) return;
    final shekels = double.tryParse(v);
    if (shekels != null && shekels >= 0) {
      await ref
          .read(storeServiceProvider)
          .setItemPrice(storeId, item.id, (shekels * 100).round());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DyarCard(
      child: Row(
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(item.imageUrl!,
                  width: 56, height: 56, fit: BoxFit.cover),
            )
          else
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: DyarTokens.brandLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.utensils,
                  color: DyarTokens.brandDark),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => _editPrice(context, ref),
                  child: MoneyText(item.price,
                      style: const TextStyle(
                          color: DyarTokens.brand,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Switch(
            value: item.available,
            activeThumbColor: DyarTokens.success,
            onChanged: (v) => ref
                .read(storeServiceProvider)
                .setItemAvailable(storeId, item.id, v),
          ),
        ],
      ),
    );
  }
}
