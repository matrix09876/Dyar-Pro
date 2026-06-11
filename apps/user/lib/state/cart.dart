import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';

/// سلة التسوق — متجر واحد لكل سلة (نمط Wolt/HAAT).
class CartLine {
  final MenuItem item;
  final int qty;
  const CartLine(this.item, this.qty);
  int get lineTotal => item.price * qty;
}

class CartState {
  final String? storeId;
  final Map<String, CartLine> lines;
  const CartState({this.storeId, this.lines = const {}});

  int get subtotal =>
      lines.values.fold(0, (sum, l) => sum + l.lineTotal);
  int get count => lines.values.fold(0, (sum, l) => sum + l.qty);
  bool get isEmpty => lines.isEmpty;
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// إضافة صنف — تبديل المتجر يفرغ السلة (مع تنبيه في الواجهة).
  void add(String storeId, MenuItem item) {
    final sameStore = state.storeId == null || state.storeId == storeId;
    final lines = sameStore
        ? Map<String, CartLine>.from(state.lines)
        : <String, CartLine>{};
    final existing = lines[item.id];
    lines[item.id] = CartLine(item, (existing?.qty ?? 0) + 1);
    state = CartState(storeId: storeId, lines: lines);
  }

  void remove(MenuItem item) {
    final lines = Map<String, CartLine>.from(state.lines);
    final existing = lines[item.id];
    if (existing == null) return;
    if (existing.qty <= 1) {
      lines.remove(item.id);
    } else {
      lines[item.id] = CartLine(item, existing.qty - 1);
    }
    state = CartState(
        storeId: lines.isEmpty ? null : state.storeId, lines: lines);
  }

  void clear() => state = const CartState();

  List<Map<String, dynamic>> toOrderItems() => state.lines.values
      .map((l) => {'itemId': l.item.id, 'qty': l.qty, 'options': []})
      .toList();
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
