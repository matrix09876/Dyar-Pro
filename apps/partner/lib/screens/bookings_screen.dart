import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'shell.dart';

/// حجوزات المتجر الحية (طاولات/مواعيد): تأكيد → إجلاس → إكمال،
/// أو لم يحضر/إلغاء. لحظي عبر Firestore والخادم يفرض التسلسل والصلاحيات.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final store = ref.watch(myStoreProvider).value;
    if (store == null) {
      return EmptyState(message: s('noData'), icon: LucideIcons.store);
    }

    return StreamBuilder<List<Booking>>(
      stream: ref.read(bookingServiceProvider).watchStore(store.id),
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
          itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
        );
      },
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});
  final Booking booking;

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
    final svc = ref.read(bookingServiceProvider);

    // أزرار الإجراء حسب الحالة (الخادم يفرض الصلاحيات والتسلسل)
    final actions = switch (booking.status) {
      'pending' => [
          (s('confirm'), 'confirmed', DyarTokens.success),
          (s('cancel'), 'cancelled', DyarTokens.danger),
        ],
      'confirmed' => [
          (s('seatGuests'), 'seated', DyarTokens.brand),
          (s('complete'), 'completed', DyarTokens.success),
          (s('noShow'), 'no_show', DyarTokens.danger),
        ],
      'seated' => [
          (s('complete'), 'completed', DyarTokens.success),
        ],
      _ => <(String, String, Color)>[],
    };

    return DyarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(
                    booking.type == 'table'
                        ? LucideIcons.utensils
                        : LucideIcons.calendarDays,
                    size: 18,
                    color: DyarTokens.brandDark),
                const SizedBox(width: 6),
                Text(
                    booking.type == 'table'
                        ? s('bookTable')
                        : s('bookAppointment'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
              StatusChip(
                  label: s.status(booking.status),
                  statusKey: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Text('${_fmtSlot(booking.slot)} · ${s('partySize')}: ${booking.partySize}'),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(booking.notes!,
                style: const TextStyle(
                    fontSize: 12.5, color: DyarTokens.inkMuted)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s('reservationFee'),
                  style: const TextStyle(color: DyarTokens.inkMuted)),
              booking.fee > 0
                  ? MoneyText(booking.fee,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800))
                  : Text(s('free'),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (label, status, color) in actions) ...[
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        minimumSize: const Size.fromHeight(46),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => svc.updateStatus(booking.id, status),
                      child: Text(label),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ]..removeLast(),
            ),
          ],
        ],
      ),
    );
  }
}
