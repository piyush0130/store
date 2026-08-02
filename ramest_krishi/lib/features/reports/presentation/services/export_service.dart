import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> exportToCsv(String reportName, List<Map<String, dynamic>> data) async {
    if (data.isEmpty) throw Exception("No data to export");

    // 1. Extract Headers
    List<String> headers = data.first.keys.toList();
    
    // 2. Extract Rows
    List<List<dynamic>> rows = [];
    rows.add(headers);
    for (var map in data) {
      rows.add(map.values.toList());
    }

    // 3. Convert to CSV string
    String csvData = const ListToCsvConverter().convert(rows);

    // 4. Save to temporary file
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/${reportName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    // 5. Share file (Will open WhatsApp, Email, or Excel)
    await Share.shareXFiles([XFile(path)], text: 'Exported $reportName');
  }
}
