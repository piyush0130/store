import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<List<CustomerEntity>> getCustomers({String? searchQuery});
  Future<CustomerEntity?> getCustomerById(String id);
  Future<void> addCustomer(CustomerEntity customer);
  Future<void> updateCustomer(CustomerEntity customer);
  Future<void> deleteCustomer(String id);
  
  // Ledger / Khata methods (queries against sales/payments tables)
  Future<List<Map<String, dynamic>>> getCustomerLedger(String customerId);
}
