import 'package:dyar_ui/dyar_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';

import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// تنقّل سفلي وفق الـ Handoff: الرئيسية · الطلبات · حسابي
/// (home / receipt-text / user-round من Icon Mapping).
class UserShell extends ConsumerStatefulWidget {
  const UserShell({super.key});

  @override
  ConsumerState<UserShell> createState() => _UserShellState();
}

class _UserShellState extends ConsumerState<UserShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: switch (_tab) {
        0 => const HomeScreen(),
        1 => const MyOrdersScreen(),
        _ => const UserProfileScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(LucideIcons.home), label: s('home')),
          NavigationDestination(
              icon: const Icon(LucideIcons.receipt), label: s('orders')),
          NavigationDestination(
              icon: const Icon(LucideIcons.userCircle2), label: s('profile')),
        ],
      ),
    );
  }
}
