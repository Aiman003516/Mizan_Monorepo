import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_products/src/presentation/all_products_stream_provider.dart';
import 'package:feature_products/src/presentation/add_product_screen.dart';

// We will create this package soon. This error is expected.
import 'package:feature_dashboard/feature_dashboard.dart'; 

import 'dart:io';
import 'package:core_database/core_database.dart'; 

class AllProductsListWidget extends ConsumerWidget {
  const AllProductsListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // This provider will be defined in feature_dashboard. This error is expected.
    final searchQuery = ref.watch(mainDashboardSearchProvider); 
    final productsAsync = ref.watch(allProductsStreamProvider);

    return productsAsync.when(
      data: (products) {
        final filteredProducts = products.where((product) {
          if (searchQuery.isEmpty) return true;
          return product.name
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredProducts.isEmpty) {
          return Center(
            child: Text(searchQuery.isEmpty
                ? l10n.noProductsSaved
                : l10n.noResultsFound(searchQuery)),
          );
        }

        return ListView.builder(
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            final imagePath = product.imagePath;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
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
                    : const Icon(Icons.inventory_2, size: 20),
              ),
              title: Text(product.name),
              subtitle: Text('${l10n.priceLabel} ${product.price.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddProductScreen(product: product),
                  ),
                );
              },
            );
          },
        );
      },
      error: (err, stack) => Center(child: Text('${l10n.error} ${err.toString()}')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}