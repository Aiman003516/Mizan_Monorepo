import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/src/presentation/accounts_list_provider.dart';
import 'package:feature_accounts/src/presentation/add_account_screen.dart';
import 'package:feature_accounts/src/presentation/account_ledger_screen.dart';

import 'package:shared_services/shared_services.dart';
import 'package:feature_reports/feature_reports.dart';

class AccountsListScreen extends ConsumerWidget {
  const AccountsListScreen({super.key});

  static String _getLocalizedAccountType(String type, AppLocalizations l10n) {
    switch (type.toLowerCase()) {
      case 'asset':
        return l10n.accountTypeAsset;
      case 'liability':
        return l10n.accountTypeLiability;
      case 'equity':
        return l10n.accountTypeEquity;
      case 'revenue':
        return l10n.accountTypeRevenue;
      case 'expense':
        return l10n.accountTypeExpense;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final searchQuery = ref.watch(mainDashboardSearchProvider);

    final accountsAsync = ref.watch(accountsStreamProvider);

    final summariesAsync = ref.watch(allAccountSummariesProvider);

    return summariesAsync.when(
      data: (summariesMap) {
        return accountsAsync.when(
          data: (accounts) {
            final filteredAccounts = accounts.where((account) {
              if (searchQuery.isEmpty) return true;
              return account.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
            }).toList();

            if (filteredAccounts.isEmpty) {
              return Center(
                child: Text(
                  searchQuery.isEmpty
                      ? l10n.noAccountsYet
                      : l10n.noResultsFound(searchQuery),
                ),
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
                    '\u200E${l10n.type} ${_getLocalizedAccountType(account.type, l10n)} \u200E/ \u200E${l10n.balance} ${currentBalance.toStringAsFixed(2)}\n${account.phoneNumber != null ? '\u200E${l10n.phone} ${account.phoneNumber}' : ''}',
                  ),
                  isThreeLine: account.phoneNumber != null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AccountLedgerScreen(account: account),
                      ),
                    );
                  },
                );
              },
            );
          },
          error: (err, stack) => Center(
            child: Text('${l10n.errorLoadingAccounts} ${err.toString()}'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
      },
      error: (err, stack) =>
          Center(child: Text('${l10n.errorLoadingBalances} ${err.toString()}')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
