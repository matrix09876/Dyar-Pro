import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// المشوار النشط: accepted → arriving → in_progress → completed
/// (الخادم يفرض التسلسل ويضيف 85% للأرباح عند الإكمال).
class ActiveRideScreen extends ConsumerStatefulWidget {
  const ActiveRideScreen({super.key, required this.rideId});
  final String rideId;

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  bool _busy = false;

  static const _next = {
    'accepted': ('arriving', 'وصلت لنقطة الانطلاق 📍'),
    'arriving': ('in_progress', 'بدأ المشوار 🚕'),
    'in_progress': ('completed', 'اكتمل المشوار ✅'),
  };

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('${s('taxi')} 🚕')),
      body: StreamBuilder<Ride?>(
        stream: ref.read(rideServiceProvider).watch(widget.rideId),
        builder: (context, snap) {
          final r = snap.data;
          if (r == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (r.status == 'completed' || r.status == 'cancelled') {
            return EmptyState(
                message: r.status == 'completed'
                    ? 'اكتمل المشوار ✅'
                    : s('cancelled'),
                icon: LucideIcons.checkCircle2);
          }
          final next = _next[r.status];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // بطاقة المشوار
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF111827),
                    Color(0xFF374151),
                  ]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusChip(label: r.status, statusKey: r.status),
                        Text(MoneyText.format(r.total),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Point(
                        emoji: '🟢',
                        label: s('pickupLocation'),
                        value: r.pickup['address']?.toString() ?? '—'),
                    const SizedBox(height: 8),
                    _Point(
                        emoji: '🔴',
                        label: s('dropoffLocation'),
                        value: r.dropoff['address']?.toString() ?? '—'),
                    const SizedBox(height: 10),
                    Text(
                      '${r.distanceKm} كم'
                      '${r.surge > 1 ? '  ·  ذروة ×${r.surge}' : ''}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ملاحة لنقطة الوجهة الحالية
              DyarCard(
                onTap: () {
                  final p = r.status == 'accepted' || r.status == 'arriving'
                      ? r.pickup
                      : r.dropoff;
                  final lat = p['lat'], lng = p['lng'];
                  if (lat != null && lng != null) {
                    launchUrl(Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'));
                  }
                },
                child: Row(children: [
                  const Icon(LucideIcons.navigation,
                      color: DyarTokens.brand),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(s('navigate'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700))),
                  const Icon(Icons.chevron_left,
                      color: DyarTokens.inkMuted),
                ]),
              ),
              const SizedBox(height: 20),

              if (next != null)
                CtaButton(
                  label: next.$2,
                  loading: _busy,
                  onPressed: () async {
                    setState(() => _busy = true);
                    try {
                      await ref
                          .read(rideServiceProvider)
                          .updateStatus(r.id, next.$1);
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s('error'))));
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(
      {required this.emoji, required this.label, required this.value});
  final String emoji, label, value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(emoji),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 11)),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ]);
  }
}
