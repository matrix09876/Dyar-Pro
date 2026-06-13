import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// دخول بالهاتف/OTP — التدفق القياسي في سوق إسرائيل (+972).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController(text: '+972');
  final _code = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = ref.read(stringsProvider);
    setState(() { _busy = true; _error = null; });
    await ref.read(authServiceProvider).sendOtp(
          phone: _phone.text.trim(),
          onCodeSent: (id) => setState(() { _verificationId = id; _busy = false; }),
          onError: (e) => setState(() { _error = s('error'); _busy = false; }),
        );
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(authServiceProvider)
          .verifyOtp(_verificationId!, _code.text.trim());
      await ref.read(authServiceProvider).ensureProfile();
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
              Text('${s('appName')} Driver',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800)),
              Text(s('allYouNeed'), textAlign: TextAlign.center),
              const SizedBox(height: 32),
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
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
