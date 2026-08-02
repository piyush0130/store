import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_ds.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource localDataSource;

  InventoryRepositoryImpl(this.localDataSource);

  @override
  Future<List<ProductEntity>> getProducts({String? searchQuery, String? categoryId}) async {
    final maps = await localDataSource.getProducts(search: searchQuery);
    return maps.map((m) => _mapToEntity(m)).toList();
  }

  @override
  Future<ProductEntity?> getProductByBarcode(String barcode) async {
    final map = await localDataSource.getProductByBarcode(barcode);
    if (map != null) return _mapToEntity(map);
    return null;
  }

  @override
  Future<void> addProduct(ProductEntity product) async {
    await localDataSource.insertProduct(_mapToModel(product));
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    await localDataSource.updateProduct(_mapToModel(product));
  }

  @override
  Future<void> deleteProduct(String id) async {
    await localDataSource.softDeleteProduct(id);
  }

  ProductEntity _mapToEntity(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'],
      branchId: map['branch_id'],
      categoryId: map['category_id'],
      name: map['name'],
      company: map['company'],
      barcode: map['barcode'],
      hsnCode: map['hsn_code'],
      gstPercentage: (map['gst_percentage'] as num?)?.toDouble() ?? 0.0,
      batchNumber: map['batch_number'],
      expiryDate: map['expiry_date'],
      mrp: (map['mrp'] as num).toDouble(),
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      imageLocalPath: map['image_local_path'],
      imageRemoteUrl: map['image_remote_url'],
    );
  }

  Map<String, dynamic> _mapToModel(ProductEntity entity) {
    return {
      'id': entity.id,
      'branch_id': entity.branchId,
      'category_id': entity.categoryId,
      'name': entity.name,
      'company': entity.company,
      'barcode': entity.barcode,
      'hsn_code': entity.hsnCode,
      'gst_percentage': entity.gstPercentage,
      'batch_number': entity.batchNumber,
      'expiry_date': entity.expiryDate,
      'mrp': entity.mrp,
      'purchase_price': entity.purchasePrice,
      'selling_price': entity.sellingPrice,
      'stock_quantity': entity.stockQuantity,
      'image_local_path': entity.imageLocalPath,
      'image_remote_url': entity.imageRemoteUrl,
    };
  }
}
