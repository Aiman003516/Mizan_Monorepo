import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/src/presentation/accounts_list_provider.dart';
import 'package:feature_accounts/src/presentation/account_ledger_screen.dart';
import 'package:shared_services/shared_services.dart';
import 'package:shared_ui/shared_ui.dart';
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

  void _openLedger(BuildContext context, Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AccountLedgerScreen(account: account)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = ref.watch(mainDashboardSearchProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final summariesAsync = ref.watch(allAccountSummariesProvider);
    final currencyCode = ref.watch(currentCurrencyCodeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget errorState(String message) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      );
    }

    return summariesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => errorState(l10n.errorLoadingBalances),
      data: (summariesMap) => accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => errorState(l10n.errorLoadingAccounts),
        data: (accounts) {
          final query = searchQuery.trim().toLowerCase();
          final filteredAccounts = accounts.where((account) {
            return query.isEmpty || account.name.toLowerCase().contains(query);
          }).toList();

          if (filteredAccounts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  query.isEmpty
                      ? l10n.noAccountsYet
                      : l10n.noResultsFound(searchQuery),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final accountRows = filteredAccounts.map((account) {
            final summary = summariesMap[account.id];
            final currentBalance =
                (account.initialBalance / 100.0) + (summary?.netBalance ?? 0.0);
            return (account: account, balance: currentBalance);
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 720;
              if (isCompact) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  itemCount: accountRows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = accountRows[index];
                    return _AccountCard(
                      account: row.account,
                      balance: row.balance,
                      currencyCode: currencyCode,
                      localizedType: _getLocalizedAccountType(
                        row.account.type,
                        l10n,
                      ),
                      onTap: () => _openLedger(context, row.account),
                    );
                  },
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 28,
                    headingRowHeight: 52,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 72,
                    headingRowColor: WidgetStatePropertyAll(
                      colorScheme.surfaceContainerHighest,
                    ),
                    headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    columns: [
                      DataColumn(label: Text(l10n.accountNameHint)),
                      DataColumn(label: Text(l10n.accountType)),
                      DataColumn(label: Text(l10n.debitBalance)),
                      DataColumn(label: Text(l10n.creditBalance)),
                      DataColumn(label: Text(l10n.details)),
                    ],
                    rows: accountRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final account = entry.value.account;
                      final currentBalance = entry.value.balance;
                      final rowColor = index.isEven
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.28,
                            )
                          : colorScheme.surface;
                      final debit = currentBalance > 0 ? currentBalance : 0.0;
                      final credit = currentBalance < 0
                          ? currentBalance.abs()
                          : 0.0;

                      return DataRow(
                        color: WidgetStatePropertyAll(rowColor),
                        cells: [
                          DataCell(
                            Text(
                              account.name,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => _openLedger(context, account),
                          ),
                          DataCell(
                            Text(
                              _getLocalizedAccountType(account.type, l10n),
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                            onTap: () => _openLedger(context, account),
                          ),
                          DataCell(
                            Text(
                              CurrencyFormatter.formatAmount(
                                (debit * 100).round(),
                                currencyCode,
                              ),
                              style: TextStyle(
                                color: debit > 0
                                    ? colorScheme.tertiary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              CurrencyFormatter.formatAmount(
                                (credit * 100).round(),
                                currencyCode,
                              ),
                              style: TextStyle(
                                color: credit > 0
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              tooltip: l10n.details,
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              onPressed: () => _openLedger(context, account),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.balance,
    required this.currencyCode,
    required this.localizedType,
    required this.onTap,
  });

  final Account account;
  final double balance;
  final String currencyCode;
  final String localizedType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final debit = balance > 0 ? balance : 0.0;
    final credit = balance < 0 ? balance.abs() : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Icon(_iconForType(account.type)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizedType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          CurrencyFormatter.formatAmount(
                            (debit * 100).round(),
                            currencyCode,
                          ),
                          style: TextStyle(
                            color: debit > 0
                                ? colorScheme.tertiary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatAmount(
                            (credit * 100).round(),
                            currencyCode,
                          ),
                          style: TextStyle(
                            color: credit > 0
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForType(String type) {
    return switch (type.toLowerCase()) {
      'asset' => Icons.account_balance_wallet_outlined,
      'liability' => Icons.credit_card_outlined,
      'equity' => Icons.pie_chart_outline,
      'revenue' => Icons.trending_up,
      'expense' => Icons.trending_down,
      _ => Icons.account_balance_outlined,
    };
  }
}
