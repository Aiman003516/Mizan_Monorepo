import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/src/presentation/accounts_list_provider.dart';
import 'package:feature_accounts/src/presentation/add_account_screen.dart';

// We will create this package soon. This error is expected.
import 'package:feature_dashboard/feature_dashboard.dart'; 
// We will create this package soon. This error is expected.
import 'package:feature_reports/feature_reports.dart'; 

class AccountsListScreen extends ConsumerWidget {
  const AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // This provider will be defined in feature_dashboard. This error is expected.
    final searchQuery = ref.watch(mainDashboardSearchProvider); 

    final accountsAsync = ref.watch(accountsStreamProvider);

    // This provider will be defined in feature_reports. This error is expected.
    final summariesAsync = ref.watch(allAccountSummariesProvider); 

    return summariesAsync.when(
      data: (summariesMap) {
        return accountsAsync.when(
          data: (accounts) {
            final filteredAccounts = accounts.where((account) {
              if (searchQuery.isEmpty) return true;
              return account.name
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
            }).toList();

            if (filteredAccounts.isEmpty) {
              return Center(
                child: Text(searchQuery.isEmpty
                    ? l10n.noAccountsYet
                    : l10n.noResultsFound(searchQuery)),
              );
            }

            return ListView.builder(
              itemCount: filteredAccounts.length,
              itemBuilder: (context, index) {
                final account = filteredAccounts[index];
                final summary = summariesMap[account.id];
                final currentBalance =
                    account.initialBalance + (summary?.netBalance ?? 0.0);

                return ListTile(
                  title: Text(account.name),
                  subtitle: Text(
                      '${l10n.type} ${account.type} / ${l10n.balance} ${currentBalance.toStringAsFixed(2)}\n${account.phoneNumber != null ? '${l10n.phone} ${account.phoneNumber}' : ''}'),
                  isThreeLine: account.phoneNumber != null,
                  trailing: const Icon(Icons.edit_note),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          AddAccountScreen(accountToEdit: account),
                    ));
                  },
                );
              },
            );
          },
          error: (err, stack) => Center(
            child: Text('${l10n.errorLoadingAccounts} ${err.toString()}'),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (err, stack) => Center(
        child: Text('${l10n.errorLoadingBalances} ${err.toString()}'),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}