import 'package:cloud_firestore/cloud_firestore.dart';

/// عرض سعر مورد على طلب RFQ — السعر والعمولة محسوبان خادميًا.
class RfqQuote {
  final int unitPrice; // أغورة/وحدة
  final int total; // أغورة
  final int commission; // عمولة ديار (أغورة)
  final num commissionPct;
  final String terms;
  final DateTime? validUntil;

  const RfqQuote({
    required this.unitPrice,
    required this.total,
    required this.commission,
    required this.commissionPct,
    this.terms = '',
    this.validUntil,
  });

  bool get isValid =>
      validUntil == null || validUntil!.isAfter(DateTime.now());

  factory RfqQuote.fromMap(Map<String, dynamic> m) => RfqQuote(
        unitPrice: (m['unitPrice'] ?? 0) as int,
        total: (m['total'] ?? 0) as int,
        commission: (m['commission'] ?? 0) as int,
        commissionPct: (m['commissionPct'] ?? 0) as num,
        terms: m['terms'] ?? '',
        validUntil: (m['validUntil'] as Timestamp?)?.toDate(),
      );
}

/// طلب عرض سعر B2B (RFQ): التاجر يطلب، المورد يردّ، التاجر يقبل/يرفض.
class Rfq {
  final String id;
  final String merchantUid;
  final String storeId;
  final String storeName;
  final String productName;
  final int qty;
  final String note;
  final String status; // open|quoted|accepted|declined|expired
  final RfqQuote? quote;
  final DateTime? createdAt;

  const Rfq({
    required this.id,
    required this.merchantUid,
    required this.storeId,
    required this.storeName,
    required this.productName,
    required this.qty,
    required this.status,
    this.note = '',
    this.quote,
    this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get isQuoted => status == 'quoted';
  bool get isAccepted => status == 'accepted';

  factory Rfq.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Rfq(
      id: doc.id,
      merchantUid: d['merchantUid'] ?? '',
      storeId: d['storeId'] ?? '',
      storeName: d['storeName'] ?? '',
      productName: d['productName'] ?? '',
      qty: (d['qty'] ?? 0) as int,
      note: d['note'] ?? '',
      status: d['status'] ?? 'open',
      quote: d['quote'] == null
          ? null
          : RfqQuote.fromMap(Map<String, dynamic>.from(d['quote'])),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
