// FILE: packages/features/feature_products/lib/src/presentation/all_products_list_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:shared_ui/shared_ui.dart'; // Import the Formatter
import 'package:feature_products/src/presentation/all_products_stream_provider.dart';
import 'package:feature_products/src/presentation/add_product_screen.dart';

class AllProductsListWidget extends ConsumerWidget {
  const AllProductsListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsStreamProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              title: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Stock: ${product.quantityOnHand} | Barcode: ${product.barcode ?? "N/A"}',
              ),
              trailing: Text(
                // --- THE FIX ---
                // Convert Int (Cents) to Formatted String
                CurrencyFormatter.formatCentsToCurrency(product.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProductScreen(productToEdit: product),
                  ),
                );
              },
            );
          },
        );
      },
      error: (err, stack) => Center(child: Text('Error: $err')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}