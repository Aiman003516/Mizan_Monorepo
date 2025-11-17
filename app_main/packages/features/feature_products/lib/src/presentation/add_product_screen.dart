import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_products/src/data/categories_repository.dart';
import 'package:feature_products/src/data/products_repository.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_services/shared_services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  bool get isEditing => product != null;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();

  String? _selectedCategoryId;
  String? _imagePath;
  String? _originalImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _selectedCategoryId = widget.product!.categoryId;
      _barcodeController.text = widget.product!.barcode ?? '';
      _imagePath = widget.product!.imagePath;
      _originalImagePath = widget.product!.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _showImageSourceSheet() {
    if (Platform.isWindows) {
      _pickImage(ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.pickFromGallery),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final imageService = ref.read(imagePickerServiceProvider);

    final newPath = await imageService.pickAndCopyImage(source);

    if (newPath != null) {
      if (_imagePath != null && _imagePath != newPath) {
        await imageService.deleteImage(_imagePath);
      }
      setState(() {
        _imagePath = newPath;
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _imagePath = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseSelectCategory)),
        );
        return;
      }

      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final barcode = _barcodeController.text.trim();
      final imageService = ref.read(imagePickerServiceProvider);

      try {
        final repo = ref.read(productsRepositoryProvider);
        if (widget.isEditing) {
          await repo.updateProduct(
            widget.product!,
            newName: name,
            newPrice: price,
            newCategoryId: _selectedCategoryId!,
            newBarcode: barcode.isEmpty ? null : barcode,
            newImagePath: _imagePath,
          );
          if (_imagePath != _originalImagePath && _originalImagePath != null) {
            await imageService.deleteImage(_originalImagePath);
          }
        } else {
          await repo.createProduct(
            name: name,
            price: price,
            categoryId: _selectedCategoryId!,
            barcode: barcode.isEmpty ? null : barcode,
            imagePath: _imagePath,
          );
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.failedToSaveProduct} $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editProduct : l10n.addNewProduct),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ImagePickerWidget(
                imagePath: _imagePath,
                onPickImage: _showImageSourceSheet,
                onRemoveImage: _removeImage,
              ),
              const SizedBox(height: 24),
              _CategoryDropdown(
                selectedCategoryId: _selectedCategoryId,
                onChanged: (newId) {
                  setState(() {
                    _selectedCategoryId = newId;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.productName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory_2),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: l10n.price,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterPrice;
                  }
                  if (double.tryParse(value) == null) {
                    return l10n.pleaseEnterValidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: l10n.barcodeOptional,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.barcode_reader),
                ),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends ConsumerWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      data: (categories) {
        final validSelectedId = categories
                .any((cat) => cat.id == selectedCategoryId)
            ? selectedCategoryId
            : null;

        return DropdownButtonFormField<String>(
          value: validSelectedId,
          decoration: InputDecoration(
            labelText: l10n.selectCategory,
            border: const OutlineInputBorder(),
          ),
          items: categories.map((Category category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null) {
              return l10n.pleaseSelectCategory;
            }
            return null;
          },
        );
      },
      error: (err, stack) =>
          Text('${l10n.errorLoadingCategories} ${err.toString()}'),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}