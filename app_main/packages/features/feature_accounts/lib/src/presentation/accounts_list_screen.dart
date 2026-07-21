import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/src/presentation/accounts_list_provider.dart';
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

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      return null; // Handle zebra striping in cells or map index
                    },
                  ),
                  columns: [
                    DataColumn(label: Text(l10n.accountNameHint)),
                    DataColumn(label: Text(l10n.accountType)),
                    DataColumn(label: Text(l10n.debitBalance)),
                    DataColumn(label: Text(l10n.creditBalance)),
                  ],
                  rows: filteredAccounts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final account = entry.value;
                    final summary = summariesMap[account.id];
                    final currentBalance =
                        (account.initialBalance / 100.0) + (summary?.netBalance ?? 0.0);

                    final isGray = index % 2 == 0;
                    final rowColor = isGray
                        ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)
                        : Theme.of(context).colorScheme.surface;

                    return DataRow(
                      color: WidgetStateProperty.all(rowColor),
                      cells: [
                        DataCell(
                          Text(account.name),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AccountLedgerScreen(account: account),
                              ),
                            );
                          },
                        ),
                        DataCell(
                          Text(_getLocalizedAccountType(account.type, l10n)),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AccountLedgerScreen(account: account),
                              ),
                            );
                          },
                        ),
                        DataCell(
                          Text(
                            currentBalance >= 0
                                ? currentBalance.toStringAsFixed(2)
                                : '0.00',
                            style: TextStyle(
                              color: currentBalance >= 0 && currentBalance != 0
                                  ? Colors.green
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AccountLedgerScreen(account: account),
                              ),
                            );
                          },
                        ),
                        DataCell(
                          Text(
                            currentBalance < 0
                                ? currentBalance.abs().toStringAsFixed(2)
                                : '0.00',
                            style: TextStyle(
                              color: currentBalance < 0 ? Colors.red : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AccountLedgerScreen(account: account),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
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
