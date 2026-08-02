import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/metric_card.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/sync/sync_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final syncState = ref.watch(syncServiceProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ramest Krishi - Dashboard'),
        actions: [
          // Sync Indicator
          IconButton(
            icon: Icon(
              syncState.status == SyncStatus.syncing ? Icons.cloud_sync : 
              syncState.status == SyncStatus.error ? Icons.cloud_off : Icons.cloud_done,
              color: syncState.status == SyncStatus.error ? Colors.red :
                     syncState.status == SyncStatus.syncing ? Colors.blue : Colors.green,
            ),
            tooltip: 'Sync Status: ${syncState.status.name}',
            onPressed: () => ref.read(syncServiceProvider).triggerManualSync(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardMetricsProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implementation of logout...
            },
          )
        ],
      ),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (metrics) {
          return RefreshIndicator(
            onRefresh: () => ref.read(dashboardMetricsProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Core Metrics Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: [
                      MetricCard(
                        title: "Today's Sales",
                        value: currencyFormatter.format(metrics.todaysSales),
                        icon: Icons.point_of_sale,
                        color: Colors.green,
                      ),
                      MetricCard(
                        title: "Today's Purchase",
                        value: currencyFormatter.format(metrics.todaysPurchase),
                        icon: Icons.shopping_cart,
                        color: Colors.blue,
                      ),
                      MetricCard(
                        title: "Expenses",
                        value: currencyFormatter.format(metrics.todayExpenses),
                        icon: Icons.money_off,
                        color: Colors.orange,
                      ),
                      MetricCard(
                        title: "Profit (Est)",
                        value: currencyFormatter.format(metrics.todayProfit),
                        icon: Icons.trending_up,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 2. Payment Breakdown & Alerts Row
                  Text("Alerts & Breakdown", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSmallCard("Cash", currencyFormatter.format(metrics.totalCash), Colors.green),
                        _buildSmallCard("UPI", currencyFormatter.format(metrics.totalUpi), Colors.blueAccent),
                        _buildSmallCard("Credit (Khata)", currencyFormatter.format(metrics.totalCredit), Colors.purple),
                        _buildSmallCard("Low Stock", "${metrics.lowStockCount} Items", Colors.orange),
                        _buildSmallCard("Out of Stock", "${metrics.outOfStockCount} Items", Colors.red),
                        _buildSmallCard("Pending Pay", currencyFormatter.format(metrics.totalPendingPayments), Colors.redAccent),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // 3. Monthly Graph
                  Text("Monthly Sales vs Expenses", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [FlSpot(0, 1), FlSpot(1, 3), FlSpot(2, 2), FlSpot(3, 5)], // Placeholder
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Navigation Links
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/purchases'),
                          icon: const Icon(Icons.inventory_2),
                          label: const Text('Wholesale Purchases'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.brown.shade100,
                            foregroundColor: Colors.brown.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/reports'),
                          icon: const Icon(Icons.analytics),
                          label: const Text('Reports & Exports'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.deepPurple.shade100,
                            foregroundColor: Colors.deepPurple.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // 4. Rankings (Top Products / Customers)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRankingList("Top Products", metrics.topProducts.map((e) => e['name'].toString()).toList()),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRankingList("Top Customers", metrics.topCustomers.map((e) => e['name'].toString()).toList()),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmallCard(String title, String value, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRankingList(String title, List<String> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            if (items.isEmpty) const Text("No data yet", style: TextStyle(color: Colors.grey)),
            ...items.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text("${e.key + 1}.", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.value, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
