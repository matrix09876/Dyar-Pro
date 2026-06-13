import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// شحن طرد: بيانات المرسِل والمستلِم + الوزن → إنشاء شحنة برمز تسليم OTP
/// (حماية ديار) يُعرض للمرسِل ليعطيه للمستلِم.
class ParcelScreen extends ConsumerStatefulWidget {
  const ParcelScreen({super.key});

  @override
  ConsumerState<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends ConsumerState<ParcelScreen> {
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _recipName = TextEditingController();
  final _recipPhone = TextEditingController();
  final _weight = TextEditingController(text: '1');
  bool _busy = false;
  String? _otp;
  int? _total;

  @override
  void dispose() {
    _senderName.dispose();
    _senderPhone.dispose();
    _recipName.dispose();
    _recipPhone.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = ref.read(stringsProvider);
    setState(() => _busy = true);
    try {
      final res = await ref.read(parcelServiceProvider).create(
        sender: {'name': _senderName.text, 'phone': _senderPhone.text},
        recipient: {'name': _recipName.text, 'phone': _recipPhone.text},
        weightKg: double.tryParse(_weight.text) ?? 1,
      );
      setState(() {
        _otp = res['deliveryOtp'] as String?;
        _total = res['total'] as int?;
      });
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

    if (_otp != null) {
      return Scaffold(
        appBar: AppBar(title: Text(s('parcel'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DyarCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.packageCheck,
                    size: 56, color: DyarTokens.success),
                const SizedBox(height: 12),
                Text(s('orderPlaced'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 16),
                Text(s('deliveryOtp')),
                Text(_otp!,
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: DyarTokens.brand)),
                const SizedBox(height: 8),
                if (_total != null) MoneyText(_total!),
              ]),
            ),
          ),
        ),
      );
    }

    Widget field(String label, TextEditingController c,
            {TextInputType? type}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: c,
            keyboardType: type,
            decoration: InputDecoration(labelText: label),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s('parcel'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s('senderInfo'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          field(s('name'), _senderName),
          field(s('phone'), _senderPhone, type: TextInputType.phone),
          const SizedBox(height: 8),
          Text(s('recipientInfo'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          field(s('name'), _recipName),
          field(s('phone'), _recipPhone, type: TextInputType.phone),
          field(s('weight'), _weight, type: TextInputType.number),
          const SizedBox(height: 16),
          CtaButton(
            label: s('sendParcel'),
            icon: LucideIcons.package,
            loading: _busy,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
