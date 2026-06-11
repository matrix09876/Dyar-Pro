import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'login_screen.dart';

/// نافذة الحجز (نمط item_sheet): اختيار يوم (اليوم/غدًا/بعد غد) + شبكة
/// أوقات (12:00→22:00 كل 30 دقيقة) + عدد الأشخاص + ملاحظات + مفتاح تذكير
/// + زر "احجز الآن — ₪الرسوم" المتدرّج. الرسوم تُفرض من الخادم.
Future<void> showBookingSheet(
    BuildContext context, WidgetRef ref, Store store) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingSheet(store: store),
  );
}

class _BookingSheet extends ConsumerStatefulWidget {
  const _BookingSheet({required this.store});
  final Store store;

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  int _day = 0; // 0=اليوم 1=غدًا 2=بعد غد
  int? _slotMinutes; // دقائق منذ منتصف الليل (12:00 → 720)
  int _party = 2;
  bool _reminder = true;
  bool _sending = false;
  final _notes = TextEditingController();

  /// نوع الاستشارة للمهن (محامٍ/محاسب/طبيب...): مكتب أو هاتف.
  String _mode = 'office';

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  bool get _isTable => widget.store.type == 'restaurant';

  int get _fee => (widget.store.dineOut?['reservationCost'] ?? 0) as int;

  /// الأوقات: 12:00 → 22:00 كل 30 دقيقة (بالدقائق منذ منتصف الليل)
  static final List<int> _times =
      [for (int m = 12 * 60; m <= 22 * 60; m += 30) m];

  DateTime _slotFor(int day, int minutes) {
    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day + day, minutes ~/ 60, minutes % 60);
  }

  String _fmtTime(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  String? _buildNotes(S s) {
    final parts = [
      if (!_isTable)
        _mode == 'phone' ? s('consultPhone') : s('consultOffice'),
      if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Future<void> _submit() async {
    final s = ref.read(stringsProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const UserLoginScreen()));
      return;
    }
    final minutes = _slotMinutes;
    if (minutes == null || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(bookingServiceProvider).createBooking(
            storeId: widget.store.id,
            type: _isTable ? 'table' : 'service',
            slot: _slotFor(_day, minutes).millisecondsSinceEpoch,
            partySize: _party,
            // للخدمات: نوع الاستشارة يسبق الملاحظات ليظهر للمزوّد واللوحة
            notes: _buildNotes(s),
            reminder: _reminder,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s('bookingPlaced'))));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s('error'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final now = DateTime.now();
    final canBook = _slotMinutes != null && !_sending;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان + إغلاق
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(children: [
                Container(
                  height: 44, width: 44,
                  decoration: BoxDecoration(
                    color: DyarTokens.brandLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.calendarDays,
                      color: DyarTokens.brandDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isTable ? s('bookTable') : s('bookAppointment'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(widget.store.name,
                          style: const TextStyle(
                              fontSize: 12.5, color: DyarTokens.inkMuted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 36, width: 36,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ]),
            ),

            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                children: [
                  // اليوم
                  Text(s('chooseDay'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (final (i, label) in [
                      (0, s('today')),
                      (1, s('tomorrow')),
                      (2, s('dayAfter')),
                    ]) ...[
                      Expanded(
                        child: _DayChip(
                          label: label,
                          selected: _day == i,
                          onTap: () => setState(() {
                            _day = i;
                            _slotMinutes = null;
                          }),
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 8),
                    ],
                  ]),
                  const SizedBox(height: 16),

                  // الوقت — شبكة 12:00→22:00 كل 30 دقيقة
                  Text(s('chooseTime'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in _times)
                        _TimeChip(
                          label: _fmtTime(m),
                          selected: _slotMinutes == m,
                          enabled: _slotFor(_day, m).isAfter(now),
                          onTap: () => setState(() => _slotMinutes = m),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // عدد الأشخاص
                  Row(children: [
                    Expanded(
                      child: Text(s('partySize'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        IconButton(
                            onPressed: _party > 1
                                ? () => setState(() => _party--)
                                : null,
                            icon: const Icon(LucideIcons.minus, size: 18)),
                        Text('$_party',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16)),
                        IconButton(
                            onPressed: _party < 20
                                ? () => setState(() => _party++)
                                : null,
                            icon: const Icon(LucideIcons.plus, size: 18)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // نوع الاستشارة — للمهن فقط (محامٍ/محاسب/طبيب...)
                  if (!_isTable) ...[
                    Text(s('consultType'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    Row(children: [
                      for (final opt in [
                        ('office', s('consultOffice')),
                        ('phone', s('consultPhone')),
                      ]) ...[
                        ChoiceChip(
                          label: Text(opt.$2,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: _mode == opt.$1
                                      ? Colors.white
                                      : DyarTokens.inkMuted)),
                          selected: _mode == opt.$1,
                          selectedColor: DyarTokens.brand,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999)),
                          onSelected: (_) =>
                              setState(() => _mode = opt.$1),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // ملاحظات
                  TextField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: s('bookingNotes'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  // تذكير قبل 30 دقيقة
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: DyarTokens.brand,
                    value: _reminder,
                    onChanged: (v) => setState(() => _reminder = v),
                    title: Text(s('remindMe'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    secondary: const Icon(LucideIcons.bellRing,
                        color: DyarTokens.brand),
                  ),
                ],
              ),
            ),

            // CTA متدرّج "احجز الآن — ₪الرسوم"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: GestureDetector(
                onTap: canBook ? _submit : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: canBook ? 1 : 0.5,
                  child: Container(
                    height: DyarTokens.ctaHeight,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFF8A3D),
                        DyarTokens.brandDark,
                      ]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: DyarTokens.brand.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(children: [
                      Text(s('bookNow'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      const Spacer(),
                      Text(_fee > 0 ? MoneyText.format(_fee) : s('free'),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [
                  Color(0xFFFF8A3D),
                  DyarTokens.brandDark,
                ])
              : null,
          color: selected ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : DyarTokens.ink,
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 44, width: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [
                  Color(0xFFFF8A3D),
                  DyarTokens.brandDark,
                ])
              : null,
          color: selected ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
                color: selected
                    ? Colors.white
                    : enabled
                        ? DyarTokens.ink
                        : const Color(0xFFC4C7CE),
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      ),
    );
  }
}
