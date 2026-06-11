import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// دخول الزبون بالهاتف/OTP — نفس تدفق السائق (هاتف أولًا، وفق P0 #6).
class UserLoginScreen extends ConsumerStatefulWidget {
  const UserLoginScreen({super.key});

  @override
  ConsumerState<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends ConsumerState<UserLoginScreen> {
  final _phone = TextEditingController(text: '+972');
  final _code = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  String? _error;

  Future<void> _send() async {
    final s = ref.read(stringsProvider);
    setState(() { _busy = true; _error = null; });
    await ref.read(authServiceProvider).sendOtp(
          phone: _phone.text.trim(),
          onCodeSent: (id) =>
              setState(() { _verificationId = id; _busy = false; }),
          onError: (_) =>
              setState(() { _error = s('error'); _busy = false; }),
        );
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(authServiceProvider)
          .verifyOtp(_verificationId!, _code.text.trim());
      await ref.read(authServiceProvider).ensureProfile();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _error = ref.read(stringsProvider)('error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final otpSent = _verificationId != null;
    return Scaffold(
      appBar: AppBar(title: Text(s('signIn'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            if (!otpSent)
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: s('phone'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              )
            else
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: s('otpCode'),
                  prefixIcon: const Icon(Icons.sms_outlined),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style: const TextStyle(color: DyarTokens.danger)),
              ),
            const SizedBox(height: 16),
            CtaButton(
              label: otpSent ? s('signIn') : s('continue'),
              loading: _busy,
              onPressed: otpSent ? _verify : _send,
            ),
          ],
        ),
      ),
    );
  }
}
