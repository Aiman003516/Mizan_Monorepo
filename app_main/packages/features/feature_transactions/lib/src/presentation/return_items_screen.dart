import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_reports/feature_reports.dart'; // FIX: Import feature_reports
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:core_database/src/initial_constants.dart' as c;

class ReturnItemsScreen extends ConsumerStatefulWidget {
  final Order order;
  final List<TransactionDetail> entries; // This class comes from feature_reports

  const ReturnItemsScreen({
    super.key,
    required this.order,
    required this.entries,
  });

  @override
  ConsumerState<ReturnItemsScreen> createState() => _ReturnItemsScreenState();
}

class _ReturnItemsScreenState extends ConsumerState<ReturnItemsScreen> {
  late final Map<String, double> _itemsToReturn;
  bool _isProcessing = false;
  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _itemsToReturn = {};
  }

  double _calculateTotalRefund(List<OrderItem> items) {
    double total = 0.0;
    for (final item in items) {
      final quantityToReturn = _itemsToReturn[item.id] ?? 0.0;
      total += quantityToReturn * item.priceAtSale;
    }
    return total;
  }

  (String?, String?) _getFinancialAccountIds() {
    final TransactionDetail? salesEntry = widget.entries
        .where(
          (e) => e.accountName == c.kSalesRevenueAccountName,
        )
        .firstOrNull;

    final TransactionDetail? paymentEntry = widget.entries
        .where(
          (e) => e.accountType == 'asset' && e.entryAmount > 0,
        )
        .firstOrNull;

    return (paymentEntry?.accountId, salesEntry?.accountId);
  }

  Future<void> _processPartialReturn(
      List<OrderItem> items, AppLocalizations l10n) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final Map<OrderItem, double> returnMap = {};
    for (final item in items) {
      final quantityToReturn = _itemsToReturn[item.id] ?? 0.0;
      if (quantityToReturn > 0) {
        returnMap[item] = quantityToReturn;
      }
    }

    final totalRefundAmount = _calculateTotalRefund(items);

    if (totalRefundAmount <= 0) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noItemsSelected)));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    final (paymentAccountId, salesAccountId) = _getFinancialAccountIds();
    if (paymentAccountId == null || salesAccountId == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.criticalSetupError)));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    bool success = false;

    try {
      await ref.read(transactionsRepositoryProvider).processPartialReturn(
            originalTransactionId: widget.order.transactionId,
            originalPaymentAccountId: paymentAccountId,
            originalSalesAccountId: salesAccountId,
            itemsToReturn: returnMap,
            totalRefundAmount: totalRefundAmount,
            currencyCode: widget.entries.firstOrNull?.currencyCode ?? 'Local',
            returnDescription: l10n.partialReturnFor(widget.order.id.substring(0, 8)),
          );

      success = true;
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('${l10n.returnFailed}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }

    if (success && mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.returnSuccess),
        backgroundColor: Colors.green,
      ));

      if (navigator.canPop()) navigator.pop();
      if (navigator.canPop()) navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orderItemsAsync =
        ref.watch(orderItemsStreamProvider(widget.order.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageReturn),
      ),
      body: orderItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.noLineItemsSaved));
          }

          final returnableItems = items
              .where((item) => item.quantity > item.quantityReturned)
              .toList();

          if (returnableItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.orderFullyReturned,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!_isMapInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              final newEntries = <String, double>{};
              for (final item in returnableItems) {
                if (!_itemsToReturn.containsKey(item.id)) {
                  newEntries[item.id] = 0.0;
                }
              }

              if (newEntries.isNotEmpty) {
                setState(() {
                  _itemsToReturn.addAll(newEntries);
                  _isMapInitialized = true;
                });
              } else {
                  setState(() {
                    _isMapInitialized = true;
                  });
              }
            });

            return const Center(child: CircularProgressIndicator());
          }

          final totalRefund = _calculateTotalRefund(returnableItems);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: returnableItems.length,
                  itemBuilder: (context, index) {
                    final item = returnableItems[index];
                    final maxReturnable = item.quantity - item.quantityReturned;
                    final currentSelection =
                        _itemsToReturn[item.id]?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                                '${l10n.price}: ${item.priceAtSale.toStringAsFixed(2)}'),
                            Text(
                                '${l10n.purchased}: ${item.quantity.toString()}'),
                            Text(
                                '${l10n.returned}: ${item.quantityReturned.toString()}'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.returnQuantity,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                DropdownButton<double>(
                                  value: currentSelection,
                                  items: List.generate(
                                    maxReturnable.toInt() + 1,
                                    (i) => DropdownMenuItem(
                                      value: i.toDouble(),
                                      child: Text(i.toString()),
                                    ),
                                  ),
                                  onChanged: _isProcessing
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _itemsToReturn[item.id] =
                                                value ?? 0.0;
                                          });
                                        },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Material(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isProcessing)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.totalRefund,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall),
                            Text(totalRefund.toStringAsFixed(2),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.history),
                          label: Text(l10n.processReturn),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          onPressed: totalRefund <= 0
                              ? null
                              : () =>
                                  _processPartialReturn(returnableItems, l10n),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}