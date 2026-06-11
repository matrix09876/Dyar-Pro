import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// دخول التاجر بالبريد (حسابات التجار تُنشأ عبر لوحة التحكم/التسجيل).
class PartnerLoginScreen extends ConsumerStatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  ConsumerState<PartnerLoginScreen> createState() =>
      _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends ConsumerState<PartnerLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    final s = ref.read(stringsProvider);
    setState(() { _busy = true; _error = null; });
    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(_email.text.trim(), _password.text);
    } catch (_) {
      setState(() => _error = s('error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                height: 88, width: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DyarTokens.brand,
                  borderRadius: BorderRadius.circular(DyarTokens.radiusLg),
                ),
                child: const Text('د',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 16),
              Text('${s('appName')} Partner',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: '••••••',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style: const TextStyle(color: DyarTokens.danger)),
                ),
              const SizedBox(height: 16),
              CtaButton(label: s('signIn'), loading: _busy, onPressed: _login),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
