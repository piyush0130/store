class SupplierEntity {
  final String id;
  final String name;
  final String? companyName;
  final String? gstNumber;
  final String? mobile;
  final double dueAmount;

  SupplierEntity({
    required this.id,
    required this.name,
    this.companyName,
    this.gstNumber,
    this.mobile,
    this.dueAmount = 0.0,
  });

  factory SupplierEntity.fromMap(Map<String, dynamic> map) {
    return SupplierEntity(
      id: map['id'],
      name: map['name'],
      companyName: map['company_name'],
      gstNumber: map['gst_number'],
      mobile: map['mobile'],
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company_name': companyName,
      'gst_number': gstNumber,
      'mobile': mobile,
      'due_amount': dueAmount,
    };
  }
}
