import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_products/src/data/categories_repository.dart';
import 'package:feature_products/src/data/products_repository.dart';
import 'package:feature_products/src/presentation/add_product_screen.dart';
import 'package:feature_products/src/presentation/all_products_stream_provider.dart';
import 'package:shared_ui/shared_ui.dart';

class AllProductsListWidget extends ConsumerStatefulWidget {
  const AllProductsListWidget({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  ConsumerState<AllProductsListWidget> createState() =>
      _AllProductsListWidgetState();
}

class _AllProductsListWidgetState extends ConsumerState<AllProductsListWidget> {
  late String? _selectedCategoryId = widget.initialCategoryId;
  String _searchQuery = '';
  bool _onlyLowStock = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyCode = ref.watch(currentCurrencyCodeProvider);
    final productsAsync = ref.watch(allProductsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categories = categoriesAsync.valueOrNull ?? const <Category>[];
    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          l10n.errorLoadingData,
          style: TextStyle(color: colorScheme.error),
        ),
      ),
      data: (products) {
        final query = _searchQuery.trim().toLowerCase();
        final filteredProducts = products.where((product) {
          final matchesSearch =
              query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              (product.barcode?.toLowerCase().contains(query) ?? false);
          final matchesCategory =
              _selectedCategoryId == null ||
              product.categoryId == _selectedCategoryId;
          final isLowStock =
              product.quantityOnHand < product.reorderPoint &&
              product.reorderPoint > 0;
          return matchesSearch &&
              matchesCategory &&
              (!_onlyLowStock || isLowStock);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchProducts,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.cancel,
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        ),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: Text(l10n.allCategories),
                    selected: _selectedCategoryId == null,
                    onSelected: (_) =>
                        setState(() => _selectedCategoryId = null),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map(
                    (category) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(category.name),
                        selected: _selectedCategoryId == category.id,
                        onSelected: (_) =>
                            setState(() => _selectedCategoryId = category.id),
                      ),
                    ),
                  ),
                  FilterChip(
                    label: Text(l10n.lowStock),
                    selected: _onlyLowStock,
                    avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                    onSelected: (selected) =>
                        setState(() => _onlyLowStock = selected),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? _EmptyProductsState(
                      message: products.isEmpty
                          ? l10n.noProducts
                          : l10n.noResultsFound(_searchQuery),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final categoryName = categoryNames[product.categoryId];
                        return _ProductCard(
                          product: product,
                          categoryName: categoryName,
                          currencyCode: currencyCode,
                          onEdit: () async {
                            final saved = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => AddProductScreen(
                                      productToEdit: product,
                                    ),
                                  ),
                                );
                            if (saved == true) {
                              ref.invalidate(allProductsStreamProvider);
                            }
                          },
                          onAdjustStock: () => _showStockAdjustmentDialog(
                            context,
                            product,
                            l10n,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStockAdjustmentDialog(
    BuildContext context,
    Product product,
    AppLocalizations l10n,
  ) async {
    final quantityController = TextEditingController();
    final costController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var addStock = true;

    final adjustment = await showDialog<_StockAdjustment>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final quantityLabel = addStock
                ? l10n.quantityToAdd
                : l10n.quantityToRemove;
            return AlertDialog(
              title: Text(l10n.adjustStock),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${l10n.currentStock}: ${product.quantityOnHand}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: true,
                            label: Text(l10n.addStock),
                            icon: const Icon(Icons.add),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text(l10n.removeStock),
                            icon: const Icon(Icons.remove),
                          ),
                        ],
                        selected: {addStock},
                        onSelectionChanged: (selection) =>
                            setDialogState(() => addStock = selection.first),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: quantityLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final quantity = double.tryParse(value?.trim() ?? '');
                          if (quantity == null ||
                              !quantity.isFinite ||
                              quantity <= 0) {
                            return l10n.invalidQuantity;
                          }
                          if (!addStock && quantity > product.quantityOnHand) {
                            return l10n.invalidQuantity;
                          }
                          return null;
                        },
                      ),
                      if (addStock) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: costController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.costPerItem,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final cost = double.tryParse(value?.trim() ?? '');
                            if (cost == null || !cost.isFinite || cost < 0) {
                              return l10n.invalidNumber;
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(dialogContext).pop(
                      _StockAdjustment(
                        quantity: double.parse(quantityController.text.trim()),
                        costPerItem: addStock
                            ? double.parse(costController.text.trim())
                            : 0,
                        add: addStock,
                      ),
                    );
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();
    costController.dispose();
    if (adjustment == null || !mounted) return;

    try {
      await ref
          .read(productsRepositoryProvider)
          .adjustStock(
            productId: product.id,
            quantityDelta: adjustment.add
                ? adjustment.quantity
                : -adjustment.quantity,
            costPerItem: adjustment.costPerItem,
          );
      ref.invalidate(allProductsStreamProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.stockUpdated)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.stockUpdateFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _StockAdjustment {
  const _StockAdjustment({
    required this.quantity,
    required this.costPerItem,
    required this.add,
  });

  final double quantity;
  final double costPerItem;
  final bool add;
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.currencyCode,
    required this.onEdit,
    required this.onAdjustStock,
  });

  final Product product;
  final String? categoryName;
  final String currencyCode;
  final VoidCallback onEdit;
  final VoidCallback onAdjustStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLowStock =
        product.quantityOnHand < product.reorderPoint &&
        product.reorderPoint > 0;
    final stockColor = product.quantityOnHand <= 0
        ? colorScheme.error
        : isLowStock
        ? colorScheme.tertiary
        : colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: Text(
                      product.name.isEmpty
                          ? '?'
                          : product.name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      CurrencyFormatter.formatCentsToCurrency(
                        product.price,
                        symbol: CurrencyFormatter.getCurrencySymbol(
                          currencyCode,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (categoryName != null)
                    _MetaChip(
                      icon: Icons.category_outlined,
                      label: categoryName!,
                    ),
                  _MetaChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${product.quantityOnHand}',
                    color: stockColor,
                  ),
                  if (isLowStock)
                    _StatusChip(
                      label: AppLocalizations.of(context)!.lowStock,
                      color: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                    ),
                  if (product.barcode != null && product.barcode!.isNotEmpty)
                    _MetaChip(icon: Icons.qr_code_2, label: product.barcode!),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onAdjustStock,
                    icon: const Icon(Icons.swap_vert, size: 18),
                    label: Text(AppLocalizations.of(context)!.adjustStock),
                  ),
                  IconButton(
                    tooltip: AppLocalizations.of(context)!.editProduct,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = color ?? colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: foreground, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.foregroundColor,
  });

  final String label;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
