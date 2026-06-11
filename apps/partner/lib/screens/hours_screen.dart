import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// مواعيد العمل: فتح/إغلاق لكل يوم — تُكتب في stores/{id}.openingHours.
class HoursScreen extends ConsumerStatefulWidget {
  const HoursScreen({super.key, required this.storeId});
  final String storeId;

  @override
  ConsumerState<HoursScreen> createState() => _HoursScreenState();
}

class _HoursScreenState extends ConsumerState<HoursScreen> {
  static const _days = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
  static const _dayAr = {
    'sun': 'الأحد', 'mon': 'الاثنين', 'tue': 'الثلاثاء', 'wed': 'الأربعاء',
    'thu': 'الخميس', 'fri': 'الجمعة', 'sat': 'السبت',
  };

  Map<String, Map<String, dynamic>> _hours = {};
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .doc('stores/${widget.storeId}')
        .get()
        .then((snap) {
      final raw = Map<String, dynamic>.from(
          snap.data()?['openingHours'] ?? const {});
      setState(() {
        _hours = {
          for (final d in _days)
            d: Map<String, dynamic>.from(raw[d] ??
                {'open': '08:00', 'close': '23:00', 'enabled': true}),
        };
        _loaded = true;
      });
    });
  }

  Future<void> _pick(String day, String field) async {
    final current = (_hours[day]![field] as String).split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.parse(current[0]), minute: int.parse(current[1])),
    );
    if (t != null) {
      setState(() => _hours[day]![field] =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .doc('stores/${widget.storeId}')
        .update({'openingHours': _hours});
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s('workHours'))),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final d in _days)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DyarCard(
                      child: Row(children: [
                        SizedBox(
                            width: 74,
                            child: Text(_dayAr[d]!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800))),
                        Switch(
                          value: _hours[d]!['enabled'] ?? true,
                          activeThumbColor: DyarTokens.success,
                          onChanged: (v) =>
                              setState(() => _hours[d]!['enabled'] = v),
                        ),
                        const Spacer(),
                        if (_hours[d]!['enabled'] ?? true) ...[
                          _TimeChip(
                              label: _hours[d]!['open'],
                              onTap: () => _pick(d, 'open')),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('—'),
                          ),
                          _TimeChip(
                              label: _hours[d]!['close'],
                              onTap: () => _pick(d, 'close')),
                        ] else
                          Text(s('closed'),
                              style: const TextStyle(
                                  color: DyarTokens.inkMuted)),
                      ]),
                    ),
                  ),
                const SizedBox(height: 8),
                CtaButton(label: s('save'), loading: _saving, onPressed: _save),
              ],
            ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DyarTokens.brandLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: DyarTokens.brandDark)),
      ),
    );
  }
}
