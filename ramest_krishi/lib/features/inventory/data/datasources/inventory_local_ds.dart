import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../../../core/database/local_db.dart';
import '../../domain/entities/product_entity.dart';

class InventoryLocalDataSource {
  final LocalDatabase localDb;
  final _uuid = const Uuid();

  InventoryLocalDataSource(this.localDb);

  Future<List<Map<String, dynamic>>> getProducts({String? search}) async {
    final db = await localDb.database;
    if (search != null && search.isNotEmpty) {
      return await db.query(
        'products',
        where: 'deleted_at IS NULL AND (name LIKE ? OR barcode = ? OR company LIKE ?)',
        whereArgs: ['%$search%', search, '%$search%'],
        orderBy: 'name ASC',
      );
    }
    return await db.query('products', where: 'deleted_at IS NULL', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await localDb.database;
    final res = await db.query('products', where: 'barcode = ? AND deleted_at IS NULL', whereArgs: [barcode]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> insertProduct(Map<String, dynamic> productMap) async {
    final db = await localDb.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      productMap['created_at'] = now;
      productMap['updated_at'] = now;
      
      // 1. Insert into local products table
      await txn.insert('products', productMap);

      // 2. Queue for Sync
      await _queueSyncAction(txn, 'products', productMap['id'], 'INSERT', productMap);
    });
  }

  Future<void> updateProduct(Map<String, dynamic> productMap) async {
    final db = await localDb.database;
    await db.transaction((txn) async {
      productMap['updated_at'] = DateTime.now().toIso8601String();
      await txn.update('products', productMap, where: 'id = ?', whereArgs: [productMap['id']]);
      await _queueSyncAction(txn, 'products', productMap['id'], 'UPDATE', productMap);
    });
  }

  Future<void> softDeleteProduct(String id) async {
    final db = await localDb.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      await txn.update('products', {'deleted_at': now, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
      await _queueSyncAction(txn, 'products', id, 'DELETE', {'id': id, 'deleted_at': now});
    });
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
