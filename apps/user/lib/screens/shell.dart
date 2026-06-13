import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../state/cart.dart';
import 'checkout_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// هيكل التطبيق مع شريط تنقّل سفلي عائم (نمط سوبر آب) بمؤشر متدرّج
/// وشارة عدد السلة.
class UserShell extends ConsumerStatefulWidget {
  const UserShell({super.key});

  @override
  ConsumerState<UserShell> createState() => _UserShellState();
}

class _UserShellState extends ConsumerState<UserShell> {
  int _tab = 0;

  /// زر الرجوع: من أي تبويب → يعود للرئيسية؛ من الرئيسية → شريحة تأكيد الخروج.
  Future<void> _onBack() async {
    if (_tab != 0) {
      setState(() => _tab = 0);
      return;
    }
    final s = ref.read(stringsProvider);
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(s('exitTitle'),
            style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(s('exitBody')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s('stay'),
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s('exitApp'))),
        ],
      ),
    );
    if (exit == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final cartCount = ref.watch(cartProvider).count;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
      extendBody: true,
      body: switch (_tab) {
        0 => const HomeScreen(),
        1 => const MyOrdersScreen(),
        _ => const UserProfileScreen(),
      },
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط السلة الدائم عبر التبويبات (Basket bar — QW5)
            if (cartCount > 0) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CheckoutScreen())),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFF8A3D),
                      DyarTokens.brandDark,
                    ]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: DyarTokens.brand.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    const Icon(LucideIcons.shoppingCart,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('${s('viewCart')} ($cartCount)',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text(MoneyText.format(ref.watch(cartProvider).subtotal),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 10)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              _NavItem(
                icon: LucideIcons.home,
                label: s('home'),
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              _NavItem(
                icon: LucideIcons.receipt,
                label: s('orders'),
                selected: _tab == 1,
                badge: cartCount > 0 ? cartCount : null,
                onTap: () => setState(() => _tab = 1),
              ),
              _NavItem(
                icon: LucideIcons.userCircle2,
                label: s('profile'),
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
        ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [
                    Color(0xFFFF8A3D),
                    DyarTokens.brandDark,
                  ])
                : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: DyarTokens.brand.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 5)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(clipBehavior: Clip.none, children: [
                Icon(icon,
                    size: 23,
                    color: selected ? Colors.white : DyarTokens.inkMuted),
                if (badge != null)
                  PositionedDirectional(
                    top: -6, end: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
              ]),
              if (selected) ...[
                const SizedBox(width: 7),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
