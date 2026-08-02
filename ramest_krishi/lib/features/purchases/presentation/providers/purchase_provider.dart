import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/supplier_entity.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../data/datasources/purchase_local_ds.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../../../core/database/local_db.dart';

final purchaseLocalDsProvider = Provider((ref) => PurchaseLocalDataSource(LocalDatabase()));

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepositoryImpl(ref.watch(purchaseLocalDsProvider));
});

final suppliersProvider = FutureProvider<List<SupplierEntity>>((ref) async {
  return ref.watch(purchaseRepositoryProvider).getSuppliers();
});

class PurchaseEntryNotifier extends StateNotifier<List<PurchaseItemEntity>> {
  final PurchaseRepository repo;
  
  PurchaseEntryNotifier(this.repo) : super([]);

  void addItem(PurchaseItemEntity item) {
    state = [...state, item];
  }

  void removeItem(int index) {
    final newList = List<PurchaseItemEntity>.from(state);
    newList.removeAt(index);
    state = newList;
  }

  double get totalAmount => state.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> submitPurchase({
    required String supplierId,
    required String invoiceNumber,
    required double paidAmount,
    required String paymentMethod,
  }) async {
    if (state.isEmpty) throw Exception("No items in purchase invoice.");
    
    await repo.recordPurchase(
      supplierId: supplierId,
      invoiceNumber: invoiceNumber,
      items: state,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
    );
    
    // Clear state after success
    state = [];
  }
}

final purchaseEntryProvider = StateNotifierProvider<PurchaseEntryNotifier, List<PurchaseItemEntity>>((ref) {
  return PurchaseEntryNotifier(ref.watch(purchaseRepositoryProvider));
});
