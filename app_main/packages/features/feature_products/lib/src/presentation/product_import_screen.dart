// FILE: packages/features/feature_products/lib/src/presentation/product_import_screen.dart

import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart'; // For AppLocalizations if available, or hardcode english for now
import 'package:feature_products/src/data/categories_repository.dart';
import 'package:feature_products/src/data/import_service.dart';
import 'package:core_database/core_database.dart';
import 'package:shared_ui/shared_ui.dart'; // Assuming shared UI exists

class ProductImportScreen extends ConsumerStatefulWidget {
  const ProductImportScreen({super.key});

  @override
  ConsumerState<ProductImportScreen> createState() => _ProductImportScreenState();
}

class _ProductImportScreenState extends ConsumerState<ProductImportScreen> {
  List<ImportedProductDraft> _drafts = [];
  bool _isLoading = false;
  String? _selectedDefaultCategoryId;

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    try {
      final drafts = await ref.read(importServiceProvider).pickAndParseFile();
      setState(() {
        _drafts = drafts;
      });
      if (drafts.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No products found in file.")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmImport() async {
    if (_selectedDefaultCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Default Category")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Convert Drafts to Companions
      final List<ProductsCompanion> companions = _drafts.map((draft) {
        return ProductsCompanion.insert(
          name: draft.name,
          // If category matching is complex, we use the default for now to ensure safety
          categoryId: _selectedDefaultCategoryId!, 
          barcode: d.Value(draft.barcode.isEmpty ? null : draft.barcode),
          price: (draft.price * 100).round(), // Cents
          averageCost: d.Value((draft.cost * 100).round()),
          quantityOnHand: d.Value(draft.quantity),
          lastUpdated: d.Value(DateTime.now()),
        );
      }).toList();

      await ref.read(importServiceProvider).saveProducts(companions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully imported ${companions.length} products!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Import Failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Import Products")),
      body: Column(
        children: [
          // 1. Control Panel
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("1. Select a default category for these products:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) return const Text("Please create a category first.");
                      return DropdownButtonFormField<String>(
                        value: _selectedDefaultCategoryId,
                        items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => setState(() => _selectedDefaultCategoryId = val),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text("Error: $e"),
                  ),
                  const SizedBox(height: 16),
                  const Text("2. Upload CSV or Excel file (Cols: Name, Barcode, Cat, Price, Cost, Qty)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Select File"),
                  ),
                ],
              ),
            ),
          ),

          // 2. Preview Table
          Expanded(
            child: _drafts.isEmpty
                ? const Center(child: Text("No data loaded. Upload a file to preview."))
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Name")),
                          DataColumn(label: Text("Barcode")),
                          DataColumn(label: Text("Price")),
                          DataColumn(label: Text("Qty")),
                        ],
                        rows: _drafts.map((d) {
                          return DataRow(cells: [
                            DataCell(Text(d.name)),
                            DataCell(Text(d.barcode)),
                            DataCell(Text(d.price.toStringAsFixed(2))),
                            DataCell(Text(d.quantity.toString())),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ),

          // 3. Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: (_drafts.isEmpty || _isLoading) ? null : _confirmImport,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text("Import ${_drafts.length} Products"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}