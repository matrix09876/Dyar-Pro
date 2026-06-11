import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';

/// سلة التسوق — متجر واحد لكل سلة (نمط Wolt/HAAT)،
/// مع دعم خيارات الصنف (إضافات/أحجام) لكل سطر.
class CartLine {
  final MenuItem item;
  final int qty;
  final List<Map<String, dynamic>> options; // [{name, price}]
  const CartLine(this.item, this.qty, [this.options = const []]);

  int get optionsTotal =>
      options.fold(0, (s, o) => s + ((o['price'] ?? 0) as int));
  int get unitTotal => item.price + optionsTotal;
  int get lineTotal => unitTotal * qty;

  /// مفتاح السطر: نفس الصنف بخيارات مختلفة = سطر مستقل
  String get key =>
      '${item.id}|${options.map((o) => o['name']).join('+')}';
}

class CartState {
  final String? storeId;
  final Map<String, CartLine> lines;
  const CartState({this.storeId, this.lines = const {}});

  int get subtotal => lines.values.fold(0, (sum, l) => sum + l.lineTotal);
  int get count => lines.values.fold(0, (sum, l) => sum + l.qty);
  bool get isEmpty => lines.isEmpty;

  /// كمية صنف عبر كل سطوره (لعدّاد البطاقة)
  int qtyOf(String itemId) => lines.values
      .where((l) => l.item.id == itemId)
      .fold(0, (s, l) => s + l.qty);
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// إضافة صنف (بخياراته) — تبديل المتجر يفرغ السلة.
  void add(String storeId, MenuItem item,
      {List<Map<String, dynamic>> options = const [], int qty = 1}) {
    final sameStore = state.storeId == null || state.storeId == storeId;
    final lines = sameStore
        ? Map<String, CartLine>.from(state.lines)
        : <String, CartLine>{};
    final line = CartLine(item, qty, options);
    final existing = lines[line.key];
    lines[line.key] =
        CartLine(item, (existing?.qty ?? 0) + qty, options);
    state = CartState(storeId: storeId, lines: lines);
  }

  /// إنقاص آخر سطر لهذا الصنف (من عدّاد البطاقة)
  void removeOne(String itemId) {
    final lines = Map<String, CartLine>.from(state.lines);
    final key = lines.values
        .where((l) => l.item.id == itemId)
        .map((l) => l.key)
        .lastOrNull;
    if (key == null) return;
    final existing = lines[key]!;
    if (existing.qty <= 1) {
      lines.remove(key);
    } else {
      lines[key] = CartLine(existing.item, existing.qty - 1, existing.options);
    }
    state = CartState(
        storeId: lines.isEmpty ? null : state.storeId, lines: lines);
  }

  void removeLine(String key) {
    final lines = Map<String, CartLine>.from(state.lines)..remove(key);
    state = CartState(
        storeId: lines.isEmpty ? null : state.storeId, lines: lines);
  }

  void clear() => state = const CartState();

  List<Map<String, dynamic>> toOrderItems() => state.lines.values
      .map((l) =>
          {'itemId': l.item.id, 'qty': l.qty, 'options': l.options})
      .toList();
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
