import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../data/datasources/billing_local_ds.dart';
import '../../data/repositories/billing_repository_impl.dart';
import '../../../../core/database/local_db.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../../customers/domain/entities/customer_entity.dart';

final billingLocalDsProvider = Provider((ref) => BillingLocalDataSource(LocalDatabase()));

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl(ref.watch(billingLocalDsProvider));
});

// State classes
class CartState {
  final List<CartItemEntity> items;
  final CustomerEntity? selectedCustomer;
  final double globalDiscount;

  CartState({this.items = const [], this.selectedCustomer, this.globalDiscount = 0.0});

  CartState copyWith({List<CartItemEntity>? items, CustomerEntity? selectedCustomer, double? globalDiscount}) {
    return CartState(
      items: items ?? this.items,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      globalDiscount: globalDiscount ?? this.globalDiscount,
    );
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalGst => items.fold(0, (sum, item) => sum + item.gstAmount);
  double get grandTotal => subtotal - globalDiscount;
}

class CartNotifier extends StateNotifier<CartState> {
  final BillingRepository repository;

  CartNotifier(this.repository) : super(CartState());

  void addProduct(ProductEntity product) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final updatedItems = List<CartItemEntity>.from(state.items);
      updatedItems[existingIndex].quantity += 1;
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItemEntity(product: product)]);
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeProduct(productId);
      return;
    }
    final updatedItems = state.items.map((i) {
      if (i.product.id == productId) i.quantity = newQuantity;
      return i;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateCustomPrice(String productId, double price) {
    final updatedItems = state.items.map((i) {
      if (i.product.id == productId) i.customPrice = price;
      return i;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  void removeProduct(String productId) {
    state = state.copyWith(items: state.items.where((i) => i.product.id != productId).toList());
  }

  void setCustomer(CustomerEntity? customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void setGlobalDiscount(double discount) {
    state = state.copyWith(globalDiscount: discount);
  }

  void clearCart() {
    state = CartState();
  }

  Future<String> checkout({required String paymentMethod, required double amountPaid}) async {
    if (state.items.isEmpty) throw Exception("Cart is empty");
    
    // Khata validation
    if (paymentMethod == 'khata' && state.selectedCustomer == null) {
      throw Exception("Please select a farmer for Khata billing.");
    }

    final saleId = await repository.checkout(
      customerId: state.selectedCustomer?.id,
      cartItems: state.items,
      paymentMethod: paymentMethod,
      globalDiscount: state.globalDiscount,
      amountPaid: amountPaid,
    );
    return saleId;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.watch(billingRepositoryProvider));
});
