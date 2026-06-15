import 'package:cloud_firestore/cloud_firestore.dart';

/// منتج سوق C2C (بيع وشراء) — المستخدم يرفعه والإدارة توافق.
class MarketProduct {
  final String id;
  final String sellerUid;
  final String title;
  final String description;
  final int price; // أغورة
  final String imageUrl;
  final String category; // electronics|fashion|home|cars|other
  final String city;
  final String status; // pending|approved|rejected|sold
  final DateTime? createdAt;

  const MarketProduct({
    required this.id,
    required this.sellerUid,
    this.title = '',
    this.description = '',
    this.price = 0,
    this.imageUrl = '',
    this.category = 'other',
    this.city = '',
    this.status = 'pending',
    this.createdAt,
  });

  factory MarketProduct.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return MarketProduct(
      id: doc.id,
      sellerUid: d['sellerUid'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      price: (d['price'] ?? 0) as int,
      imageUrl: d['imageUrl'] ?? '',
      category: d['category'] ?? 'other',
      city: d['city'] ?? '',
      status: d['status'] ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
