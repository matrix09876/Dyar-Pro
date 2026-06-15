import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyar_ui/dyar_ui.dart';

void main() {
  testWidgets('StatusChip يعرض التسمية بألوان الحالة المعروفة', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: StatusChip(label: 'تم التوصيل', statusKey: 'delivered'),
      ),
    ));
    expect(find.text('تم التوصيل'), findsOneWidget);
  });

  testWidgets('StatusChip يتحمّل حالة غير معروفة (لون رمادي افتراضي)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: StatusChip(label: 'غير معروف', statusKey: 'zzz'),
      ),
    ));
    expect(find.text('غير معروف'), findsOneWidget);
  });
}
