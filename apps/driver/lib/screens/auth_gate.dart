import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';

import 'login_screen.dart';
import 'home_screen.dart';

/// بوابة المصادقة: دخول بالهاتف → تسجيل سائق إن لم يوجد ملف → الرئيسية.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
      data: (user) =>
          user == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
