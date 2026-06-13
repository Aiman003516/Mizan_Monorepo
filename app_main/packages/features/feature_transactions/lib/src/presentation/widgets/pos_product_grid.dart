// FILE: packages/features/feature_transactions/lib/src/presentation/widgets/pos_product_grid.dart

import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:core_database/core_database.dart';

class PosProductGrid extends StatelessWidget {
  final List<Product> products;
  final void Function(Product product) onAddToCart;
  final bool isLoading;

  const PosProductGrid({
    super.key,
    required this.products,
    required this.onAddToCart,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: context.appColors.subtleText.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noProducts,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appColors.subtleText,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 4
            : constraints.maxWidth > 500
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100), // bottom padding for cart bar
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.78,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _ProductCard(
              product: products[index],
              onAdd: () => onAddToCart(products[index]),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final priceFormatted = CurrencyFormatter.formatCentsToCurrency(product.price);
    final inStock = product.quantityOnHand.round();
    final isOutOfStock = inStock <= 0;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: isOutOfStock ? null : onAdd,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Area
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.appColors.primary.withValues(alpha: 0.06),
                ),
                child: product.imagePath != null
                    ? Image.asset(
                        product.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderIcon(context),
                      )
                    : _buildPlaceholderIcon(context),
              ),
            ),

            // Product Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Price + Stock
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                priceFormatted,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isOutOfStock
                                    ? l10n.outOfStock
                                    : l10n.inStock(inStock),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isOutOfStock
                                      ? context.appColors.error
                                      : context.appColors.subtleText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add Button
                        if (!isOutOfStock)
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Material(
                              color: context.appColors.primary,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: onAdd,
                                customBorder: const CircleBorder(),
                                child: Icon(
                                  Icons.add,
                                  color: context.appColors.onPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: context.appColors.primary.withValues(alpha: 0.25),
      ),
    );
  }
}
