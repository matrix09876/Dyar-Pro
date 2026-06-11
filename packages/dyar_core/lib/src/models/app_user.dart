import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, driver, partner, staff, admin }

class AppUser {
  final String uid;
  final UserRole role;
  final String? name, phone, email, photoUrl;
  final int walletBalance; // أغورة
  final List<String> allergies;
  final List<Map<String, dynamic>> addresses;
  final bool blocked;

  /// حساب تاجر B2B — تفعّله الإدارة من اللوحة، يُظهر فئة تجار الجملة.
  final bool merchant;

  const AppUser({
    required this.uid,
    this.role = UserRole.customer,
    this.name, this.phone, this.email, this.photoUrl,
    this.walletBalance = 0,
    this.allergies = const [],
    this.addresses = const [],
    this.blocked = false,
    this.merchant = false,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      role: UserRole.values.firstWhere(
          (r) => r.name == (d['role'] ?? 'customer'),
          orElse: () => UserRole.customer),
      name: d['name'],
      phone: d['phone'],
      email: d['email'],
      photoUrl: d['photoUrl'],
      walletBalance: (d['walletBalance'] ?? 0) as int,
      allergies: List<String>.from(d['allergies'] ?? const []),
      addresses: List<Map<String, dynamic>>.from(
          (d['addresses'] ?? const []).map((e) => Map<String, dynamic>.from(e))),
      blocked: d['status'] == 'blocked',
      merchant: d['merchant'] == true,
    );
  }
}
