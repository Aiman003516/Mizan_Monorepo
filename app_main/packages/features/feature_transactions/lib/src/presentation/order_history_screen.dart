import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_database/core_database.dart' as c;
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_reports/feature_reports.dart'; // FIX: Import feature_reports
import 'package:feature_transactions/src/presentation/order_details_screen.dart';
import 'package:feature_transactions/src/presentation/order_history_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    final historyAsync = ref.watch(posSalesHistoryProvider);
    final returnsAsync = ref.watch(posReturnsProvider);
    final ledgerAsync = ref.watch(generalLedgerStreamProvider); // This is from feature_reports

    return Scaffold(
      body: historyAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(child: Text(l10n.noSalesYet));
          }

          return returnsAsync.when(
            data: (returns) {
              final returnedIds =
                  returns.map((r) => r.relatedTransactionId).toSet();

              return ledgerAsync.when(
                data: (ledgerEntries) {
                  final entriesMap = <String, List<TransactionDetail>>{};
                  for (var entry in ledgerEntries) {
                    (entriesMap[entry.transactionId] ??= []).add(entry);
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final entries = entriesMap[transaction.id] ?? [];
                      
                      final bool isReturned = returnedIds.contains(transaction.id);

                      final saleEntry = entries.firstWhere(
                        (e) => e.accountName == c.kSalesRevenueAccountName,
                        orElse: () => TransactionDetail(
                          transactionId: transaction.id,
                          transactionDescription: '',
                          transactionDate: DateTime.now(),
                          entryAmount: 0.0,
                          accountId: '',
                          accountName: '',
                          accountType: '',
                          currencyCode: 'Local',
                          currencyRate: 1.0,
                        ),
                      );

                      final totalAmount = saleEntry.entryAmount.abs();

                      return ListTile(
                        leading: isReturned
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary)
                            : Icon(Icons.receipt,
                                color: Theme.of(context).colorScheme.secondary),
                        title: Text(transaction.description),
                        subtitle: Text(
                          DateFormat.yMMMd(l10n.localeName)
                              .add_jm()
                              .format(transaction.transactionDate),
                        ),
                        trailing: isReturned
                            ? Chip(
                                label: Text(l10n.returned),
                                backgroundColor:
                                    Theme.of(context).colorScheme.errorContainer,
                              )
                            : Text(
                                '${totalAmount.toStringAsFixed(2)} ${transaction.currencyCode}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(
                                transaction: transaction,
                                entries: entries,
                                totalAmount: totalAmount,
                                isReturned: isReturned,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                error: (err, stack) =>
                    Center(child: Text('${l10n.error}: ${err.toString()}')),
                loading: () => const Center(child: CircularProgressIndicator()),
              );
            },
            error: (err, stack) =>
                Center(child: Text('${l10n.error}: ${err.toString()}')),
            loading: () => const Center(child: CircularProgressIndicator()),
          );
        },
        error: (err, stack) =>
            Center(child: Text('${l10n.error}: ${err.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}