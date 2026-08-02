import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/customer_provider.dart';
import '../../domain/entities/customer_entity.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final CustomerEntity? customer;
  const AddEditCustomerScreen({super.key, this.customer});

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _villageCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _gstCtrl;
  late TextEditingController _cropCtrl;
  late TextEditingController _landAreaCtrl;
  late TextEditingController _creditLimitCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _villageCtrl = TextEditingController(text: c?.village ?? '');
    _mobileCtrl = TextEditingController(text: c?.mobile ?? '');
    _gstCtrl = TextEditingController(text: c?.gstNumber ?? '');
    _cropCtrl = TextEditingController(text: c?.primaryCrop ?? '');
    _landAreaCtrl = TextEditingController(text: c?.landArea?.toString() ?? '');
    _creditLimitCtrl = TextEditingController(text: c?.creditLimit?.toString() ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
  }

  void _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = CustomerEntity(
      id: widget.customer?.id ?? const Uuid().v4(),
      branchId: 'current-branch-id', // From auth
      name: _nameCtrl.text,
      village: _villageCtrl.text,
      mobile: _mobileCtrl.text,
      gstNumber: _gstCtrl.text,
      primaryCrop: _cropCtrl.text,
      landArea: double.tryParse(_landAreaCtrl.text),
      creditLimit: double.tryParse(_creditLimitCtrl.text),
      notes: _notesCtrl.text,
    );

    if (widget.customer == null) {
      await ref.read(customersProvider.notifier).addCustomer(customer);
    } else {
      await ref.read(customersProvider.notifier).updateCustomer(customer);
    }
    
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Add Farmer' : 'Edit Farmer'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveCustomer),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _mobileCtrl,
                    decoration: const InputDecoration(labelText: 'Mobile', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(
                    controller: _villageCtrl,
                    decoration: const InputDecoration(labelText: 'Village', border: OutlineInputBorder()),
                  )),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _gstCtrl,
                decoration: const InputDecoration(labelText: 'GST Number (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Farming Profile
              const Text("Farming Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              const Divider(),
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _cropCtrl,
                    decoration: const InputDecoration(labelText: 'Primary Crop', border: OutlineInputBorder()),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(
                    controller: _landAreaCtrl,
                    decoration: const InputDecoration(labelText: 'Land Area (Acres)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  )),
                ],
              ),
              const SizedBox(height: 16),

              // Khata / Credit
              const Text("Khata (Credit) Setup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              const Divider(),
              TextFormField(
                controller: _creditLimitCtrl,
                decoration: const InputDecoration(labelText: 'Max Credit Limit (₹)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 3,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveCustomer,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('SAVE PROFILE', style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
