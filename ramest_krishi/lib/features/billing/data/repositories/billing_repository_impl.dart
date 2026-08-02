import '../../domain/repositories/billing_repository.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../datasources/billing_local_ds.dart';

class BillingRepositoryImpl implements BillingRepository {
  final BillingLocalDataSource localDataSource;

  BillingRepositoryImpl(this.localDataSource);

  @override
  Future<String> checkout({
    required String? customerId,
    required List<CartItemEntity> cartItems,
    required String paymentMethod,
    required double globalDiscount,
    required double amountPaid,
  }) async {
    return await localDataSource.processCheckout(
      customerId: customerId,
      items: cartItems,
      paymentMethod: paymentMethod,
      discount: globalDiscount,
      amountPaid: amountPaid,
    );
  }
}
