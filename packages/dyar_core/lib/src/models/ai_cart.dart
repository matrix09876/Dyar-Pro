/// نتيجة المساعد الذكي (aiBuildCart): متجر واحد + أصناف مُتحقَّقة بأسعار حقيقية
/// + شرح سبب الاختيار. كل المبالغ بالأغورة.
class AiCartItem {
  final String itemId;
  final String name;
  final int price; // أغورة
  final int qty;
  final int lineTotal;

  const AiCartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.qty,
    required this.lineTotal,
  });

  factory AiCartItem.fromMap(Map<String, dynamic> m) => AiCartItem(
        itemId: m['itemId'] ?? '',
        name: m['name'] ?? '',
        price: (m['price'] ?? 0) as int,
        qty: (m['qty'] ?? 1) as int,
        lineTotal: (m['lineTotal'] ?? 0) as int,
      );
}

class AiCartSuggestion {
  final bool usedAi; // هل استُخدم Claude أم الاحتياطي الحسابي؟
  final bool overBudget;
  final String storeId;
  final String storeName;
  final String storeType;
  final String explanation;
  final int deliveryFee;
  final int subtotal;
  final int estimatedTotal;
  final List<AiCartItem> items;

  const AiCartSuggestion({
    required this.usedAi,
    required this.overBudget,
    required this.storeId,
    required this.storeName,
    required this.storeType,
    required this.explanation,
    required this.deliveryFee,
    required this.subtotal,
    required this.estimatedTotal,
    required this.items,
  });

  factory AiCartSuggestion.fromMap(Map<String, dynamic> m) => AiCartSuggestion(
        usedAi: m['usedAi'] == true,
        overBudget: m['overBudget'] == true,
        storeId: m['storeId'] ?? '',
        storeName: m['storeName'] ?? '',
        storeType: m['storeType'] ?? 'store',
        explanation: m['explanation'] ?? '',
        deliveryFee: (m['deliveryFee'] ?? 0) as int,
        subtotal: (m['subtotal'] ?? 0) as int,
        estimatedTotal: (m['estimatedTotal'] ?? 0) as int,
        items: ((m['items'] ?? const []) as List)
            .map((e) => AiCartItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
