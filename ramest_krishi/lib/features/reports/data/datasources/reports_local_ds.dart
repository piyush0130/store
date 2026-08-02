import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_db.dart';

class ReportsLocalDataSource {
  final LocalDatabase localDb;
  
  ReportsLocalDataSource(this.localDb);

  Future<List<Map<String, dynamic>>> getSalesReport(String startDate, String endDate) async {
    final db = await localDb.database;
    // Returns daily sales grouped by date
    return await db.rawQuery('''
      SELECT 
        date(sale_date) as date,
        COUNT(id) as total_invoices,
        SUM(total_amount) as total_sales,
        SUM(gst_total) as total_gst,
        SUM(discount) as total_discount,
        SUM(paid_amount) as amount_received
      FROM sales
      WHERE sale_date >= ? AND sale_date <= ?
      GROUP BY date(sale_date)
      ORDER BY date(sale_date) DESC
    ''', [startDate, endDate]);
  }

  Future<List<Map<String, dynamic>>> getPurchaseReport(String startDate, String endDate) async {
    final db = await localDb.database;
    return await db.rawQuery('''
      SELECT 
        date(purchase_date) as date,
        COUNT(id) as total_invoices,
        SUM(total_amount) as total_purchases,
        SUM(paid_amount) as amount_paid
      FROM purchases
      WHERE purchase_date >= ? AND purchase_date <= ?
      GROUP BY date(purchase_date)
      ORDER BY date(purchase_date) DESC
    ''', [startDate, endDate]);
  }

  Future<List<Map<String, dynamic>>> getGstReport(String startDate, String endDate) async {
    final db = await localDb.database;
    // GST Collected (Sales) vs GST Paid (Purchases)
    final salesGst = await db.rawQuery('''
      SELECT 'Sales (Collected)' as type, SUM(gst_total) as amount 
      FROM sales 
      WHERE sale_date >= ? AND sale_date <= ?
    ''', [startDate, endDate]);
    
    final purchaseGst = await db.rawQuery('''
      SELECT 'Purchases (Paid)' as type, SUM(gst_total) as amount 
      FROM purchases 
      WHERE purchase_date >= ? AND purchase_date <= ?
    ''', [startDate, endDate]);

    return [
      if (salesGst.isNotEmpty) salesGst.first,
      if (purchaseGst.isNotEmpty) purchaseGst.first,
    ];
  }

  Future<List<Map<String, dynamic>>> getExpenseReport(String startDate, String endDate) async {
    final db = await localDb.database;
    return await db.rawQuery('''
      SELECT category, SUM(amount) as total_amount
      FROM expenses
      WHERE expense_date >= ? AND expense_date <= ?
      GROUP BY category
      ORDER BY total_amount DESC
    ''', [startDate, endDate]);
  }

  Future<List<Map<String, dynamic>>> getStockReport() async {
    final db = await localDb.database;
    // Current snapshot, ignoring dates
    return await db.rawQuery('''
      SELECT name, stock_quantity, selling_price, (stock_quantity * purchase_price) as inventory_value
      FROM products
      WHERE stock_quantity > 0
      ORDER BY stock_quantity ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getCreditReport() async {
    final db = await localDb.database;
    final customers = await db.rawQuery('''
      SELECT 'Customer' as type, name, due_amount 
      FROM customers 
      WHERE due_amount > 0
    ''');
    final suppliers = await db.rawQuery('''
      SELECT 'Supplier' as type, name, due_amount 
      FROM suppliers 
      WHERE due_amount > 0
    ''');
    return [...customers, ...suppliers];
  }
}
