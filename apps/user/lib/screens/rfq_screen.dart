import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// طلبات عرض السعر (RFQ) للتاجر: إنشاء طلب لمورد جملة، ومتابعة العروض
/// الواردة وقبولها/رفضها. الأسعار والعمولة محسوبة خادميًا.
class RfqScreen extends ConsumerWidget {
  const RfqScreen({super.key, this.storeId, this.storeName});
  final String? storeId;
  final String? storeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s('myRfqs'))),
        body: EmptyState(message: s('signIn'), icon: LucideIcons.fileText),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s('myRfqs'))),
      floatingActionButton: storeId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: DyarTokens.brand,
              foregroundColor: Colors.white,
              onPressed: () => _createDialog(context, ref),
              icon: const Icon(LucideIcons.plus),
              label: Text(s('requestQuote')),
            ),
      body: StreamBuilder<List<Rfq>>(
        stream: ref.read(b2bServiceProvider).watchMine(uid),
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
            itemBuilder: (context, i) => _RfqCard(rfq: rfqs[i]),
          );
        },
      ),
    );
  }

  Future<void> _createDialog(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final product = TextEditingController();
    final qty = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${s('requestQuote')} · ${storeName ?? ''}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: product,
              decoration: InputDecoration(labelText: s('rfqProduct'))),
          const SizedBox(height: 8),
          TextField(controller: qty,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: s('rfqQty'))),
          const SizedBox(height: 8),
          TextField(controller: note,
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
    final q = int.tryParse(qty.text.trim()) ?? 0;
    if (ok == true && product.text.trim().isNotEmpty && q > 0) {
      try {
        await ref.read(b2bServiceProvider).createRfq(
              storeId: storeId!,
              productName: product.text.trim(),
              qty: q,
              note: note.text.trim(),
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(s('rfqSent'))));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(s('error'))));
        }
      }
    }
    product.dispose();
    qty.dispose();
    note.dispose();
  }
}

class _RfqCard extends ConsumerWidget {
  const _RfqCard({required this.rfq});
  final Rfq rfq;

  String _statusLabel(S s) => switch (rfq.status) {
        'open' => s('statusOpen'),
        'quoted' => s('statusQuoted'),
        'accepted' => s('statusAccepted'),
        'declined' => s('statusDeclined'),
        _ => s('statusExpired'),
      };

  Color get _statusColor => switch (rfq.status) {
        'quoted' => DyarTokens.brand,
        'accepted' => DyarTokens.success,
        'declined' || 'expired' => DyarTokens.inkMuted,
        _ => DyarTokens.warning,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final q = rfq.quote;
    return DyarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('${rfq.productName} ×${rfq.qty}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(_statusLabel(s),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _statusColor)),
            ),
          ]),
          Text(rfq.storeName,
              style: const TextStyle(
                  color: DyarTokens.inkMuted, fontSize: 12)),
          if (q != null && rfq.isQuoted) ...[
            const Divider(height: 18),
            _line(s('unitPrice'), MoneyText.format(q.unitPrice)),
            _line(s('subtotal'), MoneyText.format(q.total)),
            _line('${s('commission')} (${q.commissionPct}%)',
                MoneyText.format(q.commission)),
            if (q.validUntil != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    '${s('quoteValidUntil')}: ${q.validUntil!.toString().split('.').first}',
                    style: const TextStyle(
                        fontSize: 11, color: DyarTokens.inkMuted)),
              ),
            const SizedBox(height: 12),
            if (q.isValid)
              Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respond(context, ref, true),
                    child: Text(s('acceptQuote')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(context, ref, false),
                    child: Text(s('declineQuote')),
                  ),
                ),
              ])
            else
              Text(s('statusExpired'),
                  style: const TextStyle(color: DyarTokens.inkMuted)),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: DyarTokens.inkMuted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );

  Future<void> _respond(BuildContext context, WidgetRef ref, bool accept) async {
    final s = ref.read(stringsProvider);
    try {
      await ref.read(b2bServiceProvider).respondRfq(rfq.id, accept);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s('error'))));
      }
    }
  }
}
