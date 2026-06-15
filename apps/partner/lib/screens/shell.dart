import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'login_screen.dart';
import 'orders_screen.dart';
import 'menu_screen.dart';
import 'bookings_screen.dart';
import 'more_screen.dart';

/// متجر التاجر الحالي (حسب المالك المسجّل).
final myStoreProvider = StreamProvider<Store?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(storeServiceProvider).watchMyStore(uid);
});

/// الهيكل الرئيسي: شريط علوي بزر "نشط" + تبويبات (طلبات/قائمة/المزيد)
/// — مطابق لبنية تطبيق التاجر الحالي مع تحسين.
class PartnerShell extends ConsumerStatefulWidget {
  const PartnerShell({super.key});

  @override
  ConsumerState<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends ConsumerState<PartnerShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const PartnerLoginScreen(),
      data: (user) {
        if (user == null) return const PartnerLoginScreen();
        final store = ref.watch(myStoreProvider).value;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store?.name ?? s('appName'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(s('storeStatus'),
                    style: const TextStyle(
                        fontSize: 12, color: DyarTokens.inkMuted)),
              ],
            ),
            actions: [
              if (store != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ActiveToggle(
                    value: store.isOpen,
                    onChanged: (v) => ref
                        .read(storeServiceProvider)
                        .setOpen(store.id, v),
                    activeLabel: s('active'),
                    inactiveLabel: s('offline'),
                  ),
                ),
            ],
          ),
          body: switch (_tab) {
            0 => const OrdersScreen(),
            1 => const MenuScreen(),
            2 => const BookingsScreen(),
            _ => const MoreScreen(),
          },
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(
                  icon: const Icon(LucideIcons.receipt),
                  label: s('orders')),
              NavigationDestination(
                  icon: const Icon(LucideIcons.utensils), label: s('menu')),
              NavigationDestination(
                  icon: const Icon(LucideIcons.calendarDays),
                  label: s('bookings')),
              NavigationDestination(
                  icon: const Icon(LucideIcons.settings), label: s('more')),
            ],
          ),
        );
      },
    );
  }
}
