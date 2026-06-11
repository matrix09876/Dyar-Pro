import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// الطرد النشط: استلام → نقل → تسليم برمز OTP من المستلم (حماية ديار).
class ActiveParcelScreen extends ConsumerStatefulWidget {
  const ActiveParcelScreen({super.key, required this.parcelId});
  final String parcelId;

  @override
  ConsumerState<ActiveParcelScreen> createState() =>
      _ActiveParcelScreenState();
}

class _ActiveParcelScreenState extends ConsumerState<ActiveParcelScreen> {
  final _otp = TextEditingController();
  bool _busy = false;

  Future<void> _do(Future<void> Function() op) async {
    final s = ref.read(stringsProvider);
    setState(() => _busy = true);
    try {
      await op();
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

    return Scaffold(
      appBar: AppBar(title: Text('${s('parcel')} 📦')),
      body: StreamBuilder<Parcel?>(
        stream: ref.read(parcelServiceProvider).watch(widget.parcelId),
        builder: (context, snap) {
          final p = snap.data;
          if (p == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (p.status == 'delivered') {
            return EmptyState(
                message: s('delivered'), icon: LucideIcons.packageCheck);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DyarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusChip(
                            label: p.status, statusKey: p.status),
                        MoneyText(p.total),
                      ],
                    ),
                    const Divider(height: 24),
                    _Party(
                        icon: LucideIcons.package,
                        title: s('senderInfo'),
                        name: p.sender['name']?.toString() ?? '',
                        phone: p.sender['phone']?.toString()),
                    const SizedBox(height: 10),
                    _Party(
                        icon: LucideIcons.mapPin,
                        title: s('recipientInfo'),
                        name: p.recipient['name']?.toString() ?? '',
                        phone: p.recipient['phone']?.toString()),
                    const SizedBox(height: 8),
                    Text('${s('weight')}: ${p.weightKg} كغم',
                        style: const TextStyle(
                            color: DyarTokens.inkMuted, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (p.status == 'pickup')
                CtaButton(
                  label: s('onTheWay'),
                  icon: LucideIcons.navigation,
                  loading: _busy,
                  onPressed: () => _do(() => ref
                      .read(parcelServiceProvider)
                      .startTransit(p.id)),
                ),

              if (p.status == 'in_transit') ...[
                Text(s('deliveryOtp'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12),
                  decoration:
                      const InputDecoration(hintText: '• • • •'),
                ),
                const SizedBox(height: 8),
                CtaButton(
                  label: '${s('delivered')} ✅',
                  loading: _busy,
                  onPressed: () => _do(() async {
                    await ref
                        .read(parcelServiceProvider)
                        .confirmDelivery(p.id, _otp.text.trim());
                    if (mounted) Navigator.of(context).pop();
                  }),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Party extends StatelessWidget {
  const _Party(
      {required this.icon,
      required this.title,
      required this.name,
      this.phone});
  final IconData icon;
  final String title, name;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: DyarTokens.brand, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 11.5, color: DyarTokens.inkMuted)),
            Text(name,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      if (phone != null && phone!.isNotEmpty)
        IconButton(
          icon: const Icon(LucideIcons.phone,
              color: DyarTokens.success, size: 20),
          onPressed: () => launchUrl(Uri.parse('tel:$phone')),
        ),
    ]);
  }
}
