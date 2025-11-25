// FILE: packages/features/feature_products/lib/src/presentation/add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_products/src/data/products_repository.dart';
import 'package:shared_ui/shared_ui.dart'; // Import Formatter

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? productToEdit; // If null, we are adding a new product

  const AddProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _barcodeController;
  String? _selectedCategoryId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productToEdit?.name ?? '');
    _barcodeController = TextEditingController(text: widget.productToEdit?.barcode ?? '');
    _selectedCategoryId = widget.productToEdit?.categoryId;
    _imagePath = widget.productToEdit?.imagePath;

    // --- CRITICAL FIX ---
    // Convert Cents (Int) to Double String (e.g. 1050 -> "10.50")
    if (widget.productToEdit != null) {
      final double priceDouble = CurrencyFormatter.centsToDouble(widget.productToEdit!.price);
      _priceController = TextEditingController(text: priceDouble.toStringAsFixed(2));
    } else {
      _priceController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final name = _nameController.text;
      final priceDouble = double.parse(_priceController.text); // User inputs 10.50
      // Note: The Repository now handles the conversion to Cents. We pass Double.
      
      final barcode = _barcodeController.text.isEmpty ? null : _barcodeController.text;

      try {
        if (widget.productToEdit != null) {
          await ref.read(productsRepositoryProvider).updateProduct(
            widget.productToEdit!,
            newName: name,
            newPrice: priceDouble,
            newCategoryId: _selectedCategoryId!,
            newBarcode: barcode,
            newImagePath: _imagePath,
          );
        } else {
          await ref.read(productsRepositoryProvider).createProduct(
            name: name,
            price: priceDouble,
            categoryId: _selectedCategoryId!,
            barcode: barcode,
            imagePath: _imagePath,
          );
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // (Keep your existing UI scaffold/layout code here)
    // ...
    // Ensure your TextFormField for price looks like this:
    return Scaffold(
      appBar: AppBar(title: Text(widget.productToEdit == null ? 'Add Product' : 'Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                   labelText: 'Price', 
                   prefixText: '\$ ', // Or use dynamic currency symbol
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                   if (v == null || v.isEmpty) return 'Required';
                   if (double.tryParse(v) == null) return 'Invalid number';
                   return null;
                },
              ),
              // ... Other fields (Category Dropdown, Barcode, ImagePicker)
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save Product'),
              )
            ],
          ),
        ),
      ),
    );
  }
}