import '../entities/product_entity.dart';

abstract class InventoryRepository {
  Future<List<ProductEntity>> getProducts({String? searchQuery, String? categoryId});
  Future<ProductEntity?> getProductByBarcode(String barcode);
  Future<void> addProduct(ProductEntity product);
  Future<void> updateProduct(ProductEntity product);
  Future<void> deleteProduct(String id);
}
