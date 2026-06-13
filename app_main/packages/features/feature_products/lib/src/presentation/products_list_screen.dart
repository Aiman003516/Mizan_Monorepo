// FILE: packages/features/feature_products/lib/src/presentation/products_list_screen.dart

import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feature_products/src/presentation/add_product_screen.dart';
import 'package:feature_products/src/presentation/all_products_list_widget.dart';

class ProductsListScreen extends ConsumerWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productsTitle),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.newProduct),
      ),
      body: const AllProductsListWidget(),
    );
  }
}