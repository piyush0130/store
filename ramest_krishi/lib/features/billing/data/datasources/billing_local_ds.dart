import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../../../core/database/local_db.dart';
import '../../domain/entities/cart_item_entity.dart';

class BillingLocalDataSource {
  final LocalDatabase localDb;
  final _uuid = const Uuid();

  BillingLocalDataSource(this.localDb);

  Future<String> processCheckout({
    required String? customerId,
    required List<CartItemEntity> items,
    required String paymentMethod,
    required double discount,
    required double amountPaid,
  }) async {
    final db = await localDb.database;
    final saleId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      double totalSubtotal = 0;
      double totalGst = 0;

      for (var item in items) {
        totalSubtotal += item.subtotal;
        totalGst += item.gstAmount;
      }

      final grandTotal = totalSubtotal - discount;

      // 1. Insert Sale
      final saleMap = {
        'id': saleId,
        'branch_id': 'current-branch-id',
        'customer_id': customerId,
        'sale_date': now,
        'total_amount': grandTotal,
        'sub_total': totalSubtotal,
        'gst_total': totalGst,
        'discount': discount,
        'payment_method': paymentMethod,
        'paid_amount': amountPaid,
        'created_at': now,
        'updated_at': now,
      };
      await txn.insert('sales', saleMap);
      await _queueSync(txn, 'sales', saleId, 'INSERT', saleMap);

      // 2. Insert Sale Items & Deduct Stock
      for (var item in items) {
        final saleItemId = _uuid.v4();
        final saleItemMap = {
          'id': saleItemId,
          'sale_id': saleId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.customPrice,
          'sub_total': item.subtotal,
          'gst_amount': item.gstAmount,
          'created_at': now,
          'updated_at': now,
        };
        await txn.insert('sale_items', saleItemMap);
        await _queueSync(txn, 'sale_items', saleItemId, 'INSERT', saleItemMap);

        // Deduct Stock
        final newStock = item.product.stockQuantity - item.quantity;
        await txn.update(
          'products',
          {'stock_quantity': newStock, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [item.product.id],
        );
        // Queue stock update
        await _queueSync(txn, 'products', item.product.id, 'UPDATE', {
          'id': item.product.id,
          'stock_quantity': newStock,
          'updated_at': now,
        });
      }

      // 3. Khata logic (if customer is attached and they didn't pay full amount)
      if (customerId != null) {
        final amountDueForThisBill = grandTotal - amountPaid;
        if (amountDueForThisBill != 0) {
          // Fetch current due
          final res = await txn.query('customers', columns: ['due_amount'], where: 'id = ?', whereArgs: [customerId]);
          if (res.isNotEmpty) {
            final currentDue = (res.first['due_amount'] as num?)?.toDouble() ?? 0.0;
            final newDue = currentDue + amountDueForThisBill;
            
            await txn.update(
              'customers',
              {'due_amount': newDue, 'updated_at': now},
              where: 'id = ?',
              whereArgs: [customerId],
            );
            await _queueSync(txn, 'customers', customerId, 'UPDATE', {
              'id': customerId,
              'due_amount': newDue,
              'updated_at': now,
            });
          }
        }
      }
    });

    return saleId;
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
