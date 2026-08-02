import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_db.dart';
import '../../domain/entities/dashboard_metrics.dart';

class DashboardLocalDataSource {
  final LocalDatabase localDb;

  DashboardLocalDataSource(this.localDb);

  Future<DashboardMetrics> getMetrics() async {
    final db = await localDb.database;

    // Helper: get today's start and end in ISO8601 for SQLite
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    
    // 1. Today's Sales
    final salesRes = await db.rawQuery(
      "SELECT SUM(total_amount) as s, SUM(discount) as d FROM sales WHERE sale_date >= ?", 
      [todayStart]
    );
    final todaysSales = (salesRes.first['s'] as num?)?.toDouble() ?? 0.0;

    // 2. Payments Breakdown (Today)
    final paymentRes = await db.rawQuery(
      "SELECT payment_method, SUM(paid_amount) as total FROM sales WHERE sale_date >= ? GROUP BY payment_method", 
      [todayStart]
    );
    double totalCash = 0; double totalUpi = 0; double totalCredit = 0;
    for (var row in paymentRes) {
      final method = row['payment_method'] as String?;
      final val = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (method == 'cash') totalCash = val;
      if (method == 'upi') totalUpi = val;
      if (method == 'khata') totalCredit = val; // Assuming 'khata' means credit given today
    }

    // 3. Stock Alerts
    final lowStockRes = await db.rawQuery("SELECT COUNT(*) as c FROM products WHERE stock_quantity > 0 AND stock_quantity <= 10");
    final lowStockCount = Sqflite.firstIntValue(lowStockRes) ?? 0;
    
    final outStockRes = await db.rawQuery("SELECT COUNT(*) as c FROM products WHERE stock_quantity <= 0");
    final outOfStockCount = Sqflite.firstIntValue(outStockRes) ?? 0;

    // 4. Pending Payments (Total negative credit_balance across all customers)
    final pendingRes = await db.rawQuery("SELECT SUM(credit_balance) as c FROM customers WHERE credit_balance < 0");
    final totalPendingPayments = (pendingRes.first['c'] as num?)?.toDouble()?.abs() ?? 0.0;

    // 5. Top Products (By Quantity Sold this month)
    // Complex join across sales and sale_items
    final topProducts = await db.rawQuery('''
      SELECT p.name, SUM(si.quantity) as qty
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      JOIN products p ON si.product_id = p.id
      GROUP BY p.id
      ORDER BY qty DESC
      LIMIT 5
    ''');

    // Return aggregated entity
    return DashboardMetrics(
      todaysSales: todaysSales,
      todaysPurchase: 0.0, // Needs Purchase module
      totalCash: totalCash,
      totalUpi: totalUpi,
      totalCredit: totalCredit,
      todayExpenses: 0.0, // Needs Expenses module
      todayProfit: todaysSales * 0.20, // Placeholder calculation
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      totalPendingPayments: totalPendingPayments,
      topProducts: topProducts,
      topCustomers: [], // Similar to topProducts
      monthlyGraphData: [], // Would generate array of last 30 days sums
    );
  }
}
