import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String name;
  final String? description, imageUrl, categoryId;
  final int price; // أغورة
  final bool available;
  final int sortOrder;

  /// حد أدنى للكمية (متاجر الجملة B2B) — الافتراضي 1 للبيع بالمفرّق.
  final int minQty;

  /// وسوم حِمية الصنف — حلال/كوشير/نباتي/فيغان/خالٍ من الغلوتين/حار.
  /// تُعرض كشرائح صغيرة وتُطابَق ضد حساسيات المستخدم.
  final List<String> dietary;

  const MenuItem({
    required this.id, required this.name, required this.price,
    this.description, this.imageUrl, this.categoryId,
    this.available = true, this.sortOrder = 0, this.minQty = 1,
    this.dietary = const [],
  });

  factory MenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return MenuItem(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'],
      imageUrl: d['imageUrl'],
      categoryId: d['categoryId'],
      price: (d['price'] ?? 0) as int,
      available: d['available'] ?? true,
      sortOrder: (d['sortOrder'] ?? 0) as int,
      minQty: (d['minQty'] ?? 1) as int,
      dietary: List<String>.from(d['dietary'] ?? const []),
    );
  }
}
