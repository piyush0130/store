import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/datasources/customer_local_ds.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../../../core/database/local_db.dart';

final customerLocalDsProvider = Provider((ref) {
  return CustomerLocalDataSource(LocalDatabase());
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(ref.watch(customerLocalDsProvider));
});

// Search Query State
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

// Notifier to fetch and stream customers
class CustomersNotifier extends AutoDisposeAsyncNotifier<List<CustomerEntity>> {
  @override
  Future<List<CustomerEntity>> build() async {
    final search = ref.watch(customerSearchQueryProvider);
    return ref.watch(customerRepositoryProvider).getCustomers(searchQuery: search);
  }

  Future<void> addCustomer(CustomerEntity customer) async {
    await ref.read(customerRepositoryProvider).addCustomer(customer);
    ref.invalidateSelf(); // Refresh list
  }
  
  Future<void> updateCustomer(CustomerEntity customer) async {
    await ref.read(customerRepositoryProvider).updateCustomer(customer);
    ref.invalidateSelf();
  }

  Future<void> deleteCustomer(String id) async {
    await ref.read(customerRepositoryProvider).deleteCustomer(id);
    ref.invalidateSelf();
  }
}

final customersProvider = AsyncNotifierProvider.autoDispose<CustomersNotifier, List<CustomerEntity>>(() {
  return CustomersNotifier();
});

// Provides ledger for a specific customer
final customerLedgerProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async {
  final repo = ref.watch(customerRepositoryProvider);
  return await repo.getCustomerLedger(customerId);
});
