import 'package:cloud_firestore/cloud_firestore.dart';

/// حالات الطلب — مطابقة لعقد البيانات docs/DATA-MODEL.md.
enum OrderStatus {
  pending, accepted, preparing, ready, assigned,
  pickedUp, onTheWay, delivered, cancelled, rejected;

  static OrderStatus fromKey(String key) => switch (key) {
        'picked_up' => OrderStatus.pickedUp,
        'on_the_way' => OrderStatus.onTheWay,
        _ => OrderStatus.values.firstWhere(
            (s) => s.name == key, orElse: () => OrderStatus.pending),
      };

  String get key => switch (this) {
        OrderStatus.pickedUp => 'picked_up',
        OrderStatus.onTheWay => 'on_the_way',
        _ => name,
      };

  bool get isTerminal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.rejected;
}

class OrderItem {
  final String itemId;
  final String name;
  final int qty;
  final int unitPrice; // أغورة
  final int lineTotal;

  const OrderItem({
    required this.itemId, required this.name, required this.qty,
    required this.unitPrice, required this.lineTotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        itemId: m['itemId'] ?? '',
        name: m['name'] ?? '',
        qty: (m['qty'] ?? 1) as int,
        unitPrice: (m['unitPrice'] ?? 0) as int,
        lineTotal: (m['lineTotal'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'itemId': itemId, 'name': name, 'qty': qty,
        'unitPrice': unitPrice, 'lineTotal': lineTotal,
      };
}

class OrderPricing {
  final int subtotal, deliveryFee, serviceFee, discount, tip, total;
  const OrderPricing({
    this.subtotal = 0, this.deliveryFee = 0, this.serviceFee = 0,
    this.discount = 0, this.tip = 0, this.total = 0,
  });

  factory OrderPricing.fromMap(Map<String, dynamic>? m) => OrderPricing(
        subtotal: (m?['subtotal'] ?? 0) as int,
        deliveryFee: (m?['deliveryFee'] ?? 0) as int,
        serviceFee: (m?['serviceFee'] ?? 0) as int,
        discount: (m?['discount'] ?? 0) as int,
        tip: (m?['tip'] ?? 0) as int,
        total: (m?['total'] ?? 0) as int,
      );
}

class DyarOrder {
  final String id;
  final String code;
  final String customerUid;
  final String storeId;
  final String? driverUid;
  final List<OrderItem> items;
  final OrderStatus status;
  final String type; // delivery | pickup | dinein | service
  final OrderPricing pricing;
  final String paymentMethod;
  final String paymentStatus;
  final Map<String, dynamic>? address;
  final DateTime? createdAt;

  const DyarOrder({
    required this.id, required this.code, required this.customerUid,
    required this.storeId, this.driverUid, required this.items,
    required this.status, required this.type, required this.pricing,
    required this.paymentMethod, required this.paymentStatus,
    this.address, this.createdAt,
  });

  factory DyarOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return DyarOrder(
      id: doc.id,
      code: d['code'] ?? '',
      customerUid: d['customerUid'] ?? '',
      storeId: d['storeId'] ?? '',
      driverUid: d['driverUid'],
      items: ((d['items'] ?? []) as List)
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      status: OrderStatus.fromKey(d['status'] ?? 'pending'),
      type: d['type'] ?? 'delivery',
      pricing: OrderPricing.fromMap(
          d['pricing'] == null ? null : Map<String, dynamic>.from(d['pricing'])),
      paymentMethod: (d['payment']?['method'] ?? 'cash') as String,
      paymentStatus: (d['payment']?['status'] ?? 'pending') as String,
      address: d['address'] == null
          ? null
          : Map<String, dynamic>.from(d['address']),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
