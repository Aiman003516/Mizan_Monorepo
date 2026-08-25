import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_products/src/data/categories_repository.dart';
import 'package:feature_products/src/presentation/all_products_stream_provider.dart';
import 'package:feature_products/src/presentation/products_hub_screen.dart';

import 'dart:io';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_services/shared_services.dart';
import 'package:image_picker/image_picker.dart';

class CategoriesHubScreen extends ConsumerWidget {
  const CategoriesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final productsAsync = ref.watch(allProductsStreamProvider);
    final productCounts = <String, int>{};
    for (final product in productsAsync.valueOrNull ?? const <Product>[]) {
      productCounts.update(
        product.categoryId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final searchQuery = ref.watch(mainDashboardSearchProvider);

    return Scaffold(
      body: categoriesAsync.when(
        data: (categories) {
          final filteredList = categories.where((cat) {
            if (searchQuery.isEmpty) return true;
            return cat.name.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          if (filteredList.isEmpty) {
            return Center(
              child: Text(
                searchQuery.isEmpty
                    ? l10n.noCategoriesYet
                    : l10n.noResultsFound(searchQuery),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final category = filteredList[index];
              final imagePath = category.imagePath;
              final productCount = productCounts[category.id] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.appColors.primary,
                    child: imagePath != null && imagePath.isNotEmpty
                        ? ClipOval(
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error_outline, size: 20),
                            ),
                          )
                        : const Icon(Icons.category, size: 20),
                  ),
                  title: Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    l10n.productsCount(productCount),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: productCount == 0
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductsHubScreen(
                                isStandalone: true,
                                initialCategoryId: category.id,
                              ),
                            ),
                          );
                        },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.editCategory,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          _showAddEditDialog(context, ref, category: category);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () {
                          ref
                              .read(categoriesRepositoryProvider)
                              .deleteCategory(category.id);
                          ref
                              .read(imagePickerServiceProvider)
                              .deleteImage(category.imagePath);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (_, __) => Center(
          child: Text(
            l10n.errorLoadingData,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.addCategory),
        onPressed: () {
          _showAddEditDialog(context, ref);
        },
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return _AddEditCategoryDialog(category: category);
      },
    );
  }
}

class _AddEditCategoryDialog extends ConsumerStatefulWidget {
  final Category? category;
  bool get isEditing => category != null;

  const _AddEditCategoryDialog({this.category});

  @override
  ConsumerState<_AddEditCategoryDialog> createState() =>
      _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState
    extends ConsumerState<_AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _imagePath;
  String? _originalImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _nameController.text = widget.category!.name;
      _imagePath = widget.category!.imagePath;
      _originalImagePath = widget.category!.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      final repo = ref.read(categoriesRepositoryProvider);
      final imageService = ref.read(imagePickerServiceProvider);
      final newName = _nameController.text.trim();

      try {
        if (widget.isEditing) {
          await repo.updateCategory(
            widget.category!,
            newName: newName,
            newImagePath: _imagePath,
          );
          if (_imagePath != _originalImagePath && _originalImagePath != null) {
            await imageService.deleteImage(_originalImagePath);
          }
        } else {
          await repo.createCategory(name: newName, imagePath: _imagePath);
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.failedToSave)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.isEditing ? l10n.editCategory : l10n.newCategory),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImagePickerWidget(
                imagePath: _imagePath,
                onPickImage: _showImageSourceSheet,
                onRemoveImage: _removeImage,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.categoryName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterName;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
