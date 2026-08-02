import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/reports_local_ds.dart';
import '../../../../core/database/local_db.dart';
import 'package:intl/intl.dart';

final reportsLocalDsProvider = Provider((ref) => ReportsLocalDataSource(LocalDatabase()));

// Holds the currently selected Date Range
class DateRangeState {
  final DateTime startDate;
  final DateTime endDate;
  DateRangeState(this.startDate, this.endDate);

  String get startIso => startDate.toIso8601String();
  String get endIso => endDate.toIso8601String();
  
  String get display => '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
}

final reportDateRangeProvider = StateProvider<DateRangeState>((ref) {
  // Default to current month
  final now = DateTime.now();
  return DateRangeState(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0, 23, 59, 59));
});

// Enums for report types
enum ReportType { sales, purchase, gst, expense, stock, credit }

final selectedReportTypeProvider = StateProvider<ReportType>((ref) => ReportType.sales);

// Data Provider that recalculates whenever date range or type changes
final reportDataProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final ds = ref.watch(reportsLocalDsProvider);
  final dates = ref.watch(reportDateRangeProvider);
  final type = ref.watch(selectedReportTypeProvider);

  switch (type) {
    case ReportType.sales:
      return await ds.getSalesReport(dates.startIso, dates.endIso);
    case ReportType.purchase:
      return await ds.getPurchaseReport(dates.startIso, dates.endIso);
    case ReportType.gst:
      return await ds.getGstReport(dates.startIso, dates.endIso);
    case ReportType.expense:
      return await ds.getExpenseReport(dates.startIso, dates.endIso);
    case ReportType.stock:
      return await ds.getStockReport(); // Ignores dates
    case ReportType.credit:
      return await ds.getCreditReport(); // Ignores dates
  }
});
