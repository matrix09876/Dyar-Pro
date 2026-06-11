import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// قفل التطبيق ببصمة/Face ID — طبقة حماية اختيارية لكل التطبيقات الثلاثة.
/// (غير مدعوم على الويب — يُعطَّل تلقائيًا هناك.)
class AppLockService {
  static const _key = 'dyar.appLock';
  final _auth = LocalAuthentication();

  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  Future<void> setEnabled(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_key, v);

  Future<bool> authenticate(String reason) async {
    if (kIsWeb) return true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}

/// بوابة القفل: تغلّف جذر التطبيق — تطلب البصمة عند الفتح والعودة
/// من الخلفية إذا كان القفل مفعّلًا.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child, this.reason = 'افتح ديار'});
  final Widget child;
  final String reason;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  final _svc = AppLockService();
  bool _locked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _locked) _unlock();
    if (state == AppLifecycleState.paused) _relockIfEnabled();
  }

  Future<void> _relockIfEnabled() async {
    if (await _svc.isEnabled()) setState(() => _locked = true);
  }

  Future<void> _check() async {
    final enabled = await _svc.isEnabled();
    setState(() {
      _locked = enabled;
      _checking = false;
    });
    if (enabled) _unlock();
  }

  Future<void> _unlock() async {
    final ok = await _svc.authenticate(widget.reason);
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Material(
          child: Center(child: CircularProgressIndicator()));
    }
    if (!_locked) return widget.child;
    return Material(
      color: const Color(0xFF15151A),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔒', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('ديار مقفل',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _unlock,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('فتح بالبصمة / Face ID'),
            ),
          ),
        ]),
      ),
    );
  }
}
