class ProductEntity {
  final String id;
  final String branchId;
  final String? categoryId;
  final String name;
  final String? company;
  final String? barcode;
  final String? hsnCode;
  final double gstPercentage;
  final String? batchNumber;
  final String? expiryDate;
  final double mrp;
  final double purchasePrice;
  final double sellingPrice;
  final double stockQuantity;
  final String? imageLocalPath;
  final String? imageRemoteUrl;
  final bool isDeleted;

  ProductEntity({
    required this.id,
    required this.branchId,
    this.categoryId,
    required this.name,
    this.company,
    this.barcode,
    this.hsnCode,
    this.gstPercentage = 0.0,
    this.batchNumber,
    this.expiryDate,
    required this.mrp,
    required this.purchasePrice,
    required this.sellingPrice,
    this.stockQuantity = 0.0,
    this.imageLocalPath,
    this.imageRemoteUrl,
    this.isDeleted = false,
  });

  // Margin calculation helper
  double get profitMargin => sellingPrice - purchasePrice;
  double get profitMarginPercentage => purchasePrice > 0 ? (profitMargin / purchasePrice) * 100 : 100;
}
