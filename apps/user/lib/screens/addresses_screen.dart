import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'pin_picker_screen.dart';

/// عناويني: عرض/إضافة/حذف — مربوطة بـ users/{uid}.addresses.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref, String uid) async {
    final s = ref.read(stringsProvider);
    final label = TextEditingController();
    final line = TextEditingController();
    double? lat, lng; // إحداثيات دقيقة من منتقي الخريطة
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(s('addAddress')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: label,
                decoration: InputDecoration(labelText: s('name'))),
            const SizedBox(height: 8),
            TextField(controller: line,
                decoration: InputDecoration(labelText: s('dropoffLocation'))),
            const SizedBox(height: 12),
            // اختيار الموقع بدقة المتر على الخريطة
            OutlinedButton.icon(
              onPressed: () async {
                final res = await Navigator.of(ctx).push<Map<String, dynamic>>(
                  MaterialPageRoute(builder: (_) => const PinPickerScreen()),
                );
                if (res != null) {
                  setLocal(() {
                    lat = (res['lat'] as num?)?.toDouble();
                    lng = (res['lng'] as num?)?.toDouble();
                  });
                }
              },
              icon: Icon(lat == null ? LucideIcons.mapPin : LucideIcons.check,
                  size: 16, color: lat == null ? null : DyarTokens.success),
              label: Text(lat == null
                  ? s('pickOnMap')
                  : '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: Text(s('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true),
                child: Text(s('save'))),
          ],
        ),
      ),
    );
    if (ok == true && line.text.isNotEmpty) {
      await ref.read(userServiceProvider).addAddress(uid, {
        'label': label.text, 'line': line.text,
        'lat': lat ?? 0.0, 'lng': lng ?? 0.0,
      });
    }
    label.dispose();
    line.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
          appBar: AppBar(title: Text(s('myAddresses'))),
          body: EmptyState(message: s('signIn'), icon: LucideIcons.mapPin));
    }
    return Scaffold(
      appBar: AppBar(title: Text(s('myAddresses'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref, uid),
        backgroundColor: DyarTokens.brand,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(s('addAddress'), style: const TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<AppUser?>(
        stream: ref.read(userServiceProvider).watch(uid),
        builder: (context, snap) {
          final addresses = snap.data?.addresses ?? [];
          if (addresses.isEmpty) {
            return EmptyState(message: s('noData'), icon: LucideIcons.mapPin);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = addresses[i];
              return DyarCard(
                child: Row(children: [
                  const Icon(LucideIcons.mapPin, color: DyarTokens.brand),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['label']?.toString().isNotEmpty == true
                            ? a['label'].toString()
                            : s('myAddresses'),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(a['line']?.toString() ?? '',
                            style: const TextStyle(
                                color: DyarTokens.inkMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2,
                        color: DyarTokens.danger, size: 20),
                    onPressed: () =>
                        ref.read(userServiceProvider).removeAddress(uid, a),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
