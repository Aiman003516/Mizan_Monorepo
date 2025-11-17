import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_l10n/app_localizations.dart';
//
// 💡--- THIS IS THE FIX ---
// The provider is in the 'presentation' folder, not 'data'.
import 'package:feature_transactions/src/presentation/transactions_list_provider.dart';
//
//

class TransactionsListScreen extends ConsumerWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Text(l10n.noTransactionsYet),
          );
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return ListTile(
              title: Text(transaction.description),
              subtitle: Text(
                DateFormat.yMMMd().add_jm().format(transaction.transactionDate),
              ),
              trailing: const Text(
                '0.00', // TODO: This should show a real amount later
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              onTap: () {
                // TODO: Navigate to a "Transaction Details" screen
              },
            );
          },
        );
      },
      error: (err, stack) => Center(
        child: Text('${l10n.error} ${err.toString()}'),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}