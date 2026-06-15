import 'package:cloud_firestore/cloud_firestore.dart';

/// حساب وجبات الموظف (ديار Meals) — رصيد ممنوح من الشركة، use-it-or-lose-it.
class MealAccount {
  const MealAccount({
    required this.orgId, required this.balance, this.period = 'daily'});

  final String orgId;
  final int balance; // أغورة
  final String period; // 'daily' | 'monthly'

  bool get hasBudget => balance > 0;

  factory MealAccount.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return MealAccount(
      orgId: (d['orgId'] ?? '').toString(),
      balance: (d['balance'] ?? 0) as int,
      period: (d['period'] ?? 'daily').toString(),
    );
  }
}
