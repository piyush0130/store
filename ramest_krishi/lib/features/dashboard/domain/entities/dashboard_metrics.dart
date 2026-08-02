class DashboardMetrics {
  final double todaysSales;
  final double todaysPurchase;
  final double totalCash;
  final double totalUpi;
  final double totalCredit;
  final double todayExpenses;
  final double todayProfit;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalPendingPayments;
  
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> topCustomers;
  final List<Map<String, dynamic>> monthlyGraphData;

  DashboardMetrics({
    required this.todaysSales,
    required this.todaysPurchase,
    required this.totalCash,
    required this.totalUpi,
    required this.totalCredit,
    required this.todayExpenses,
    required this.todayProfit,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalPendingPayments,
    required this.topProducts,
    required this.topCustomers,
    required this.monthlyGraphData,
  });

  // Empty state
  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      todaysSales: 0, todaysPurchase: 0, totalCash: 0, totalUpi: 0,
      totalCredit: 0, todayExpenses: 0, todayProfit: 0,
      lowStockCount: 0, outOfStockCount: 0, totalPendingPayments: 0,
      topProducts: [], topCustomers: [], monthlyGraphData: []
    );
  }
}
