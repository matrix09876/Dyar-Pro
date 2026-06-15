import 'package:flutter_test/flutter_test.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_user/state/cart.dart';

MenuItem _item(String id, int price) =>
    MenuItem(id: id, name: 'صنف $id', price: price);

void main() {
  group('CartLine — حساب السطر', () {
    test('lineTotal = (السعر + الإضافات) × الكمية', () {
      final line = CartLine(_item('i1', 2000), 3, [
        {'name': 'كاتشوب', 'price': 200},
        {'name': 'جبنة', 'price': 300},
      ]);
      expect(line.optionsTotal, 500);
      expect(line.unitTotal, 2500);
      expect(line.lineTotal, 7500);
    });
    test('بلا إضافات', () {
      final line = CartLine(_item('i2', 1500), 2);
      expect(line.optionsTotal, 0);
      expect(line.lineTotal, 3000);
    });
    test('مفتاح السطر يفرّق بالخيارات', () {
      final a = CartLine(_item('i3', 1000), 1, [{'name': 'حار'}]);
      final b = CartLine(_item('i3', 1000), 1, [{'name': 'وسط'}]);
      expect(a.key == b.key, isFalse);
    });
  });

  group('CartState — الإجماليات', () {
    test('subtotal وcount عبر عدة سطور + qtyOf', () {
      final st = CartState(storeId: 's1', lines: {
        'a': CartLine(_item('i1', 1000), 2),       // 2000
        'b': CartLine(_item('i2', 1500), 1, [       // 1500+200 = 1700
          {'name': 'إضافة', 'price': 200},
        ]),
        'c': CartLine(_item('i1', 1000), 3),       // 3000 (نفس i1 سطر آخر)
      });
      expect(st.subtotal, 6700);
      expect(st.count, 6);
      expect(st.qtyOf('i1'), 5); // 2 + 3 عبر سطرين
      expect(st.isEmpty, isFalse);
    });
    test('سلة فارغة', () {
      const st = CartState();
      expect(st.subtotal, 0);
      expect(st.count, 0);
      expect(st.isEmpty, isTrue);
    });
  });
}
