import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reports_provider.dart';
import '../services/export_service.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key});

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(reportDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: currentRange.startDate, end: currentRange.endDate),
    );

    if (picked != null) {
      // Adjust end date to end of day
      final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      ref.read(reportDateRangeProvider.notifier).state = DateRangeState(picked.start, end);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(selectedReportTypeProvider);
    final dates = ref.watch(reportDateRangeProvider);
    final dataAsync = ref.watch(reportDataProvider);
    
    // Hide date picker for snapshot reports
    final showDates = type != ReportType.stock && type != ReportType.credit;

    return Scaffold(
      appBar: AppBar(
        title: Text('${type.name.toUpperCase()} Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV / Excel',
            onPressed: () {
              dataAsync.whenData((data) {
                ExportService.exportToCsv('${type.name}_report', data);
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (showDates)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dates.display, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ElevatedButton.icon(
                    onPressed: () => _selectDateRange(context, ref),
                    icon: const Icon(Icons.date_range),
                    label: const Text('Change Dates'),
                  )
                ],
              ),
            ),
          
          Expanded(
            child: dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (data) {
                if (data.isEmpty) return const Center(child: Text('No data found for this period.'));

                // Build a dynamic DataTable
                final headers = data.first.keys.toList();
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: headers.map((h) => DataColumn(label: Text(h.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      rows: data.map((row) {
                        return DataRow(
                          cells: headers.map((h) {
                            final val = row[h];
                            // Basic formatting for numbers
                            if (val is double) {
                              return DataCell(Text('₹${val.toStringAsFixed(2)}'));
                            }
                            return DataCell(Text(val.toString()));
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
