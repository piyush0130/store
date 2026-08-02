import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_local_ds.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource localDataSource;

  CustomerRepositoryImpl(this.localDataSource);

  @override
  Future<List<CustomerEntity>> getCustomers({String? searchQuery}) async {
    final maps = await localDataSource.getCustomers(search: searchQuery);
    return maps.map((m) => _mapToEntity(m)).toList();
  }

  @override
  Future<CustomerEntity?> getCustomerById(String id) async {
    final map = await localDataSource.getCustomerById(id);
    if (map != null) return _mapToEntity(map);
    return null;
  }

  @override
  Future<void> addCustomer(CustomerEntity customer) async {
    await localDataSource.insertCustomer(_mapToModel(customer));
  }

  @override
  Future<void> updateCustomer(CustomerEntity customer) async {
    await localDataSource.updateCustomer(_mapToModel(customer));
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await localDataSource.softDeleteCustomer(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerLedger(String customerId) async {
    return await localDataSource.getCustomerLedger(customerId);
  }

  CustomerEntity _mapToEntity(Map<String, dynamic> map) {
    return CustomerEntity(
      id: map['id'],
      branchId: map['branch_id'],
      name: map['name'],
      village: map['village'],
      mobile: map['mobile'],
      gstNumber: map['gst_number'],
      primaryCrop: map['primary_crop'],
      landArea: (map['land_area'] as num?)?.toDouble(),
      creditLimit: (map['credit_limit'] as num?)?.toDouble(),
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> _mapToModel(CustomerEntity entity) {
    return {
      'id': entity.id,
      'branch_id': entity.branchId,
      'name': entity.name,
      'village': entity.village,
      'mobile': entity.mobile,
      'gst_number': entity.gstNumber,
      'primary_crop': entity.primaryCrop,
      'land_area': entity.landArea,
      'credit_limit': entity.creditLimit,
      'due_amount': entity.dueAmount,
      'notes': entity.notes,
    };
  }
}
