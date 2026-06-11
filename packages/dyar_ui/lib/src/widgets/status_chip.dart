import 'package:flutter/material.dart';

/// شارة حالة ملوّنة (طلب/مشوار/حجز).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.statusKey});

  final String label;
  final String statusKey;

  static const _colors = <String, (Color, Color)>{
    'pending': (Color(0xFFFEF3C7), Color(0xFFB45309)),
    'accepted': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'preparing': (Color(0xFFE0E7FF), Color(0xFF4338CA)),
    'ready': (Color(0xFFCFFAFE), Color(0xFF0E7490)),
    'assigned': (Color(0xFFEDE9FE), Color(0xFF6D28D9)),
    'picked_up': (Color(0xFFF3E8FF), Color(0xFF7E22CE)),
    'on_the_way': (Color(0xFFE0F2FE), Color(0xFF0369A1)),
    'delivered': (Color(0xFFDCFCE7), Color(0xFF15803D)),
    'completed': (Color(0xFFDCFCE7), Color(0xFF15803D)),
    'cancelled': (Color(0xFFF3F4F6), Color(0xFF4B5563)),
    'rejected': (Color(0xFFFEE2E2), Color(0xFFB91C1C)),
    'confirmed': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'seated': (Color(0xFFE0E7FF), Color(0xFF4338CA)),
    'no_show': (Color(0xFFFEE2E2), Color(0xFFB91C1C)),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors[statusKey] ??
        (Colors.grey.shade200, Colors.grey.shade700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
