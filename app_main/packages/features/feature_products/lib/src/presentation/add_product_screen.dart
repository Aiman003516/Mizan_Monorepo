// FILE: packages/features/feature_products/lib/src/presentation/add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_products/src/data/products_repository.dart';
import 'package:shared_ui/shared_ui.dart'; // Import Formatter
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';

import 'package:feature_products/src/data/categories_repository.dart';

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
    _nameController =
        TextEditingController(text: widget.productToEdit?.name ?? '');
    _barcodeController =
        TextEditingController(text: widget.productToEdit?.barcode ?? '');
    _selectedCategoryId = widget.productToEdit?.categoryId;
    _imagePath = widget.productToEdit?.imagePath;

    // --- CRITICAL FIX ---
    // Convert Cents (Int) to Double String (e.g. 1050 -> "10.50")
    if (widget.productToEdit != null) {
      final double priceDouble =
          CurrencyFormatter.centsToDouble(widget.productToEdit!.price);
      _priceController =
          TextEditingController(text: priceDouble.toStringAsFixed(2));
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
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.pleaseSelectCategory)),
        );
        return;
      }

      final name = _nameController.text;
      final priceDouble =
          double.parse(_priceController.text); // User inputs 10.50
      // Note: The Repository now handles the conversion to Cents. We pass Double.

      final barcode =
          _barcodeController.text.isEmpty ? null : _barcodeController.text;

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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencySymbol =
        ref.watch(preferencesRepositoryProvider).getCurrencySymbol();

    // (Keep your existing UI scaffold/layout code here)
    // ...
    // Ensure your TextFormField for price looks like this:
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.productToEdit == null
              ? l10n.addProduct
              : l10n.editProduct)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.productName),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: l10n.price,
                  prefixText: '$currencySymbol ', // dynamic currency symbol
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.requiredField;
                  if (double.tryParse(v) == null) return l10n.invalidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Category Dropdown
              Consumer(
                builder: (context, ref, _) {
                  final categoriesAsync = ref.watch(categoriesStreamProvider);
                  return categoriesAsync.when(
                    data: (categories) {
                      return DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: l10n.category,
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                        validator: (v) =>
                            v == null ? l10n.pleaseSelectCategory : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) =>
                        Text(l10n.errorLoadingCategories(e.toString())),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: Text(l10n.saveProduct),
              )
            ],
          ),
        ),
      ),
    );
  }
}
