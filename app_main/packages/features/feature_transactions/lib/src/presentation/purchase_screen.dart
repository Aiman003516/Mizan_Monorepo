// FILE: packages/features/feature_transactions/lib/src/presentation/purchase_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as d;

// Core Imports
import 'package:core_database/core_database.dart';
import 'package:core_l10n/app_localizations.dart';

// Feature Imports
import 'package:feature_products/src/data/database_provider.dart';
import 'package:feature_accounts/feature_accounts.dart';
import 'package:feature_products/feature_products.dart' hide accountsRepositoryProvider;
// FIX: Un-hide databaseProvider so we can use it!

const _uuid = Uuid();

class PurchaseItem {
  final Product product;
  final double quantity;
  final double cost;
  PurchaseItem({
    required this.product,
    required this.quantity,
    required this.cost,
  });
}

final _supplierAccountsProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountsRepositoryProvider).watchAccountsByClassification(
    kClassificationSuppliers,
  );
});

final _allProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productsRepositoryProvider).watchAllProducts();
});

class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  Account? _selectedSupplier;
  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();

  final List<PurchaseItem> _items = [];

  void _addItem() {
    if (_selectedProduct != null &&
        _quantityController.text.isNotEmpty &&
        _costController.text.isNotEmpty) {
      final quantity = double.tryParse(_quantityController.text);
      final cost = double.tryParse(_costController.text);

      if (quantity != null && cost != null && quantity > 0 && cost >= 0) {
        setState(() {
          _items.add(PurchaseItem(
            product: _selectedProduct!,
            quantity: quantity,
            cost: cost,
          ));
        });
        _selectedProduct = null;
        _quantityController.clear();
        _costController.clear();
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _savePurchase() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      final db = ref.read(databaseProvider); // Now valid because we imported it
      final productsRepo = ref.read(productsRepositoryProvider);
      final accountsRepo = ref.read(accountsRepositoryProvider);

      final inventoryAccountId = await accountsRepo.getAccountIdByName(kInventoryAccountName);
      if (inventoryAccountId == null) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(l10n.criticalAccountError),
          backgroundColor: Colors.red,
        ));
        return;
      }

      final supplier = _selectedSupplier!;
      double totalCost = 0.0;
      for (final item in _items) {
        totalCost += item.cost * item.quantity;
      }
      
      // FIX: Convert Double Total to Cents (Int)
      final int totalCostCents = (totalCost * 100).round();

      try {
        await db.transaction(() async {
          final now = DateTime.now();
          final newTransactionId = _uuid.v4();

          await db.into(db.transactions).insert(TransactionsCompanion.insert(
            id: d.Value(newTransactionId),
            description: l10n.purchaseFrom(supplier.name),
            transactionDate: now,
          ));

          await db.into(db.transactionEntries).insert(TransactionEntriesCompanion.insert(
            transactionId: newTransactionId,
            accountId: inventoryAccountId,
            amount: totalCostCents, // Pass Int
          ));

          await db.into(db.transactionEntries).insert(TransactionEntriesCompanion.insert(
            transactionId: newTransactionId,
            accountId: supplier.id,
            amount: -totalCostCents, // Pass Int
          ));

          for (final item in _items) {
            await productsRepo.addStockToProduct(
              productId: item.product.id,
              quantityPurchased: item.quantity,
              costPerItem: item.cost, 
            );
          }
        });

        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(l10n.purchaseSaved),
          backgroundColor: Colors.green,
        ));
        navigator.pop();

      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(l10n.failedToSavePurchase(e.toString())),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suppliersAsync = ref.watch(_supplierAccountsProvider);
    final productsAsync = ref.watch(_allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchaseScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: l10n.save,
            onPressed: (_selectedSupplier != null && _items.isNotEmpty)
                ? _savePurchase
                : null,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: suppliersAsync.when(
                data: (suppliers) => DropdownButtonFormField<Account>(
                  value: _selectedSupplier,
                  hint: Text(l10n.selectSupplier),
                  isExpanded: true,
                  items: suppliers.map((account) {
                    return DropdownMenuItem<Account>(
                      value: account,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSupplier = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? l10n.pleaseSelectSupplier : null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text("Error: ${e.toString()}"),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: productsAsync.when(
                data: (products) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<Product>(
                          value: _selectedProduct,
                          hint: Text(l10n.addProduct),
                          isExpanded: true,
                          items: products.map((product) {
                            return DropdownMenuItem<Product>(
                              value: product,
                              child: Text(product.name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProduct = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(labelText: l10n.quantityShort),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _costController,
                          decoration: InputDecoration(labelText: l10n.costPerItem),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: _addItem,
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => Text("Error: ${e.toString()}"),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final total = item.cost * item.quantity;
                  return ListTile(
                    title: Text(item.product.name),
                    subtitle: Text(
                        "${l10n.quantityShort}: ${item.quantity} @ ${l10n.cost}: ${item.cost.toStringAsFixed(2)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(total.toStringAsFixed(2)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}