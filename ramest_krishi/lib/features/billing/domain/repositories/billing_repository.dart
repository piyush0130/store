import '../entities/cart_item_entity.dart';

abstract class BillingRepository {
  Future<String> checkout({
    required String? customerId,
    required List<CartItemEntity> cartItems,
    required String paymentMethod,
    required double globalDiscount,
    required double amountPaid,
  });
}
