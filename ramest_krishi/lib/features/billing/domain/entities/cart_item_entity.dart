import '../../inventory/domain/entities/product_entity.dart';

class CartItemEntity {
  final ProductEntity product;
  int quantity;
  double customPrice;
  double discountAmount;

  CartItemEntity({
    required this.product,
    this.quantity = 1,
    double? customPrice,
    this.discountAmount = 0.0,
  }) : customPrice = customPrice ?? product.sellingPrice;

  double get subtotal => (customPrice * quantity) - discountAmount;
  
  // Backing out GST from inclusive price (assumes sellingPrice is GST inclusive)
  double get gstAmount {
    if (product.gstPercentage <= 0) return 0;
    // Price = Base + (Base * GST%) => Base = Price / (1 + GST%)
    final basePrice = subtotal / (1 + (product.gstPercentage / 100));
    return subtotal - basePrice;
  }
}
