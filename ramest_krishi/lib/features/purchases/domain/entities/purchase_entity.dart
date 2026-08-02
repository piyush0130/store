import '../../../inventory/domain/entities/product_entity.dart';

class PurchaseItemEntity {
  final ProductEntity product;
  final double quantity;
  final double unitPrice;
  final String? batchNumber;
  final String? expiryDate;

  PurchaseItemEntity({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.batchNumber,
    this.expiryDate,
  });

  double get subtotal => quantity * unitPrice;
}
