import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../providers/inventory_provider.dart';
import '../../domain/entities/product_entity.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final ProductEntity? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _purchaseCtrl;
  late TextEditingController _sellingCtrl;
  late TextEditingController _gstCtrl;
  late TextEditingController _hsnCtrl;
  late TextEditingController _batchCtrl;
  late TextEditingController _expiryCtrl;
  late TextEditingController _stockCtrl;
  
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _companyCtrl = TextEditingController(text: p?.company ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _mrpCtrl = TextEditingController(text: p?.mrp.toString() ?? '');
    _purchaseCtrl = TextEditingController(text: p?.purchasePrice.toString() ?? '');
    _sellingCtrl = TextEditingController(text: p?.sellingPrice.toString() ?? '');
    _gstCtrl = TextEditingController(text: p?.gstPercentage.toString() ?? '0.0');
    _hsnCtrl = TextEditingController(text: p?.hsnCode ?? '');
    _batchCtrl = TextEditingController(text: p?.batchNumber ?? '');
    _expiryCtrl = TextEditingController(text: p?.expiryDate ?? '');
    _stockCtrl = TextEditingController(text: p?.stockQuantity.toString() ?? '0.0');
    
    if (p?.imageLocalPath != null) {
      _imageFile = File(p!.imageLocalPath!);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = ProductEntity(
      id: widget.product?.id ?? const Uuid().v4(),
      branchId: 'current-branch-id', // Would come from Auth state
      name: _nameCtrl.text,
      company: _companyCtrl.text,
      barcode: _barcodeCtrl.text,
      mrp: double.tryParse(_mrpCtrl.text) ?? 0,
      purchasePrice: double.tryParse(_purchaseCtrl.text) ?? 0,
      sellingPrice: double.tryParse(_sellingCtrl.text) ?? 0,
      gstPercentage: double.tryParse(_gstCtrl.text) ?? 0,
      hsnCode: _hsnCtrl.text,
      batchNumber: _batchCtrl.text,
      expiryDate: _expiryCtrl.text,
      stockQuantity: double.tryParse(_stockCtrl.text) ?? 0,
      imageLocalPath: _imageFile?.path,
    );

    if (widget.product == null) {
      await ref.read(productsProvider.notifier).addProduct(product);
    } else {
      // await ref.read(productsProvider.notifier).updateProduct(product);
    }
    
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveProduct),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Area
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                            Text('Tap to add photo'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _barcodeCtrl,
                    decoration: const InputDecoration(labelText: 'Barcode', border: OutlineInputBorder()),
                  )),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 36),
                    onPressed: () {
                      context.push('/scanner').then((code) {
                        if (code != null) setState(() => _barcodeCtrl.text = code.toString());
                      });
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),

              // Pricing Row
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _purchaseCtrl,
                    decoration: const InputDecoration(labelText: 'Purchase Price', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(
                    controller: _mrpCtrl,
                    decoration: const InputDecoration(labelText: 'MRP', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(
                    controller: _sellingCtrl,
                    decoration: const InputDecoration(labelText: 'Selling Price *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  )),
                ],
              ),
              const SizedBox(height: 16),

              // Taxes & Stock
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _gstCtrl,
                    decoration: const InputDecoration(labelText: 'GST %', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(
                    controller: _stockCtrl,
                    decoration: const InputDecoration(labelText: 'Current Stock', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  )),
                ],
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('SAVE PRODUCT', style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
