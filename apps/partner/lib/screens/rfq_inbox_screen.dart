import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// صندوق طلبات عرض السعر الواردة (RFQ) للمورد: يرى طلبات التجار ويردّ
/// بسعر الوحدة. العمولة تُحسب وتُحفظ خادميًا (حماية العمولة).
class RfqInboxScreen extends ConsumerWidget {
  const RfqInboxScreen({super.key, required this.storeId});
  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s('rfqInbox'))),
      body: StreamBuilder<List<Rfq>>(
        stream: ref.read(b2bServiceProvider).watchForStore(storeId),
        builder: (context, snap) {
          final rfqs = snap.data ?? const <Rfq>[];
          if (rfqs.isEmpty) {
            return EmptyState(
                message: s('noData'), icon: LucideIcons.fileText);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rfqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _InboxCard(rfq: rfqs[i]),
          );
        },
      ),
    );
  }
}

class _InboxCard extends ConsumerWidget {
  const _InboxCard({required this.rfq});
  final Rfq rfq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return DyarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${rfq.productName} ×${rfq.qty}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          if (rfq.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(rfq.note,
                style: const TextStyle(color: DyarTokens.inkMuted, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          if (rfq.isOpen)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _quoteDialog(context, ref),
                icon: const Icon(LucideIcons.tag, size: 16),
                label: Text(s('sendQuote')),
              ),
            )
          else if (rfq.isQuoted && rfq.quote != null)
            Row(children: [
              Expanded(
                  child: Text(s('statusQuoted'),
                      style: const TextStyle(
                          color: DyarTokens.brand, fontWeight: FontWeight.w700))),
              Text(MoneyText.format(rfq.quote!.total),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
        ],
      ),
    );
  }

  Future<void> _quoteDialog(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final price = TextEditingController(); // شيكل/وحدة
    final terms = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${s('sendQuote')} · ${rfq.productName} ×${rfq.qty}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: price,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: '${s('unitPrice')} ₪')),
          const SizedBox(height: 8),
          TextField(controller: terms,
              decoration: InputDecoration(labelText: s('rfqNote'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(s('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(s('send'))),
        ],
      ),
    );
    final shekels = double.tryParse(price.text.trim()) ?? 0;
    if (ok == true && shekels > 0) {
      try {
        await ref.read(b2bServiceProvider).quoteRfq(
              rfqId: rfq.id,
              unitPrice: (shekels * 100).round(),
              terms: terms.text.trim(),
            );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(s('error'))));
        }
      }
    }
    price.dispose();
    terms.dispose();
  }
}
