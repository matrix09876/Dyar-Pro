import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../state/cart.dart';
import 'login_screen.dart';
import 'tracking_screen.dart';

/// الدفع: ملخص + طريقة الدفع (نقدًا/بطاقة عبر Stripe) — bottom nav مخفي
/// في مسار الدفع وفق قرار P0 #2. التسعير النهائي من الخادم.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _method = 'cash';
  bool _busy = false;

  Future<void> _placeOrder() async {
    final s = ref.read(stringsProvider);
    if (FirebaseAuth.instance.currentUser == null) {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UserLoginScreen()));
      if (FirebaseAuth.instance.currentUser == null) return;
    }
    final cart = ref.read(cartProvider);
    if (cart.isEmpty || cart.storeId == null) return;

    setState(() => _busy = true);
    try {
      final res = await ref.read(orderServiceProvider).createOrder(
            storeId: cart.storeId!,
            items: ref.read(cartProvider.notifier).toOrderItems(),
            type: 'delivery',
            paymentMethod: _method,
            // العنوان: يُستبدل بعناوين المستخدم المحفوظة
            address: {'line': '', 'lat': 0.0, 'lng': 0.0},
          );
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) =>
                TrackingScreen(orderId: res['orderId'] as String)));
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
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s('checkout'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DyarCard(
            child: Column(
              children: [
                ...cart.lines.values.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${l.qty}× ${l.item.name}')),
                          MoneyText(l.lineTotal),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s('subtotal')),
                    MoneyText(cart.subtotal),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${s('deliveryFee')} + ${s('serviceFee')} →',
                  style: const TextStyle(
                      fontSize: 12, color: DyarTokens.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // طريقة الدفع
          Text(s('payment'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _PayOption(
            icon: LucideIcons.banknote,
            label: s('payCash'),
            selected: _method == 'cash',
            onTap: () => setState(() => _method = 'cash'),
          ),
          const SizedBox(height: 8),
          _PayOption(
            icon: LucideIcons.creditCard,
            label: '${s('payCard')} · Stripe',
            selected: _method == 'card',
            onTap: () => setState(() => _method = 'card'),
          ),
          const SizedBox(height: 24),

          CtaButton(
            label: s('checkout'),
            trailing: MoneyText.format(cart.subtotal),
            loading: _busy,
            icon: LucideIcons.lock,
            onPressed: cart.isEmpty ? null : _placeOrder,
          ),
        ],
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DyarTokens.brandLight
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(DyarTokens.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DyarTokens.radius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
                color: selected ? DyarTokens.brand : Colors.black12,
                width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(DyarTokens.radius),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected
                      ? DyarTokens.brandDark
                      : DyarTokens.inkMuted),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700))),
              if (selected)
                const Icon(LucideIcons.checkCircle2,
                    color: DyarTokens.brand),
            ],
          ),
        ),
      ),
    );
  }
}
