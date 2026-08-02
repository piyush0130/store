import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/purchase_provider.dart';
import '../../domain/entities/supplier_entity.dart';

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wholesale Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Enter New Purchase',
            onPressed: () => context.push('/purchase/entry'),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: suppliersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return const Center(child: Text('No suppliers found. Add one to start purchasing.'));
          }
          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final s = suppliers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(s.name[0])),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.companyName ?? 'No Company Name'),
                trailing: Text(
                  'Due: ₹${s.dueAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: s.dueAmount > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // In the future, click to see supplier khata ledger
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Contact Name *')),
            TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company / Distributor Name')),
            TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final newSupplier = SupplierEntity(
                id: const Uuid().v4(),
                name: nameCtrl.text,
                companyName: companyCtrl.text,
                mobile: mobileCtrl.text,
              );
              await ref.read(purchaseRepositoryProvider).addSupplier(newSupplier);
              ref.refresh(suppliersProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}
