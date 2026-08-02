import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/customer_provider.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final CustomerEntity customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(customerLedgerProvider(customer.id));
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {
            // Navigate to edit passing the customer
          })
        ],
      ),
      body: Column(
        children: [
          // Profile & Khata Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.shade200,
                  child: Text(customer.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.mobile ?? 'No Mobile', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(customer.village ?? 'No Village'),
                      if (customer.primaryCrop != null) Text('Crop: ${customer.primaryCrop} (${customer.landArea} Acres)', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Due', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(
                      currencyFormatter.format(customer.dueAmount), 
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: customer.dueAmount > 0 ? Colors.red : Colors.green
                      )
                    ),
                  ],
                )
              ],
            ),
          ),

          // Ledger (Purchase & Payment History)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: const Text('Khata Ledger (Purchase History)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: ledgerAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (ledger) {
                if (ledger.isEmpty) return const Center(child: Text('No transaction history found.'));
                
                return ListView.builder(
                  itemCount: ledger.length,
                  itemBuilder: (context, index) {
                    final tx = ledger[index];
                    final date = DateTime.parse(tx['sale_date'] ?? tx['created_at']);
                    final isDebit = tx['payment_method'] == 'khata';
                    final amount = (tx['total_amount'] as num?)?.toDouble() ?? 0.0;
                    
                    return ListTile(
                      leading: Icon(
                        isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isDebit ? Colors.red : Colors.green,
                      ),
                      title: Text(isDebit ? 'Purchase (Credit)' : 'Purchase (Cash/UPI)'),
                      subtitle: Text(dateFormatter.format(date)),
                      trailing: Text(
                        currencyFormatter.format(amount),
                        style: TextStyle(
                          color: isDebit ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Logic to receive payment and reduce dueAmount
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Receive Payment'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
