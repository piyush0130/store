import '../../domain/entities/supplier_entity.dart';
import '../../domain/entities/purchase_entity.dart';

abstract class PurchaseRepository {
  Future<List<SupplierEntity>> getSuppliers();
  Future<void> addSupplier(SupplierEntity supplier);
  Future<void> recordPurchase({
    required String supplierId,
    required String invoiceNumber,
    required List<PurchaseItemEntity> items,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethod,
  });
}
