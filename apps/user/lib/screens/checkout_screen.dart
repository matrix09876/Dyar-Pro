import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import '../state/cart.dart';
import 'login_screen.dart';
import 'tracking_screen.dart';

/// الدفع: ملخص + طريقة الدفع (نقدًا/بطاقة عبر Stripe) — bottom nav مخفي
/// في مسار الدفع وفق قرار P0 #2. التسعير النهائي من الخادم.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _method = 'cash';
  bool _busy = false;
  Map<String, dynamic>? _address;
  int _tip = 0; // أغورة
  final _promo = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _scheduledFor; // null = الآن

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final u = await ref.read(userServiceProvider).watch(uid).first;
    if (mounted && u != null && u.addresses.isNotEmpty) {
      setState(() => _address = u.addresses.first);
    }
  }

  /// اختيار عنوان محفوظ أو إضافة جديد — العنوان إلزامي قبل الطلب.
  Future<void> _pickAddress() async {
    final s = ref.read(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UserLoginScreen()));
      if (FirebaseAuth.instance.currentUser == null) return;
    }
    final u = await ref
        .read(userServiceProvider)
        .watch(FirebaseAuth.instance.currentUser!.uid)
        .first;
    if (!mounted) return;
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(s('myAddresses'),
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            for (final a in u?.addresses ?? const <Map<String, dynamic>>[])
              ListTile(
                leading: const Icon(LucideIcons.mapPin,
                    color: DyarTokens.brand),
                title: Text(a['label']?.toString() ?? ''),
                subtitle: Text(a['line']?.toString() ?? ''),
                onTap: () => Navigator.pop(ctx, a),
              ),
            ListTile(
              leading: const Icon(LucideIcons.plus),
              title: Text(s('addAddress')),
              onTap: () => Navigator.pop(ctx, {'__add': true}),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if (picked['__add'] == true) {
      final line = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s('addAddress')),
          content: TextField(
              controller: line,
              decoration: InputDecoration(labelText: s('myAddresses'))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s('cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s('save'))),
          ],
        ),
      );
      if (ok == true && line.text.trim().isNotEmpty) {
        final addr = {
          'label': s('home'),
          'line': line.text.trim(),
          'lat': 0.0, 'lng': 0.0,
        };
        await ref.read(userServiceProvider).addAddress(
            FirebaseAuth.instance.currentUser!.uid, addr);
        setState(() => _address = addr);
      }
    } else {
      setState(() => _address = picked);
    }
  }

  Future<void> _placeOrder() async {
    final s = ref.read(stringsProvider);
    if (FirebaseAuth.instance.currentUser == null) {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UserLoginScreen()));
      if (FirebaseAuth.instance.currentUser == null) return;
    }
    if (_address == null) {
      await _pickAddress();
      if (_address == null) return; // العنوان شرط للتوصيل
    }
    final cart = ref.read(cartProvider);
    if (cart.isEmpty || cart.storeId == null) return;

    setState(() => _busy = true);
    try {
      final res = await ref.read(orderServiceProvider).createOrder(
            storeId: cart.storeId!,
            items: ref.read(cartProvider.notifier).toOrderItems(),
            type: 'delivery',
            paymentMethod: _method,
            address: {
              ...?_address,
              if (_notes.text.trim().isNotEmpty)
                'notes': _notes.text.trim(),
            },
            tip: _tip,
            couponCode: _promo.text.trim().isEmpty
                ? null
                : _promo.text.trim().toUpperCase(),
            scheduledFor: _scheduledFor?.millisecondsSinceEpoch,
          );
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) =>
                TrackingScreen(orderId: res['orderId'] as String)));
      }
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
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s('checkout'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DyarCard(
            child: Column(
              children: [
                ...cart.lines.values.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${l.qty}× ${l.item.name}')),
                          MoneyText(l.lineTotal),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s('subtotal')),
                    MoneyText(cart.subtotal),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${s('deliveryFee')} + ${s('serviceFee')} →',
                  style: const TextStyle(
                      fontSize: 12, color: DyarTokens.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // طريقة الدفع
          Text(s('payment'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          // عنوان التوصيل — إلزامي
          DyarCard(
            onTap: _pickAddress,
            child: Row(children: [
              const Icon(LucideIcons.mapPin, color: DyarTokens.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _address == null
                      ? s('addAddress')
                      : '${_address!['label'] ?? ''} · ${_address!['line'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _address == null
                          ? DyarTokens.brand
                          : null),
                ),
              ),
              const Icon(Icons.chevron_left, color: DyarTokens.inkMuted),
            ]),
          ),
          const SizedBox(height: 16),

          // البقشيش (نمط Wolt) — يذهب كاملًا للسائق
          Text(s('tip'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(children: [
            for (final v in const [0, 200, 500, 1000])
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  selected: _tip == v,
                  selectedColor: DyarTokens.brand,
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _tip == v ? Colors.white : null),
                  label: Text(v == 0 ? '—' : MoneyText.format(v),
                      textDirection: TextDirection.ltr),
                  onSelected: (_) => setState(() => _tip = v),
                ),
              ),
          ]),
          const SizedBox(height: 16),

          // كود الخصم + ملاحظات التوصيل
          TextField(
            controller: _promo,
            textDirection: TextDirection.ltr,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: s('promoCode'),
              prefixIcon: const Icon(LucideIcons.gift, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: s('deliveryNotes'),
              prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // الآن / جدولة (نمط HAAT scheduled orders)
          Row(children: [
            Expanded(
              child: ChoiceChip(
                selected: _scheduledFor == null,
                selectedColor: DyarTokens.brand,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _scheduledFor == null ? Colors.white : null),
                label: Center(child: Text(s('now'))),
                onSelected: (_) => setState(() => _scheduledFor = null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                selected: _scheduledFor != null,
                selectedColor: DyarTokens.brand,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _scheduledFor != null ? Colors.white : null),
                label: Center(
                  child: Text(_scheduledFor == null
                      ? s('scheduleDelivery')
                      : '${_scheduledFor!.hour.toString().padLeft(2, '0')}:${_scheduledFor!.minute.toString().padLeft(2, '0')}'),
                ),
                onSelected: (_) async {
                  final t = await showTimePicker(
                      context: context, initialTime: TimeOfDay.now());
                  if (t != null) {
                    final now = DateTime.now();
                    var dt = DateTime(
                        now.year, now.month, now.day, t.hour, t.minute);
                    if (dt.isBefore(now)) {
                      dt = dt.add(const Duration(days: 1));
                    }
                    setState(() => _scheduledFor = dt);
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // طرق الدفع المعتمدة: VISA · CASH · BIT (قرار المالك)
          _PayOption(
            icon: LucideIcons.creditCard,
            label: 'VISA · ${s('payCard')}',
            selected: _method == 'card',
            onTap: () => setState(() => _method = 'card'),
          ),
          const SizedBox(height: 8),
          _PayOption(
            icon: LucideIcons.banknote,
            label: s('payCash'),
            selected: _method == 'cash',
            onTap: () => setState(() => _method = 'cash'),
          ),
          const SizedBox(height: 8),
          _PayOption(
            icon: LucideIcons.wallet,
            label: s('payBit'),
            selected: _method == 'bit',
            onTap: () => setState(() => _method = 'bit'),
          ),
          const SizedBox(height: 24),

          CtaButton(
            label: s('checkout'),
            trailing: MoneyText.format(cart.subtotal),
            loading: _busy,
            icon: LucideIcons.lock,
            onPressed: cart.isEmpty ? null : _placeOrder,
          ),
        ],
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DyarTokens.brandLight
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(DyarTokens.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DyarTokens.radius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
                color: selected ? DyarTokens.brand : Colors.black12,
                width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(DyarTokens.radius),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected
                      ? DyarTokens.brandDark
                      : DyarTokens.inkMuted),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700))),
              if (selected)
                const Icon(LucideIcons.checkCircle2,
                    color: DyarTokens.brand),
            ],
          ),
        ),
      ),
    );
  }
}
