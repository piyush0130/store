class CustomerEntity {
  final String id;
  final String branchId;
  final String name;
  final String? village;
  final String? mobile;
  final String? gstNumber;
  final String? primaryCrop;
  final double? landArea;
  final double? creditLimit;
  final double dueAmount;
  final String? notes;
  final bool isDeleted;

  CustomerEntity({
    required this.id,
    required this.branchId,
    required this.name,
    this.village,
    this.mobile,
    this.gstNumber,
    this.primaryCrop,
    this.landArea,
    this.creditLimit,
    this.dueAmount = 0.0,
    this.notes,
    this.isDeleted = false,
  });
}
