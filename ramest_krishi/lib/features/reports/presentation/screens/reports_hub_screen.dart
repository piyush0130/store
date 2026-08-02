import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/reports_provider.dart';

class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _ReportCard(
            title: 'Sales Report',
            icon: Icons.point_of_sale,
            color: Colors.green,
            onTap: () => _openReport(context, ref, ReportType.sales),
          ),
          _ReportCard(
            title: 'Purchase Report',
            icon: Icons.shopping_cart,
            color: Colors.blue,
            onTap: () => _openReport(context, ref, ReportType.purchase),
          ),
          _ReportCard(
            title: 'GST Report',
            icon: Icons.account_balance,
            color: Colors.orange,
            onTap: () => _openReport(context, ref, ReportType.gst),
          ),
          _ReportCard(
            title: 'Expenses Report',
            icon: Icons.money_off,
            color: Colors.red,
            onTap: () => _openReport(context, ref, ReportType.expense),
          ),
          _ReportCard(
            title: 'Stock Valuation',
            icon: Icons.inventory,
            color: Colors.teal,
            onTap: () => _openReport(context, ref, ReportType.stock),
          ),
          _ReportCard(
            title: 'Credit (Khata) Report',
            icon: Icons.book,
            color: Colors.purple,
            onTap: () => _openReport(context, ref, ReportType.credit),
          ),
        ],
      ),
    );
  }

  void _openReport(BuildContext context, WidgetRef ref, ReportType type) {
    ref.read(selectedReportTypeProvider.notifier).state = type;
    context.push('/reports/detail');
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.5))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
