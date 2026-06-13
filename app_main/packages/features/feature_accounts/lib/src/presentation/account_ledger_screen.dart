// FILE: packages/features/feature_accounts/lib/src/presentation/account_ledger_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';

import 'package:feature_reports/feature_reports.dart';
import 'package:feature_transactions/feature_transactions.dart';

import 'add_account_screen.dart';

class AccountLedgerScreen extends ConsumerWidget {
  final Account account;

  const AccountLedgerScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ledgerAsync = ref.watch(generalLedgerStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.account}: ${account.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AddAccountScreen(accountToEdit: account),
                ),
              );
            },
          ),
        ],
      ),
      body: ledgerAsync.when(
        data: (allDetails) {
          final accountDetails =
              allDetails.where((d) => d.accountId == account.id).toList()..sort(
                (a, b) => b.transactionDate.compareTo(a.transactionDate),
              ); // Newest first

          // Calculate current balance including initial balance
          final netTransactions = accountDetails.fold(
            0.0,
            (sum, d) => sum + d.entryAmount,
          );
          final totalBalance =
              (account.initialBalance / 100.0) + netTransactions;

          return Column(
            children: [
              _buildBalanceCard(context, l10n, totalBalance),
              Expanded(
                child: accountDetails.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noTransactionsYet,
                          style: TextStyle(color: context.appColors.subtleText),
                        ),
                      )
                    : ListView.separated(
                        itemCount: accountDetails.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final detail = accountDetails[index];
                          final isDebit = detail.entryAmount > 0;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDebit
                                  ? context.appColors.success.withValues(
                                      alpha: 0.1,
                                    )
                                  : context.appColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                              child: Icon(
                                isDebit
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isDebit
                                    ? context.appColors.success
                                    : context.appColors.error,
                              ),
                            ),
                            title: Text(detail.transactionDescription),
                            subtitle: Text(
                              DateFormat.yMd().format(detail.transactionDate),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  detail.entryAmount.abs().toStringAsFixed(2),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDebit
                                        ? context.appColors.success
                                        : context.appColors.error,
                                  ),
                                ),
                                Text(
                                  detail.currencyCode,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.appColors.subtleText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        error: (err, stack) => Center(child: Text('${l10n.error} $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  GeneralJournalScreen(initialAccount: account),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addNewTransaction),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    AppLocalizations l10n,
    double totalBalance,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: context.appColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.balance,
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.subtleText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalBalance.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: context.appColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
