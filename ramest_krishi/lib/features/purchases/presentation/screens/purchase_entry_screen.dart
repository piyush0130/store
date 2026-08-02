import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/purchase_provider.dart';
import '../../domain/entities/purchase_entity.dart';
import '../../domain/entities/supplier_entity.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/domain/entities/product_entity.dart';

class PurchaseEntryScreen extends ConsumerStatefulWidget {
  const PurchaseEntryScreen({super.key});

  @override
  ConsumerState<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends ConsumerState<PurchaseEntryScreen> {
  SupplierEntity? _selectedSupplier;
  final _invoiceCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isSaving = false;

  void _showAddProductDialog() {
    final productsAsync = ref.read(productsProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return productsAsync.when(
          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (products) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              builder: (_, controller) => _AddItemForm(products: products),
            );
          },
        );
      },
    );
  }

  void _submit() async {
    if (_selectedSupplier == null || _invoiceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select supplier and enter invoice number')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(purchaseEntryProvider.notifier).submitPurchase(
        supplierId: _selectedSupplier!.id,
        invoiceNumber: _invoiceCtrl.text,
        paidAmount: double.tryParse(_paidAmountCtrl.text) ?? 0.0,
        paymentMethod: _paymentMethod,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase Saved & Stock Updated!')));
      // Refresh inventory to show new stock
      ref.refresh(productsProvider); 
      ref.refresh(suppliersProvider);
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(purchaseEntryProvider);
    final totalAmount = ref.watch(purchaseEntryProvider.notifier).totalAmount;
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Wholesale Purchase')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Info
            Row(
              children: [
                Expanded(
                  child: suppliersAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => const Text('Error loading suppliers'),
                    data: (suppliers) => DropdownButtonFormField<SupplierEntity>(
                      decoration: const InputDecoration(labelText: 'Supplier', border: OutlineInputBorder()),
                      value: _selectedSupplier,
                      items: suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                      onChanged: (val) => setState(() => _selectedSupplier = val),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _invoiceCtrl,
                    decoration: const InputDecoration(labelText: 'Invoice Number', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Item List
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Invoice Items', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(icon: const Icon(Icons.add_circle, color: Colors.green, size: 30), onPressed: _showAddProductDialog),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.product.name),
                            subtitle: Text('Qty: ${item.quantity} | Batch: ${item.batchNumber ?? "N/A"}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('₹${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => ref.read(purchaseEntryProvider.notifier).removeItem(index),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Payment Footer
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Invoice Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _paidAmountCtrl,
                            decoration: const InputDecoration(labelText: 'Amount Paid Now', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                            value: _paymentMethod,
                            items: const [
                              DropdownMenuItem(value: 'cash', child: Text('Cash')),
                              DropdownMenuItem(value: 'upi', child: Text('UPI / Bank')),
                              DropdownMenuItem(value: 'credit', child: Text('Full Credit (Udhar)')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _paymentMethod = val!;
                                if (val == 'credit') _paidAmountCtrl.text = '0';
                                if (val != 'credit' && _paidAmountCtrl.text.isEmpty) _paidAmountCtrl.text = totalAmount.toString();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        onPressed: _isSaving ? null : _submit,
                        child: _isSaving ? const CircularProgressIndicator() : const Text('SAVE INVOICE & ADD STOCK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Sub-widget for adding an item to the invoice
class _AddItemForm extends ConsumerStatefulWidget {
  final List<ProductEntity> products;
  const _AddItemForm({required this.products});

  @override
  ConsumerState<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends ConsumerState<_AddItemForm> {
  ProductEntity? _selectedProduct;
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: ListView(
        children: [
          const Text('Add Item to Invoice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProductEntity>(
            decoration: const InputDecoration(labelText: 'Select Product', border: OutlineInputBorder()),
            items: widget.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedProduct = val;
                _priceCtrl.text = val?.purchasePrice.toString() ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: _qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Purchase Price / Unit', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: _batchCtrl, decoration: const InputDecoration(labelText: 'Batch Number', border: OutlineInputBorder()))),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _expiryCtrl, decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_selectedProduct == null || _qtyCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
              
              final item = PurchaseItemEntity(
                product: _selectedProduct!,
                quantity: double.parse(_qtyCtrl.text),
                unitPrice: double.parse(_priceCtrl.text),
                batchNumber: _batchCtrl.text.isEmpty ? null : _batchCtrl.text,
                expiryDate: _expiryCtrl.text.isEmpty ? null : _expiryCtrl.text,
              );
              
              ref.read(purchaseEntryProvider.notifier).addItem(item);
              Navigator.pop(context);
            },
            child: const Text('Add to Invoice'),
          )
        ],
      ),
    );
  }
}
