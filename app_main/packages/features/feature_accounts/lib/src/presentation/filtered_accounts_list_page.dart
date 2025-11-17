import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_accounts/src/presentation/filtered_accounts_list_provider.dart';

// We will create these packages soon. These errors are expected.
import 'package:feature_transactions/feature_transactions.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:shared_services/shared_services.dart';
import 'package:feature_dashboard/feature_dashboard.dart';
import 'package:core_data/core_data.dart';

class CalculatedAccountBalance {
  final Account account;
  final double totalCombinedBalance;
  final List<AccountSummary> currencySummaries;

  CalculatedAccountBalance({
    required this.account,
    required this.totalCombinedBalance,
    required this.currencySummaries,
  });
}

final calculatedAccountBalanceProvider = Provider.family<
    AsyncValue<Map<String, CalculatedAccountBalance>>, String>(
    (ref, classificationFilter) {

  // These providers will be defined in feature_reports. This error is expected.
  final ledgerAsync = ref.watch(generalLedgerStreamProvider);
  final accountsAsync =
      ref.watch(filteredAccountsProvider(classificationFilter));

  if (!ledgerAsync.hasValue || !accountsAsync.hasValue) {
    return const AsyncLoading();
  }

  if (ledgerAsync.hasError || accountsAsync.hasError) {
    return AsyncError(
      ledgerAsync.error ?? accountsAsync.error ?? 'Error loading balances',
      StackTrace.current,
    );
  }

  final allDetails = ledgerAsync.value!;
  final accounts = accountsAsync.value!;

  final groupedByAccount = groupBy(allDetails, (detail) => detail.accountId);
  final Map<String, CalculatedAccountBalance> summariesMap = {};

  for (final account in accounts) {
    double totalCombinedBalance = account.initialBalance;
    final detailsForThisAccount = groupedByAccount[account.id] ?? [];

    final groupedByCurrency =
        groupBy(detailsForThisAccount, (d) => d.currencyCode);
    final List<AccountSummary> currencySummaries = [];

    groupedByCurrency.forEach((currencyCode, currencyDetails) {
      double totalDebit = 0.0, totalCredit = 0.0;
      for (var detail in currencyDetails) {
        if (detail.entryAmount > 0) {
          totalDebit += detail.entryAmount;
        } else {
          totalCredit += detail.entryAmount.abs();
        }
      }
      final netBalance = totalDebit - totalCredit;

      final rate =
          currencyDetails.isNotEmpty ? currencyDetails.first.currencyRate : 1.0;
      totalCombinedBalance += (netBalance * rate);

      currencySummaries.add(AccountSummary(
        accountId: account.id,
        accountName: account.name,
        currencyCode: currencyCode,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        netBalance: netBalance,
      ));
    });

    currencySummaries.sort((a, b) => a.currencyCode.compareTo(b.currencyCode));

    summariesMap[account.id] = CalculatedAccountBalance(
      account: account,
      totalCombinedBalance: totalCombinedBalance,
      currencySummaries: currencySummaries,
    );
  }

  return AsyncData(summariesMap);
});

class FilteredAccountsListPage extends ConsumerWidget {
  final String classificationFilter;

  const FilteredAccountsListPage({
    super.key,
    required this.classificationFilter,
  });

  Widget _buildExportButtons(
    BuildContext context,
    WidgetRef ref,
    List<CalculatedAccountBalance> balances,
    String title,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: l10n.exportToPDF,
            onPressed: () {
              ref
                  .read(exportServiceProvider)
                  .printDashboardPdf(balances, title, l10n: l10n);
            },
          ),
          IconButton(
            icon: Icon(Icons.description, color: Colors.green.shade700),
            tooltip: l10n.exportToExcel,
            onPressed: () {
              ref
                  .read(exportServiceProvider)
                  .exportDashboardExcel(balances, title);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.excelExportSuccess)),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final defaultCurrency = ref.watch(defaultCurrencyProvider);

    // This provider will be defined in feature_dashboard. This error is expected.
    final searchQuery = ref.watch(mainDashboardSearchProvider);

    final accountsAsync =
        ref.watch(filteredAccountsProvider(classificationFilter));
    final summariesAsync =
        ref.watch(calculatedAccountBalanceProvider(classificationFilter));

    return Scaffold(
      body: accountsAsync.when(
        data: (accounts) {
          final filteredAccounts = accounts.where((account) {
            if (searchQuery.isEmpty) {
              return true;
            }
            return account.name
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
          }).toList();

          if (filteredAccounts.isEmpty) {
            return Center(
              child: Text(searchQuery.isEmpty
                  ? l10n.noAccountsClassified(classificationFilter)
                  : l10n.noResultsFound(searchQuery)),
            );
          }

          return summariesAsync.when(
            data: (summariesMap) {
              final List<CalculatedAccountBalance> filteredBalances =
                  filteredAccounts
                      .map((account) => summariesMap[account.id])
                      .whereType<CalculatedAccountBalance>()
                      .toList();

              return Column(
                children: [
                  _buildExportButtons(
                    context,
                    ref,
                    filteredBalances,
                    l10n.accountBalances(classificationFilter),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredBalances.length,
                      itemBuilder: (context, index) {
                        final balanceData = filteredBalances[index];
                        final account = balanceData.account;
                        final totalBalance = balanceData.totalCombinedBalance;

                        final bool isSupplier =
                            classificationFilter == kClassificationSuppliers;
                        final bool isOwed = totalBalance < -0.001;
                        final bool showPaymentButton = isSupplier && isOwed;

                        final bool isDebitNature =
                            classificationFilter == kClassificationClients;

                        Color totalBalanceColor;
                        if (totalBalance == 0) {
                          totalBalanceColor = Colors.grey;
                        } else if (isDebitNature) {
                          totalBalanceColor =
                              totalBalance > 0 ? Colors.redAccent : Colors.green;
                        } else {
                          totalBalanceColor =
                              totalBalance < 0 ? Colors.redAccent : Colors.green;
                        }

                        final breakdownSummaries =
                            balanceData.currencySummaries;

                        return ListTile(
                          title: Text(account.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${totalBalance.abs().toStringAsFixed(2)} $defaultCurrency',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: totalBalanceColor,
                                  fontSize: 16,
                                ),
                              ),
                              if (breakdownSummaries.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children:
                                        breakdownSummaries.map((summary) {
                                      Color color;
                                      if (summary.netBalance == 0) {
                                        color = Colors.grey;
                                      } else if (isDebitNature) {
                                        color = summary.netBalance > 0
                                            ? Colors.redAccent
                                            : Colors.green;
                                      } else {
                                        color = summary.netBalance < 0
                                            ? Colors.redAccent
                                            : Colors.green;
                                      }
                                      return Text(
                                        '(${summary.netBalance.abs().toStringAsFixed(2)} ${summary.currencyCode})',
                                        style: TextStyle(
                                            color: color, fontSize: 12),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                          trailing: showPaymentButton
                              ? FilledButton(
                                  child: Text(l10n.pay),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MakePaymentScreen(
                                          supplierAccount: account,
                                          amountOwed: totalBalance.abs(),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : null,
                          onTap: showPaymentButton
                              ? null
                              : () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => AddAmountScreen(
                                        accountId: account.id,
                                        classificationName:
                                            classificationFilter),
                                  ));
                                },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
                child: Text('${l10n.errorLoadingSummaries} ${err.toString()}')),
          );
        },
        error: (err, stack) =>
            Center(child: Text('${l10n.errorLoadingAccounts} ${err.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addNewTransaction,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AddAmountScreen(
                accountId: null, classificationName: classificationFilter),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}