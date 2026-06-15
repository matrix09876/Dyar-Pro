import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyar_ui/dyar_ui.dart';

void main() {
  test('MoneyText.format: أغورة → ₪ بخانتين', () {
    expect(MoneyText.format(2500), '₪25.00');
    expect(MoneyText.format(0), '₪0.00');
    expect(MoneyText.format(199), '₪1.99');
  });

  testWidgets('MoneyText يعرض المبلغ بـ LTR داخل RTL', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MoneyText(4690),
      ),
    ));
    expect(find.text('₪46.90'), findsOneWidget);
  });
}
