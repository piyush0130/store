import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../../../core/database/local_db.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerLocalDataSource {
  final LocalDatabase localDb;
  final _uuid = const Uuid();

  CustomerLocalDataSource(this.localDb);

  Future<List<Map<String, dynamic>>> getCustomers({String? search}) async {
    final db = await localDb.database;
    if (search != null && search.isNotEmpty) {
      return await db.query(
        'customers',
        where: 'deleted_at IS NULL AND (name LIKE ? OR mobile LIKE ? OR village LIKE ?)',
        whereArgs: ['%$search%', '%$search%', '%$search%'],
        orderBy: 'name ASC',
      );
    }
    return await db.query('customers', where: 'deleted_at IS NULL', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    final db = await localDb.database;
    final res = await db.query('customers', where: 'id = ? AND deleted_at IS NULL', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> insertCustomer(Map<String, dynamic> data) async {
    final db = await localDb.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      data['created_at'] = now;
      data['updated_at'] = now;
      
      await txn.insert('customers', data);
      await _queueSyncAction(txn, 'customers', data['id'], 'INSERT', data);
    });
  }

  Future<void> updateCustomer(Map<String, dynamic> data) async {
    final db = await localDb.database;
    await db.transaction((txn) async {
      data['updated_at'] = DateTime.now().toIso8601String();
      await txn.update('customers', data, where: 'id = ?', whereArgs: [data['id']]);
      await _queueSyncAction(txn, 'customers', data['id'], 'UPDATE', data);
    });
  }

  Future<void> softDeleteCustomer(String id) async {
    final db = await localDb.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      await txn.update('customers', {'deleted_at': now, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
      await _queueSyncAction(txn, 'customers', id, 'DELETE', {'id': id, 'deleted_at': now});
    });
  }

  // Generates the Ledger by combining sales (purchases) and payments
  Future<List<Map<String, dynamic>>> getCustomerLedger(String customerId) async {
    final db = await localDb.database;
    
    // We query sales where this customer is involved.
    // In a complete ERP, there would also be a `payments` table for when they pay off debt.
    // For now, we assume sales with 'khata' payment method are debits, others are cash.
    final sales = await db.query(
      'sales',
      where: 'customer_id = ? AND deleted_at IS NULL',
      whereArgs: [customerId],
      orderBy: 'sale_date DESC',
    );
    
    return sales;
  }

  Future<void> _queueSyncAction(Transaction txn, String tableName, String recordId, String action, Map<String, dynamic> payload) async {
    await txn.insert('sync_queue', {
      'id': _uuid.v4(),
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
