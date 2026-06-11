import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// تسجيل سائق جديد (KYC): نوع المركبة + اللوحة + بيانات الوثائق —
/// يبدأ بحالة pending حتى توافق الإدارة من اللوحة.
class DriverRegisterScreen extends ConsumerStatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  ConsumerState<DriverRegisterScreen> createState() =>
      _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends ConsumerState<DriverRegisterScreen> {
  String _vehicle = 'car';
  final _plate = TextEditingController();
  final _license = TextEditingController();
  final _idNumber = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _busy = true);
    await ref.read(driverServiceProvider).register(
          uid,
          vehicleType: _vehicle,
          plate: _plate.text.trim().isEmpty ? null : _plate.text.trim(),
        );
    // بيانات الوثائق نصيًا (رفع الصور يتفعّل مع Storage الإنتاجي)
    await ref.read(driverServiceProvider).updateDocuments(uid, {
      'licenseNumber': _license.text.trim(),
      'idNumber': _idNumber.text.trim(),
      'verified': false,
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final vehicles = [
      ('car', '🚗', s('taxi')),
      ('motorcycle', '🏍️', 'دراجة نارية'),
      ('bicycle', '🚲', 'دراجة'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s('driverRegister'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(s('vehicle'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            for (final (key, emoji, label) in vehicles)
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _vehicle = key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _vehicle == key
                            ? DyarTokens.brandLight
                            : Colors.white,
                        border: Border.all(
                            color: _vehicle == key
                                ? DyarTokens.brand
                                : Colors.black12,
                            width: _vehicle == key ? 2 : 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(children: [
                        Text(emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(label,
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _plate,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'رقم اللوحة'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _license,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'رقم الرخصة'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _idNumber,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'رقم الهوية'),
          ),
          const SizedBox(height: 24),
          CtaButton(
            label: s('continue'),
            icon: LucideIcons.checkCircle2,
            loading: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          Text(s('pendingApprovalNote'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: DyarTokens.inkMuted, fontSize: 12.5)),
        ],
      ),
    );
  }
}
