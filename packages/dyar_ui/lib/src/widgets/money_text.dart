import 'package:flutter/material.dart';

/// عرض المبالغ: المخزَّن بالأغورة، العرض بالشيكل ₪ دائمًا مع رمز العملة
/// (تصحيح من مراجعة الـ Handoff: "أسعار بلا ₪" كان خطأ مرصودًا).
class MoneyText extends StatelessWidget {
  const MoneyText(this.agorot, {super.key, this.style});

  final int agorot;
  final TextStyle? style;

  static String format(int agorot) =>
      '₪${(agorot / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Text(
      format(agorot),
      style: style ?? const TextStyle(fontWeight: FontWeight.w800),
      textDirection: TextDirection.ltr,
    );
  }
}
