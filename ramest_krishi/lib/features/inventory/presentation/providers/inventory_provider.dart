import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/datasources/inventory_local_ds.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../../../core/database/local_db.dart';

final inventoryLocalDsProvider = Provider((ref) {
  return InventoryLocalDataSource(LocalDatabase());
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(ref.watch(inventoryLocalDsProvider));
});

// Search Query State
final searchQueryProvider = StateProvider<String>((ref) => '');

// Notifier to fetch and stream products
class ProductsNotifier extends AutoDisposeAsyncNotifier<List<ProductEntity>> {
  @override
  Future<List<ProductEntity>> build() async {
    final search = ref.watch(searchQueryProvider);
    return ref.watch(inventoryRepositoryProvider).getProducts(searchQuery: search);
  }

  Future<void> addProduct(ProductEntity product) async {
    await ref.read(inventoryRepositoryProvider).addProduct(product);
    ref.invalidateSelf(); // Refresh list
  }
  
  Future<void> deleteProduct(String id) async {
    await ref.read(inventoryRepositoryProvider).deleteProduct(id);
    ref.invalidateSelf();
  }
}

final productsProvider = AsyncNotifierProvider.autoDispose<ProductsNotifier, List<ProductEntity>>(() {
  return ProductsNotifier();
});
