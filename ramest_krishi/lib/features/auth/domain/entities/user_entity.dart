class UserEntity {
  final String id;
  final String fullName;
  final String role; // 'admin', 'cashier', 'manager'
  final String? branchId;
  final String? phone;

  UserEntity({
    required this.id,
    required this.fullName,
    required this.role,
    this.branchId,
    this.phone,
  });

  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';
}
