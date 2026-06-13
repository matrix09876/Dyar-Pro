import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// ديار Meals — نقطة بيع المطعم: التاجر يُدخل رمز الزبون + المبلغ فيُخصم
/// من ميزانية وجباته (scan-to-pay، نمط 10bis). الكاميرا تُضاف لاحقًا؛
/// الإدخال اليدوي يعمل الآن.
class MealPosScreen extends ConsumerStatefulWidget {
  const MealPosScreen({super.key});
  @override
  ConsumerState<MealPosScreen> createState() => _MealPosScreenState();
}

class _MealPosScreenState extends ConsumerState<MealPosScreen> {
  final _code = TextEditingController();
  final _amount = TextEditingController(); // بالشيكل
  bool _busy = false;
  String? _result;

  @override
  void dispose() {
    _code.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final s = ref.read(stringsProvider);
    final code = _code.text.trim();
    final shekels = double.tryParse(_amount.text.trim()) ?? 0;
    if (code.length < 6 || shekels <= 0) return;
    setState(() { _busy = true; _result = null; });
    try {
      final remaining = await ref
          .read(orderServiceProvider)
          .redeemMealPos(code, (shekels * 100).round());
      setState(() => _result =
          '${s('mealPaidOk')} · ${s('mealRemaining')}: ${MoneyText.format(remaining)}');
      _code.clear();
      _amount.clear();
    } catch (_) {
      setState(() => _result = s('mealPosError'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('🍱 ${s('mealPos')}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(s('mealPosHint'),
              style: const TextStyle(color: DyarTokens.inkMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            maxLength: 6,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: s('mealCode'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: '${s('amount')} ₪',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _busy ? null : _redeem,
              child: _busy
                  ? const SizedBox(
                      height: 22, width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('${s('redeem')} 🍱',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _result!.contains('✅') || _result!.contains(s('mealRemaining'))
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(_result!,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}
