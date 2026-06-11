import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String ownerUid;
  final String name;
  final String type; // restaurant|grocery|pharmacy|flowers|service|store
  final String? logoUrl, coverUrl, description;
  final bool isOpen;
  final String status; // pending|approved|suspended
  final double rating;
  final int ratingCount;
  final int deliveryFee, minOrder; // أغورة
  final int prepTimeMins;
  final Map<String, dynamic>? location;

  const Store({
    required this.id, required this.ownerUid, required this.name,
    required this.type, this.logoUrl, this.coverUrl, this.description,
    this.isOpen = false, this.status = 'pending',
    this.rating = 0, this.ratingCount = 0,
    this.deliveryFee = 0, this.minOrder = 0, this.prepTimeMins = 20,
    this.location,
  });

  factory Store.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Store(
      id: doc.id,
      ownerUid: d['ownerUid'] ?? '',
      name: d['name'] ?? '',
      type: d['type'] ?? 'store',
      logoUrl: d['logoUrl'],
      coverUrl: d['coverUrl'],
      description: d['description'],
      isOpen: d['isOpen'] ?? false,
      status: d['status'] ?? 'pending',
      rating: ((d['rating'] ?? 0) as num).toDouble(),
      ratingCount: (d['ratingCount'] ?? 0) as int,
      deliveryFee: (d['deliveryFee'] ?? 0) as int,
      minOrder: (d['minOrder'] ?? 0) as int,
      prepTimeMins: (d['prepTimeMins'] ?? 20) as int,
      location: d['location'] == null
          ? null
          : Map<String, dynamic>.from(d['location']),
    );
  }
}
