import 'package:flutter_test/flutter_test.dart';
import 'package:dyar_core/dyar_core.dart';

void main() {
  group('geo', () {
    test('distanceKm صفر لنفس النقطة', () {
      expect(distanceKm(32.8, 35.3, 32.8, 35.3), closeTo(0, 0.001));
    });
    test('distanceKm الناصرة↔حيفا ~30كم تقريبًا', () {
      final d = distanceKm(32.70, 35.30, 32.79, 34.99);
      expect(d, greaterThan(25));
      expect(d, lessThan(40));
    });
    test('formatKm بالمتر تحت كيلومتر وبالكسر فوقه', () {
      expect(formatKm(0.4), contains('م'));
      expect(formatKm(2.5), contains('كم'));
    });
  });

  group('dietary util', () {
    test('المفاتيح المعروفة موجودة وبالترتيب', () {
      expect(kDietaryTags.first.key, 'halal');
      expect(kDietaryTags.any((t) => t.key == 'kosher'), isTrue);
    });
    test('halal/kosher وسوم تصديق', () {
      expect(dietaryTagByKey('halal')!.certification, isTrue);
      expect(dietaryTagByKey('vegan')!.certification, isFalse);
      expect(dietaryTagByKey('غير_موجود'), isNull);
    });
  });
}
