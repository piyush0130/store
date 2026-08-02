import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../../inventory/presentation/providers/inventory_provider.dart';
import '../../customers/presentation/providers/customer_provider.dart';
import 'checkout_modal.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  void _showCheckoutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CheckoutModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final productsAsync = ref.watch(productsProvider);
    final customersAsync = ref.watch(customersProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS / Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Attach Farmer',
            onPressed: () {
              // Simple dialog to pick customer
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Farmer'),
                  content: customersAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text('Error: $e'),
                    data: (customers) => SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final c = customers[index];
                          return ListTile(
                            title: Text(c.name),
                            subtitle: Text(c.mobile ?? ''),
                            onTap: () {
                              ref.read(cartProvider.notifier).setCustomer(c);
                              context.pop();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              context.push('/scanner').then((barcode) {
                if (barcode != null) {
                  // Find product by barcode and add
                  ref.read(searchQueryProvider.notifier).state = barcode.toString();
                }
              });
            },
          )
        ],
      ),
      body: Row(
        children: [
          // Left Side: Product Search & List
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search products by name or barcode...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                  ),
                ),
                Expanded(
                  child: productsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                    data: (products) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final p = products[index];
                          return InkWell(
                            onTap: () {
                              if (p.stockQuantity <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of Stock!')));
                                return;
                              }
                              ref.read(cartProvider.notifier).addProduct(p);
                            },
                            child: Card(
                              color: p.stockQuantity <= 0 ? Colors.red.shade50 : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.inventory, size: 40, color: Colors.green),
                                    const SizedBox(height: 8),
                                    Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    Text(currencyFormat.format(p.sellingPrice), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    Text('Stock: ${p.stockQuantity}', style: TextStyle(color: p.stockQuantity <= 0 ? Colors.red : Colors.grey, fontSize: 12)),
                                  ],
                                ),
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
          ),
          
          // Right Side: Cart
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.green,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        if (cart.selectedCustomer != null)
                          Chip(
                            label: Text(cart.selectedCustomer!.name),
                            onDeleted: () => ref.read(cartProvider.notifier).setCustomer(null),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: cart.items.isEmpty 
                      ? const Center(child: Text('Cart is empty', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return ListTile(
                              title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${currencyFormat.format(item.customPrice)} x ${item.quantity}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                  
                  // Totals
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text(currencyFormat.format(cart.subtotal)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tax (GST):'),
                            Text(currencyFormat.format(cart.totalGst), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(currencyFormat.format(cart.grandTotal), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cart.items.isEmpty ? null : () => _showCheckoutModal(context),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(20),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('PROCEED TO CHECKOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
