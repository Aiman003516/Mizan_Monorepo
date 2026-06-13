// FILE: packages/features/feature_products/lib/src/presentation/all_products_list_widget.dart

import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: context.appColors.subtleText),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.appColors.subtleText,
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
            final isLowStock = product.quantityOnHand < product.reorderPoint &&
                product.reorderPoint > 0;

            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: context.appColors.primary,
                    child: Text(
                      product.name.isNotEmpty
                          ? product.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(color: context.appColors.info),
                    ),
                  ),
                  // 🔴 Low Stock Badge
                  if (isLowStock)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: context.appColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.appColors.onPrimary, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isLowStock) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.appColors.primary,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.appColors.primary),
                      ),
                      child: Text(
                        'LOW STOCK',
                        style: TextStyle(
                          color: context.appColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                'Stock: ${product.quantityOnHand} | Barcode: ${product.barcode ?? "N/A"}',
              ),
              trailing: Text(
                CurrencyFormatter.formatCentsToCurrency(product.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.appColors.primary,
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
