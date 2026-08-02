import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_provider.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final searchController = TextEditingController(text: ref.read(customerSearchQueryProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers & Khata'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, Mobile, Village...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) => ref.read(customerSearchQueryProvider.notifier).state = val,
            ),
          ),
        ),
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No customers found. Add a farmer!'));
          }
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final c = customers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.green)),
                ),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${c.village ?? "No Village"} | ${c.mobile ?? "No Number"}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Due: ₹${c.dueAmount}', 
                      style: TextStyle(
                        color: c.dueAmount > 0 ? Colors.red : Colors.green, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to Ledger detail screen passing the customer object (or ID)
                  context.push('/customer/detail', extra: c);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add customer form
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Farmer'),
      ),
    );
  }
}
