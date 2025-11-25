// FILE: packages/features/feature_products/lib/src/presentation/products_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_products/src/presentation/add_product_screen.dart';
import 'package:feature_products/src/presentation/all_products_list_widget.dart';

class ProductsListScreen extends ConsumerWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
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
        label: const Text('New Product'),
      ),
      body: const AllProductsListWidget(),
    );
  }
}