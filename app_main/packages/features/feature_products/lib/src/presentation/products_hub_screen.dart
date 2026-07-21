// FILE: packages/features/feature_products/lib/src/presentation/products_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_products/src/presentation/add_product_screen.dart';
import 'package:feature_products/src/presentation/all_products_list_widget.dart';
// ✅ NEW: Import the Import Screen
import 'package:feature_products/src/presentation/product_import_screen.dart';

class ProductsHubScreen extends ConsumerWidget {
  final bool isStandalone;

  const ProductsHubScreen({
    super.key,
    this.isStandalone = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ✅ NEW: Added AppBar to house the "Action" buttons
      appBar: isStandalone
          ? AppBar(
              title: Text(l10n.productsTitle), // You can replace this with l10n.products later
              actions: [
                // ⬇️ THE IMPORT BUTTON
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  tooltip: 'Import from Excel/CSV',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProductImportScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          if (!isStandalone)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import from Excel/CSV'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProductImportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          const Expanded(child: AllProductsListWidget()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
        },
        tooltip: l10n.addNewProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}