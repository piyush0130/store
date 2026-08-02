import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';
import 'dart:io';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final searchController = TextEditingController(text: ref.read(searchQueryProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Company, Barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          // Navigate to scanner screen or show bottom sheet
                          context.push('/scanner').then((barcode) {
                            if (barcode != null) {
                              ref.read(searchQueryProvider.notifier).state = barcode.toString();
                            }
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products found. Add some!'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                leading: p.imageLocalPath != null
                    ? Image.file(File(p.imageLocalPath!), width: 50, height: 50, fit: BoxFit.cover)
                    : Container(width: 50, height: 50, color: Colors.grey.shade300, child: const Icon(Icons.inventory)),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${p.company ?? ""} | Stock: ${p.stockQuantity}'),
                trailing: Text('₹${p.sellingPrice}', style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                onTap: () {
                  // Navigate to AddEdit screen with product ID for editing
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add product screen
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
