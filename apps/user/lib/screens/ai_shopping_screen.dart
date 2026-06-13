import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../state/cart.dart';
import 'checkout_screen.dart';

/// ديار AI — المساعد الذكي يتسوّق عنك: يكتب المستخدم نيّته، فيبني الـAI سلة
/// جاهزة من متجر واحد بأصناف وأسعار حقيقية، ويشرح سبب اختياره. لا طلب بلا
/// تأكيد — المستخدم يراجع ثم «أضف للسلة وتابع».
class AiShoppingScreen extends ConsumerStatefulWidget {
  const AiShoppingScreen({super.key});
  @override
  ConsumerState<AiShoppingScreen> createState() => _AiShoppingScreenState();
}

class _AiShoppingScreenState extends ConsumerState<AiShoppingScreen> {
  final _query = TextEditingController();
  final _budget = TextEditingController(); // شيكل (اختياري)
  bool _busy = false;
  String? _error;
  AiCartSuggestion? _result;

  @override
  void dispose() {
    _query.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    final lang = ref.read(langProvider).name;
    final shekels = double.tryParse(_budget.text.trim());
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await ref.read(aiServiceProvider).buildCart(
            query: q,
            lang: lang,
            budget: shekels != null && shekels > 0 ? (shekels * 100).round() : null,
          );
      setState(() => _result = res);
    } catch (_) {
      setState(() => _error = ref.read(stringsProvider)('aiError'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addToCartAndCheckout(AiCartSuggestion r) {
    final cart = ref.read(cartProvider.notifier);
    cart.clear();
    for (final it in r.items) {
      cart.add(
        r.storeId,
        MenuItem(id: it.itemId, name: it.name, price: it.price),
        qty: it.qty,
      );
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('✨ ${s('aiAssistant')}')),
      body: _result != null
          ? _ResultView(
              result: _result!,
              onConfirm: () => _addToCartAndCheckout(_result!),
              onRetry: () => setState(() => _result = null),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // بطاقة تعريفية
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DyarTokens.brand, DyarTokens.brandDark],
                    ),
                    borderRadius: BorderRadius.circular(DyarTokens.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 30)),
                      const SizedBox(height: 8),
                      Text(s('aiTagline'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(s('aiHint'),
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _query,
                  maxLines: 3,
                  minLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: s('aiPrompt'),
                    hintText: s('aiExample'),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _budget,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: '${s('aiBudget')} ₪',
                    hintText: s('optional'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: DyarTokens.ctaHeight,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _ask,
                    icon: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.sparkles),
                    label: Text(_busy ? s('aiThinking') : s('aiBuild'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: const TextStyle(color: DyarTokens.danger),
                      textAlign: TextAlign.center),
                ],
              ],
            ),
    );
  }
}

/// نتيجة المساعد: المتجر + شرح الاختيار + الأصناف + الإجمالي + التأكيد.
class _ResultView extends ConsumerWidget {
  const _ResultView({
    required this.result,
    required this.onConfirm,
    required this.onRetry,
  });
  final AiCartSuggestion result;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // المتجر المختار
              DyarCard(
                child: Row(children: [
                  const Icon(LucideIcons.store, color: DyarTokens.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(result.storeName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  if (result.usedAi)
                    const Text('✨', style: TextStyle(fontSize: 18)),
                ]),
              ),
              const SizedBox(height: 12),
              // شرح الاختيار (شفافية — لماذا هذه السلة)
              if (result.explanation.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DyarTokens.brandLight,
                    borderRadius: BorderRadius.circular(DyarTokens.radius),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(result.explanation,
                            style: const TextStyle(
                                color: DyarTokens.ink, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // الأصناف
              ...result.items.map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DyarCard(
                      child: Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: DyarTokens.brandLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${it.qty}×',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: DyarTokens.brand,
                                  fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(it.name)),
                        MoneyText(it.lineTotal),
                      ]),
                    ),
                  )),
              const SizedBox(height: 8),
              // الإجمالي
              if (result.overBudget)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('⚠️ ${s('aiOverBudget')}',
                      style: const TextStyle(color: DyarTokens.warning)),
                ),
              _Row(label: s('subtotal'), value: result.subtotal),
              _Row(label: s('deliveryFee'), value: result.deliveryFee),
              const Divider(),
              _Row(label: s('estimatedTotal'), value: result.estimatedTotal, bold: true),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: DyarTokens.ctaHeight,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(LucideIcons.shoppingCart),
                  label: Text(s('aiAddAndContinue'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: Text(s('aiTryAgain')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});
  final String label;
  final int value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
        fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        MoneyText(value, style: style),
      ]),
    );
  }
}
