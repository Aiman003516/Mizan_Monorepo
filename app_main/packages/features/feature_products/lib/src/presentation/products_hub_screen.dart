import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_products/src/presentation/add_product_screen.dart';
import 'package:feature_products/src/presentation/all_products_list_widget.dart';

class ProductsHubScreen extends ConsumerWidget {
  const ProductsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: const AllProductsListWidget(),
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