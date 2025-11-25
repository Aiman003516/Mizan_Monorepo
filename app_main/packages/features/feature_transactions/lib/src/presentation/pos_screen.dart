// FILE: packages/features/feature_transactions/lib/src/presentation/pos_screen.dart

import 'dart:io' show Platform;
import 'package:feature_accounts/feature_accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as d;
import 'package:audioplayers/audioplayers.dart';
import 'package:printing/printing.dart';

// Core Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_database/core_database.dart';
import 'package:core_data/core_data.dart';

// Shared Imports
import 'package:shared_ui/shared_ui.dart'; // Formatter

// Feature Imports
// FIX: Hide databaseProvider from feature_products to avoid conflict
import 'package:feature_products/feature_products.dart' hide databaseProvider, accountsRepositoryProvider;

// Local Feature Imports
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:feature_transactions/src/data/database_provider.dart'; // Explicit Local DB Provider
import 'package:feature_transactions/src/data/receipt_service.dart';
import 'package:feature_transactions/src/presentation/pos_receipt_provider.dart';
import 'package:feature_transactions/src/presentation/barcode_scanner_screen.dart';

// Local Provider for Payment Methods
final paymentMethodsProvider = StreamProvider<List<PaymentMethod>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.paymentMethods)).watch();
});

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();

  late final AudioPlayer _audioPlayer;
  final _beepSound = AssetSource('audio/beep.mp3');

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _refocusBarcodeScanner() {
    if (mounted) {
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
    }
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (barcode.isEmpty) return;

    final product = await ref
        .read(productsRepositoryProvider)
        .findProductByBarcode(barcode);

    if (product != null) {
      ref.read(posReceiptProvider.notifier).addItem(product);
      _audioPlayer.play(_beepSound);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productNotFound(barcode))),
      );
    }
    _refocusBarcodeScanner();
  }

  void _openMobileScanner() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BarcodeScannerScreen(
        onScan: _handleBarcodeScan,
      ),
    ));
  }

  void _showOrderDetailsDialog(BuildContext context) {
    // This reads the current state of the provider (CompanyProfileData)
    final profileData = ref.read(companyProfileProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return _OrderDetailsDialog(
              scrollController: scrollController,
              onSaveAndPrint: (PaymentMethod selectedMethod) async {
                // Pass the data down
                final result = await _saveAndPrintOrder(
                    context, selectedMethod, profileData);
                
                // If successful, close the dialog
                if (result == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        );
      },
    );
  }

  /// Returns TRUE if transaction succeeded, FALSE otherwise.
  Future<bool> _saveAndPrintOrder(
    BuildContext context,
    PaymentMethod paymentMethod,
    CompanyProfileData profileData,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final items = ref.read(posReceiptProvider);
    // posTotalAmountProvider returns Double (Dollars)
    final totalAmount = ref.read(posTotalAmountProvider);

    if (totalAmount <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.zeroTotalError)),
      );
      return false;
    }

    final accountsRepo = ref.read(accountsRepositoryProvider);
    final salesAccountId =
        await accountsRepo.getAccountIdByName(kSalesRevenueAccountName);
    
    final paymentAccountId = paymentMethod.accountId;

    if (salesAccountId == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.criticalSetupError)),
      );
      return false;
    }

    const currencyRate = 1.0;
    
    // Convert Double Total (Dollars) to Cents (Int) for DB
    final int totalCents = (totalAmount * 100).round();

    final entries = [
      TransactionEntriesCompanion.insert(
        accountId: paymentAccountId,
        amount: totalCents, // Int
        transactionId: 'TEMP',
        currencyRate: const d.Value(currencyRate),
      ),
      TransactionEntriesCompanion.insert(
        accountId: salesAccountId,
        amount: -totalCents, // Int
        transactionId: 'TEMP',
        currencyRate: const d.Value(currencyRate),
      ),
    ];

    try {
      final description =
          l10n.posSale(DateTime.now().microsecondsSinceEpoch.toString());

      await ref.read(transactionsRepositoryProvider).createPosSale(
            transactionCompanion: TransactionsCompanion.insert(
              description: description,
              transactionDate: DateTime.now(),
              attachmentPath: const d.Value(null),
              currencyCode: const d.Value('Local'),
              relatedTransactionId: const d.Value(null),
            ),
            entries: entries,
            items: items,
            totalAmount: totalAmount, // Double passed to update Order table
          );

      // --- PRINTING LOGIC ---
      try {
        final pdfData =
            await ref.read(receiptServiceProvider).generatePosReceipt(
                  items: items,
                  total: totalAmount,
                  profile: profileData,
                  l10n: l10n,
                );

        await Printing.layoutPdf(
          onLayout: (format) async => pdfData,
        );
      } catch (printError) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.saveSuccessPrintFailed(printError.toString())),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Clear cart only on success
      ref.read(posReceiptProvider.notifier).clear();
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.saleRecorded(totalAmount.toStringAsFixed(2))),
        ),
      );
      _refocusBarcodeScanner();
      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.transactionFailed} ${e.toString()}')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Platform.isWindows) {
        _refocusBarcodeScanner();
      }
    });

    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 700;

        if (isWideScreen) {
          return Row(
            children: [
              const Expanded(
                flex: 3,
                child: ProductSelectionPanel(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: ReceiptPanel(
                  barcodeController: _barcodeController,
                  barcodeFocusNode: _barcodeFocusNode,
                  onScan: _handleBarcodeScan,
                  onShowCart: () => _showOrderDetailsDialog(context),
                ),
              ),
            ],
          );
        } else {
          return Scaffold(
            body: Stack(
              children: [
                const ProductSelectionPanel(
                  bottomPadding: 100.0,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: _CartSummaryPanel(
                            isFab: false,
                            onTap: () => _showOrderDetailsDialog(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FloatingActionButton(
                        tooltip: l10n.scanBarcode,
                        onPressed: _openMobileScanner,
                        child: const Icon(Icons.barcode_reader),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// ... ProductSelectionPanel and ReceiptPanel remain unchanged ...
// They are purely presentation components.
class ProductSelectionPanel extends ConsumerWidget {
  final double bottomPadding;
  const ProductSelectionPanel({super.key, this.bottomPadding = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesStreamProvider); 

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(child: Text(l10n.pleaseAddCategory));
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: bottomPadding),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryProductList(category: category);
          },
        );
      },
      error: (err, stack) => Center(child: Text('${l10n.error} $err')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _CategoryProductList extends ConsumerWidget {
  const _CategoryProductList({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(productsByCategoryStreamProvider(category.id));

    return ExpansionTile(
      title: Text(category.name, style: Theme.of(context).textTheme.titleLarge),
      initiallyExpanded: true,
      children: [
        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return ListTile(title: Text(l10n.noProductsInCategory));
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(CurrencyFormatter.formatCentsToCurrency(product.price)),
                  trailing: const Icon(Icons.add_shopping_cart),
                  onTap: () {
                    ref.read(posReceiptProvider.notifier).addItem(product);
                  },
                );
              },
            );
          },
          error: (err, stack) => ListTile(title: Text('${l10n.error} $err')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class ReceiptPanel extends ConsumerWidget {
  final TextEditingController barcodeController;
  final FocusNode barcodeFocusNode;
  final Future<void> Function(String) onScan;
  final VoidCallback onShowCart;

  const ReceiptPanel({
    super.key,
    required this.barcodeController,
    required this.barcodeFocusNode,
    required this.onScan,
    required this.onShowCart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextFormField(
            controller: barcodeController,
            focusNode: barcodeFocusNode,
            decoration: InputDecoration(
              labelText: l10n.scanProductBarcode,
              prefixIcon: const Icon(Icons.barcode_reader),
              border: const OutlineInputBorder(),
            ),
            onFieldSubmitted: (value) {
              onScan(value);
            },
          ),
        ),
        const Expanded(
          child: Center(
            child: Icon(Icons.shopping_cart_checkout,
                size: 80, color: Colors.black12),
          ),
        ),
        _CartSummaryPanel(
          isFab: false,
          onTap: onShowCart,
        ),
      ],
    );
  }
}

class _CartSummaryPanel extends ConsumerWidget {
  final bool isFab;
  final VoidCallback onTap;

  const _CartSummaryPanel({required this.isFab, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(posReceiptProvider);
    final total = ref.watch(posTotalAmountProvider);
    
    final itemCount = items.length;

    if (itemCount == 0 && isFab) {
      return const SizedBox.shrink();
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isFab ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.cart}: $itemCount ${l10n.items}',
          style: isFab
              ? const TextStyle(fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${l10n.total}: ${total.toStringAsFixed(2)}',
          style: isFab
              ? null
              : Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );

    if (isFab) {
      return FloatingActionButton.extended(
        onPressed: onTap,
        icon: const Icon(Icons.shopping_cart),
        label: content,
      );
    }

    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

// ⭐️ UPDATED: Concurrency Lock Implementation ⭐️
class _OrderDetailsDialog extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Future<void> Function(PaymentMethod) onSaveAndPrint;

  const _OrderDetailsDialog({
    required this.scrollController,
    required this.onSaveAndPrint,
  });

  @override
  ConsumerState<_OrderDetailsDialog> createState() =>
      _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends ConsumerState<_OrderDetailsDialog> {
  String? _selectedPaymentMethodId;
  
  // 🔒 THE MUTEX: Prevents double taps
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final receiptItems = ref.watch(posReceiptProvider);
    final total = ref.watch(posTotalAmountProvider);

    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.orderDetails,
                  style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close),
                // Disable close while processing to be safe
                onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: receiptItems.isEmpty
                ? Center(child: Text(l10n.cart))
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: receiptItems.length,
                    itemBuilder: (context, index) {
                      final item = receiptItems[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                            '${l10n.quantity} ${item.quantity} @ ${CurrencyFormatter.formatCentsToCurrency(item.product.price)}'),
                        trailing: Text(
                          CurrencyFormatter.formatCentsToCurrency(
                             (item.product.price * item.quantity).round()
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(thickness: 2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.total,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(
                  total.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          paymentMethodsAsync.when(
            data: (paymentMethods) {
              if (paymentMethods.isEmpty) {
                return Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(l10n.criticalSetupError),
                  ),
                );
              }

              if (_selectedPaymentMethodId == null &&
                  paymentMethods.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedPaymentMethodId = paymentMethods.first.id;
                    });
                  }
                });
              }

              return DropdownButtonFormField<String>(
                value: _selectedPaymentMethodId,
                hint: Text(l10n.selectPaymentMethod),
                isExpanded: true,
                // Disable dropdown while processing
                onChanged: _isProcessing 
                    ? null 
                    : (value) {
                        setState(() {
                          _selectedPaymentMethodId = value;
                        });
                      },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method.id,
                    child: Text(method.name),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? l10n.fieldRequired : null,
              );
            },
            error: (err, stack) =>
                Text(l10n.errorLoadingPaymentMethods(err.toString())),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: Text(l10n.clearOrder),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: (_isProcessing) 
                    ? null 
                    : () {
                        ref.read(posReceiptProvider.notifier).clear();
                        Navigator.of(context).pop();
                      },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: _isProcessing 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(
                            strokeWidth: 2, 
                            color: Colors.white
                          )
                        ) 
                      : const Icon(Icons.print),
                  label: Text(_isProcessing ? l10n.saving : l10n.printAndSave),
                  // 🔒 LOCK: Button is disabled if processing
                  onPressed: (receiptItems.isEmpty ||
                          _selectedPaymentMethodId == null ||
                          _isProcessing)
                      ? null
                      : () async {
                          // 1. ENGAGE LOCK
                          setState(() {
                            _isProcessing = true;
                          });

                          try {
                            final methods =
                                await ref.read(paymentMethodsProvider.future);
                            final selectedMethod = methods.firstWhere(
                              (m) => m.id == _selectedPaymentMethodId,
                              orElse: () => methods.first,
                            );
                            
                            // 2. EXECUTE TRANSACTION
                            await widget.onSaveAndPrint(selectedMethod);
                          } finally {
                            // 3. RELEASE LOCK (If widget is still alive)
                            // Note: If success, the dialog closes, so this might not run.
                            // That is fine. If failure, this re-enables the button.
                            if (mounted) {
                              setState(() {
                                _isProcessing = false;
                              });
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}