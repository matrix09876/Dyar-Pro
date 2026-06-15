import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// عروض المتجر: قائمة + إنشاء (عنوان ونسبة خصم وانتهاء) — promotions
/// مفلترة بمعرّف المتجر، وتظهر للزبائن وللإدارة.
class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key, required this.storeId});
  final String storeId;

  Future<void> _add(BuildContext context, S s) async {
    final title = TextEditingController();
    final pct = TextEditingController(text: '10');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('addPromotion')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              decoration: InputDecoration(labelText: s('name'))),
          const SizedBox(height: 8),
          TextField(
              controller: pct,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: '%', suffixText: '%')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s('save'))),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('promotions').add({
        'title': title.text.trim(),
        'discountPct': int.tryParse(pct.text) ?? 10,
        'storeId': storeId,
        'active': true,
        'sortOrder': 0,
        'createdAt': Timestamp.now(),
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s('offers'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DyarTokens.brand,
        onPressed: () => _add(context, s),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(s('addPromotion'),
            style: const TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('promotions')
            .where('storeId', isEqualTo: storeId)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return EmptyState(message: s('noData'), icon: LucideIcons.gift);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i];
              final p = d.data();
              final active = p['active'] == true;
              return DyarCard(
                child: Row(children: [
                  Container(
                    height: 44, width: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFF8A3D), DyarTokens.brandDark,
                      ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('${p['discountPct'] ?? 0}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(p['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800))),
                  Switch(
                    value: active,
                    activeThumbColor: DyarTokens.success,
                    onChanged: (v) => d.reference.update({'active': v}),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2,
                        color: DyarTokens.danger, size: 20),
                    onPressed: () => d.reference.delete(),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
