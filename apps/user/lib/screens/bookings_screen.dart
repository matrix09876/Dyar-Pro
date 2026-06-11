import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// حجوزاتي: قائمة لحظية (طاولات/مواعيد) بحالة ملوّنة StatusChip
/// + إلغاء ما دام الحجز pending/confirmed (الخادم يفرض الصلاحيات).
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  static String _fmtSlot(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')} · '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
          appBar: AppBar(title: Text(s('myBookings'))),
          body: EmptyState(
              message: s('signIn'), icon: LucideIcons.calendarDays));
    }

    return Scaffold(
      appBar: AppBar(title: Text(s('myBookings'))),
      body: StreamBuilder<List<Booking>>(
        stream: ref.read(bookingServiceProvider).watchMine(uid),
        builder: (context, snap) {
          final bookings = snap.data ?? [];
          if (bookings.isEmpty) {
            return EmptyState(
                message: s('noData'), icon: LucideIcons.calendarDays);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = bookings[i];
              final cancellable =
                  b.status == 'pending' || b.status == 'confirmed';
              return DyarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        height: 44, width: 44,
                        decoration: BoxDecoration(
                          color: DyarTokens.brandLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                            b.type == 'table'
                                ? LucideIcons.utensils
                                : LucideIcons.calendarDays,
                            color: DyarTokens.brandDark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                b.type == 'table'
                                    ? s('bookTable')
                                    : s('bookAppointment'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(
                                '${_fmtSlot(b.slot)} · ${s('partySize')}: ${b.partySize}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: DyarTokens.inkMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusChip(
                              label: s.status(b.status),
                              statusKey: b.status),
                          if (b.fee > 0) ...[
                            const SizedBox(height: 4),
                            MoneyText(b.fee),
                          ],
                        ],
                      ),
                    ]),
                    if (b.notes != null && b.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(b.notes!,
                          style: const TextStyle(
                              fontSize: 12.5, color: DyarTokens.inkMuted)),
                    ],
                    if (cancellable) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DyarTokens.danger,
                            side: const BorderSide(
                                color: DyarTokens.danger, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(LucideIcons.xCircle, size: 18),
                          label: Text(s('cancel'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                          onPressed: () => ref
                              .read(bookingServiceProvider)
                              .updateStatus(b.id, 'cancelled'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
