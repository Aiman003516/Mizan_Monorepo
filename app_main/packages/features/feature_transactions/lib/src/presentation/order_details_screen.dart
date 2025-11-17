import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_database/core_database.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_reports/feature_reports.dart'; // FIX: Import feature_reports
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:feature_transactions/src/presentation/return_items_screen.dart';


class OrderDetailsScreen extends ConsumerWidget {
  final Transaction transaction;
  final List<TransactionDetail> entries;
  final double totalAmount;
  final bool isReturned;

  const OrderDetailsScreen({
    super.key,
    required this.transaction,
    required this.entries,
    required this.totalAmount,
    required this.isReturned,
  });

  Widget _buildOrderItemsList(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final orderAsync = ref.watch(
      orderForTransactionProvider(transaction.id)
    );

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return Center(child: Text(l10n.noLineItemsSaved));
        }

        final itemsAsync = ref.watch(orderItemsStreamProvider(order.id));
        return itemsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(child: Text(l10n.noLineItemsSaved));
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final itemTotal = item.quantity * item.priceAtSale;
                      final bool isFullyReturned = item.quantityReturned >= item.quantity;

                      return ListTile(
                        title: Text(item.productName, style: TextStyle(
                          decoration: isFullyReturned ? TextDecoration.lineThrough : null,
                        )),
                        subtitle: Text(
                          '${l10n.quantity} ${item.quantity.toString()} ${l10n.atPrice(item.priceAtSale.toStringAsFixed(2))}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              itemTotal.toStringAsFixed(2),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (item.quantityReturned > 0)
                              Text(
                                '${l10n.returned}: ${item.quantityReturned.toString()}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.history),
                    label: Text(l10n.manageReturn),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ReturnItemsScreen(
                            order: order,
                            entries: entries,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
      },
      error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetails),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  DateFormat.yMMMd(l10n.localeName)
                      .add_jm()
                      .format(transaction.transactionDate),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.total,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      '${totalAmount.toStringAsFixed(2)} ${transaction.currencyCode}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),
          if (isReturned)
            Container(
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.onErrorContainer),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.orderReturned, 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildOrderItemsList(context, ref, l10n),
          ),
        ],
      ),
    );
  }
}