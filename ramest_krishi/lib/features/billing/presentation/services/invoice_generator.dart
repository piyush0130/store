import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';

class InvoiceGenerator {
  static Future<Uint8List> generateInvoicePdf(CartState cart, String saleId, String paymentMethod) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // 3-inch thermal printer format
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('RAMEST KRISHI SEWA KENDRA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('Fertilizers & Seeds', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill: ${saleId.substring(0, 8).toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(dateFormatter.format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (cart.selectedCustomer != null) ...[
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Farmer: ${cart.selectedCustomer!.name}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ),
              ],
              pw.Divider(),
              
              // Table Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('Price', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.SizedBox(height: 4),
              
              // Items
              ...cart.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.product.name, style: const pw.TextStyle(fontSize: 10))),
                      pw.Expanded(flex: 1, child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 2, child: pw.Text(currencyFormatter.format(item.subtotal), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                );
              }).toList(),
              
              pw.Divider(),
              
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(currencyFormatter.format(cart.subtotal), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (cart.globalDiscount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('- ${currencyFormatter.format(cart.globalDiscount)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(currencyFormatter.format(cart.grandTotal), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(paymentMethod.toUpperCase(), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Text('Thank you for visiting!', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
              pw.Text('Software by Ramest Krishi', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printInvoice(CartState cart, String saleId, String paymentMethod) async {
    final pdfBytes = await generateInvoicePdf(cart, saleId, paymentMethod);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }
}
