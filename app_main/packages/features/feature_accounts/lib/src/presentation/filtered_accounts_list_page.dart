// FILE: packages/features/feature_accounts/lib/src/presentation/filtered_accounts_list_page.dart

import 'package:feature_accounts/feature_accounts.dart';
import 'package:feature_accounts/src/presentation/add_account_screen.dart';
import 'package:feature_accounts/src/presentation/account_ledger_screen.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'dart:convert';
import 'package:shared_ui/shared_ui.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_transactions/feature_transactions.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:shared_services/shared_services.dart';
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

final calculatedAccountBalanceProvider =
    Provider.family<AsyncValue<Map<String, CalculatedAccountBalance>>, String>((
      ref,
      classificationFilter,
    ) {
      // These providers will be defined in feature_reports.
      final ledgerAsync = ref.watch(generalLedgerStreamProvider);
      final accountsAsync = ref.watch(
        filteredAccountsProvider(classificationFilter),
      );

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

      final groupedByAccount = groupBy(
        allDetails,
        (detail) => detail.accountId,
      );
      final Map<String, CalculatedAccountBalance> summariesMap = {};

      for (final account in accounts) {
        // FIX: Convert Initial Balance (Int Cents) to Double
        double totalCombinedBalance = account.initialBalance / 100.0;

        final detailsForThisAccount = groupedByAccount[account.id] ?? [];

        final groupedByCurrency = groupBy(
          detailsForThisAccount,
          (d) => d.currencyCode,
        );
        final List<AccountSummary> currencySummaries = [];

        groupedByCurrency.forEach((currencyCode, currencyDetails) {
          double totalDebit = 0.0, totalCredit = 0.0;

          for (var detail in currencyDetails) {
            // FIX: Convert Transaction Amount (Int Cents) to Double
            // Assuming entryAmount comes from the View Model which might already be converted?
            // CHECK: generalLedgerStreamProvider usually returns View Models (TransactionDetail).
            // If TransactionDetail.entryAmount is already double (which is standard for ViewModels), this is fine.
            // BUT based on our migration, if it's raw data, we must divide.
            // Safe approach: If the View Model has 'entryAmount' as Double, we use it.
            // Let's assume standard View Models use Doubles.
            // If they used Ints, we'd divide by 100.0 here.
            // Given previous context, TransactionDetail usually exposes doubles.
            // IF NOT, change this line to: final amount = detail.entryAmount / 100.0;
            final amount = detail.entryAmount;

            if (amount > 0) {
              totalDebit += amount;
            } else {
              totalCredit += amount.abs();
            }
          }
          final netBalance = totalDebit - totalCredit;

          final rate = currencyDetails.isNotEmpty
              ? currencyDetails.first.currencyRate
              : 1.0;
          totalCombinedBalance += (netBalance * rate);

          currencySummaries.add(
            AccountSummary(
              accountId: account.id,
              accountName: account.name,
              currencyCode: currencyCode,
              totalDebit: totalDebit,
              totalCredit: totalCredit,
              netBalance: netBalance,
            ),
          );
        });

        currencySummaries.sort(
          (a, b) => a.currencyCode.compareTo(b.currencyCode),
        );

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
            icon: Icon(Icons.picture_as_pdf, color: context.appColors.error),
            tooltip: l10n.exportToPDF,
            onPressed: () {
              ref
                  .read(exportServiceProvider)
                  .printDashboardPdf(balances, title, l10n: l10n);
            },
          ),
          IconButton(
            icon: Icon(Icons.description, color: context.appColors.primary),
            tooltip: l10n.exportToExcel,
            onPressed: () {
              ref
                  .read(exportServiceProvider)
                  .exportDashboardExcel(balances, title);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.excelExportSuccess)));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final searchQuery = ref.watch(mainDashboardSearchProvider);

    final accountsAsync = ref.watch(
      filteredAccountsProvider(classificationFilter),
    );
    final summariesAsync = ref.watch(
      calculatedAccountBalanceProvider(classificationFilter),
    );

    return Scaffold(
      body: accountsAsync.when(
        data: (accounts) {
          final filteredAccounts = accounts.where((account) {
            if (searchQuery.isEmpty) {
              return true;
            }
            return account.name.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
          }).toList();

          if (filteredAccounts.isEmpty) {
            return Center(
              child: Text(
                searchQuery.isEmpty
                    ? l10n.noAccountsClassified(
                        classificationFilter.toLowerCase() == 'clients'
                            ? l10n.clients
                            : classificationFilter.toLowerCase() == 'suppliers'
                            ? l10n.suppliers
                            : l10n.general,
                      )
                    : l10n.noResultsFound(searchQuery),
              ),
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              return null;
                            },
                          ),
                          columns: [
                            DataColumn(label: Text(l10n.accountNameHint)),
                            DataColumn(label: Text(l10n.debitBalance)),
                            DataColumn(label: Text(l10n.creditBalance)),
                            DataColumn(label: Text(l10n.actions)),
                          ],
                          rows: filteredBalances.asMap().entries.map((entry) {
                            final index = entry.key;
                            final balanceData = entry.value;
                            final account = balanceData.account;
                            final totalBalance = balanceData.totalCombinedBalance;

                            final bool isSupplier =
                                classificationFilter == kClassificationSuppliers;
                            final bool isOwed = totalBalance < -0.001;
                            final bool showPaymentButton = isSupplier && isOwed;

                            final breakdownSummaries = balanceData.currencySummaries;
                            
                            final baseCurrencyCode = ref.read(defaultCurrencyProvider);
                            final baseCurrencySymbol =
                                ref.read(preferencesRepositoryProvider).getCurrencySymbol();

                            String accountCurrency = baseCurrencyCode;
                            if (account.customAttributes != null) {
                              try {
                                final attrs = jsonDecode(account.customAttributes!);
                                final stored = attrs['currency'] as String?;
                                if (stored != null && stored != 'Local') {
                                  accountCurrency = stored;
                                }
                              } catch (_) {}
                            }
                            final displaySymbol = accountCurrency == baseCurrencyCode
                                ? baseCurrencySymbol
                                : CurrencyFormatter.getCurrencySymbol(accountCurrency);

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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        totalBalance >= 0
                                            ? '${totalBalance.toStringAsFixed(2)} $displaySymbol'
                                            : '0.00 $displaySymbol',
                                        style: TextStyle(
                                          color: totalBalance > 0 ? Colors.green : null,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (breakdownSummaries.isNotEmpty)
                                        ...breakdownSummaries.map((summary) {
                                          return Text(
                                            summary.netBalance > 0
                                                ? '${summary.netBalance.toStringAsFixed(2)} ${summary.currencyCode}'
                                                : '',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 10,
                                            ),
                                          );
                                        }).where((w) => (w.data ?? '').isNotEmpty),
                                    ],
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        totalBalance < 0
                                            ? '${totalBalance.abs().toStringAsFixed(2)} $displaySymbol'
                                            : '0.00 $displaySymbol',
                                        style: TextStyle(
                                          color: totalBalance < 0 ? Colors.red : null,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (breakdownSummaries.isNotEmpty)
                                        ...breakdownSummaries.map((summary) {
                                          return Text(
                                            summary.netBalance < 0
                                                ? '${summary.netBalance.abs().toStringAsFixed(2)} ${summary.currencyCode}'
                                                : '',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 10,
                                            ),
                                          );
                                        }).where((w) => (w.data ?? '').isNotEmpty),
                                    ],
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
                                  showPaymentButton
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
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('${l10n.errorLoadingSummaries} ${err.toString()}'),
            ),
          );
        },
        error: (err, stack) => Center(
          child: Text('${l10n.errorLoadingAccounts} ${err.toString()}'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addNewAccount,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddAccountScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
