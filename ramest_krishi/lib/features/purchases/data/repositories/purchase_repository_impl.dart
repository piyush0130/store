import '../../domain/repositories/purchase_repository.dart';
import '../../domain/entities/supplier_entity.dart';
import '../../domain/entities/purchase_entity.dart';
import '../datasources/purchase_local_ds.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseLocalDataSource localDataSource;

  PurchaseRepositoryImpl(this.localDataSource);

  @override
  Future<List<SupplierEntity>> getSuppliers() async {
    return await localDataSource.getSuppliers();
  }

  @override
  Future<void> addSupplier(SupplierEntity supplier) async {
    await localDataSource.addSupplier(supplier);
  }

  @override
  Future<void> recordPurchase({
    required String supplierId,
    required String invoiceNumber,
    required List<PurchaseItemEntity> items,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethod,
  }) async {
    await localDataSource.recordPurchase(
      supplierId: supplierId,
      invoiceNumber: invoiceNumber,
      items: items,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
    );
  }
}
