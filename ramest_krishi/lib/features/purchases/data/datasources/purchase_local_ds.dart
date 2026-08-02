import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../../../core/database/local_db.dart';
import '../../domain/entities/supplier_entity.dart';
import '../../domain/entities/purchase_entity.dart';

class PurchaseLocalDataSource {
  final LocalDatabase localDb;
  final _uuid = const Uuid();

  PurchaseLocalDataSource(this.localDb);

  Future<List<SupplierEntity>> getSuppliers() async {
    final db = await localDb.database;
    final res = await db.query('suppliers', where: 'deleted_at IS NULL', orderBy: 'name ASC');
    return res.map((m) => SupplierEntity.fromMap(m)).toList();
  }

  Future<void> addSupplier(SupplierEntity supplier) async {
    final db = await localDb.database;
    final now = DateTime.now().toIso8601String();
    final map = supplier.toMap();
    map['branch_id'] = 'current-branch-id';
    map['created_at'] = now;
    map['updated_at'] = now;

    await db.transaction((txn) async {
      await txn.insert('suppliers', map, conflictAlgorithm: ConflictAlgorithm.replace);
      await _queueSync(txn, 'suppliers', supplier.id, 'INSERT', map);
    });
  }

  Future<void> recordPurchase({
    required String supplierId,
    required String invoiceNumber,
    required List<PurchaseItemEntity> items,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethod,
  }) async {
    final db = await localDb.database;
    final purchaseId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Insert Purchase
      final purchaseMap = {
        'id': purchaseId,
        'branch_id': 'current-branch-id',
        'supplier_id': supplierId,
        'invoice_number': invoiceNumber,
        'purchase_date': now,
        'type': 'INVOICE',
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'payment_method': paymentMethod,
        'created_at': now,
        'updated_at': now,
      };
      await txn.insert('purchases', purchaseMap);
      await _queueSync(txn, 'purchases', purchaseId, 'INSERT', purchaseMap);

      // 2. Insert Items & Update Products (Stock + Batch/Expiry)
      for (var item in items) {
        final itemId = _uuid.v4();
        final itemMap = {
          'id': itemId,
          'purchase_id': purchaseId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'batch_number': item.batchNumber,
          'expiry_date': item.expiryDate,
          'created_at': now,
          'updated_at': now,
        };
        await txn.insert('purchase_items', itemMap);
        await _queueSync(txn, 'purchase_items', itemId, 'INSERT', itemMap);

        // Update Product Stock and Overwrite Batch info
        final newStock = item.product.stockQuantity + item.quantity.toInt();
        final productUpdate = {
          'stock_quantity': newStock,
          'purchase_price': item.unitPrice, // Update the moving average or latest purchase price
          if (item.batchNumber != null) 'batch_number': item.batchNumber,
          if (item.expiryDate != null) 'expiry_date': item.expiryDate,
          'updated_at': now,
        };

        await txn.update(
          'products',
          productUpdate,
          where: 'id = ?',
          whereArgs: [item.product.id],
        );
        
        // Sync queue for product update requires the full ID
        productUpdate['id'] = item.product.id;
        await _queueSync(txn, 'products', item.product.id, 'UPDATE', productUpdate);
      }

      // 3. Update Supplier Khata (If paid < total)
      final amountDueForThisInvoice = totalAmount - paidAmount;
      if (amountDueForThisInvoice != 0) {
        final res = await txn.query('suppliers', columns: ['due_amount'], where: 'id = ?', whereArgs: [supplierId]);
        if (res.isNotEmpty) {
          final currentDue = (res.first['due_amount'] as num?)?.toDouble() ?? 0.0;
          final newDue = currentDue + amountDueForThisInvoice;
          
          await txn.update(
            'suppliers',
            {'due_amount': newDue, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [supplierId],
          );
          await _queueSync(txn, 'suppliers', supplierId, 'UPDATE', {
            'id': supplierId,
            'due_amount': newDue,
            'updated_at': now,
          });
        }
      }
    });
  }

  Future<void> _queueSync(Transaction txn, String tableName, String recordId, String action, Map<String, dynamic> payload) async {
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
