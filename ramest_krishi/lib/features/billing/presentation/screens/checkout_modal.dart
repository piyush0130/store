import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/cart_provider.dart';
import '../services/invoice_generator.dart';
import '../../../customers/domain/entities/customer_entity.dart';

class CheckoutModal extends ConsumerStatefulWidget {
  const CheckoutModal({super.key});

  @override
  ConsumerState<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends ConsumerState<CheckoutModal> {
  String _paymentMethod = 'cash';
  late TextEditingController _amountPaidCtrl;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _amountPaidCtrl = TextEditingController(text: cart.grandTotal.toString());
  }

  void _processPayment(CartState cart) async {
    setState(() => _isProcessing = true);
    try {
      final amountPaid = double.tryParse(_amountPaidCtrl.text) ?? 0.0;
      
      final saleId = await ref.read(cartProvider.notifier).checkout(
        paymentMethod: _paymentMethod,
        amountPaid: amountPaid,
      );

      if (!mounted) return;
      
      // Auto-Print Invoice
      await InvoiceGenerator.printInvoice(cart, saleId, _paymentMethod);
      
      ref.read(cartProvider.notifier).clearCart();
      context.pop(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed successfully!')));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final upiString = 'upi://pay?pa=shop@upi&pn=RamestKrishi&am=${cart.grandTotal}&cu=INR';

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Checkout Summary', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontSize: 18)),
                  Text('₹${cart.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const Divider(height: 32),

              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', label: Text('Cash'), icon: Icon(Icons.money)),
                  ButtonSegment(value: 'upi', label: Text('UPI/QR'), icon: Icon(Icons.qr_code)),
                  ButtonSegment(value: 'khata', label: Text('Khata (Credit)'), icon: Icon(Icons.book)),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _paymentMethod = newSelection.first;
                    if (_paymentMethod == 'khata') {
                      _amountPaidCtrl.text = '0'; // Default to paying 0 for khata
                    } else {
                      _amountPaidCtrl.text = cart.grandTotal.toString();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              if (_paymentMethod == 'upi') ...[
                const Center(child: Text('Scan to Pay via UPI', style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 8),
                Center(
                  child: QrImageView(
                    data: upiString,
                    version: QrVersions.auto,
                    size: 150.0,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_paymentMethod == 'khata') ...[
                if (cart.selectedCustomer == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade50,
                    child: const Text('⚠️ You must attach a Farmer profile to this bill for Khata.', style: TextStyle(color: Colors.red)),
                  )
                else
                  Text('Adding to ${cart.selectedCustomer!.name}\'s Khata Ledger.', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _amountPaidCtrl,
                decoration: const InputDecoration(labelText: 'Amount Received (₹)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isProcessing ? null : () => _processPayment(cart),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('COMPLETE & PRINT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : () async {
                  // Simulate process and share instead of print
                  final saleId = "SALE-${DateTime.now().millisecondsSinceEpoch}";
                  final pdfBytes = await InvoiceGenerator.generateInvoicePdf(cart, saleId, _paymentMethod);
                  await Printing.sharePdf(bytes: pdfBytes, filename: 'receipt_$saleId.pdf');
                },
                icon: const Icon(Icons.share, color: Colors.green),
                label: const Text('Share PDF (WhatsApp)', style: TextStyle(color: Colors.green)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
