import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:shared_ui/shared_ui.dart';

import 'customer_detail_screen.dart';

/// 📊 AR Aging Report Screen
/// Shows accounts receivable aging buckets (Current, 30, 60, 90+ days).
class ARAgingReportScreen extends ConsumerWidget {
  const ARAgingReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(arAgingReportProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.arAgingReport),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(arAgingReportProvider);
            },
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error: $e'),
            ],
          ),
        ),
        data: (report) {
          if (report.totalReceivables == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: context.appColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noOutstandingReceivables,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: context.appColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.allInvoicesPaid,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          final currencyCode = ref.watch(currentCurrencyCodeProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.totalReceivables,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.appColors.onPrimary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.formatAmount(report.totalReceivables, currencyCode),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: context.appColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.customersWithBalances(report.customerBalances.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.appColors.onPrimary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Aging Buckets
                Row(
                  children: [
                    Expanded(
                      child: _AgingBucket(
                        label: l10n.current0To30,
                        amount: report.current,
                        color: context.appColors.success,
                        currencyCode: currencyCode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AgingBucket(
                        label: l10n.days31To60,
                        amount: report.days31to60,
                        color: context.appColors.warning,
                        currencyCode: currencyCode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AgingBucket(
                        label: l10n.days61To90,
                        amount: report.days61to90,
                        color: context.appColors.warning,
                        currencyCode: currencyCode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AgingBucket(
                        label: l10n.days90Plus,
                        amount: report.over90Days,
                        color: colorScheme.error,
                        currencyCode: currencyCode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Customer Breakdown
                Text(
                  l10n.byCustomer,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Customer List
                ...report.customerBalances.map(
                  (cb) => _CustomerAgingCard(
                    currencyCode: currencyCode,
                    balance: cb,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              CustomerDetailScreen(customerId: cb.customer.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AgingBucket extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final String currencyCode;

  const _AgingBucket({
    required this.label,
    required this.amount,
    required this.color,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyFormatter.getCurrencySymbol(currencyCode)}${(amount / 100).toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerAgingCard extends StatelessWidget {
  final CustomerBalance balance;
  final VoidCallback onTap;
  final String currencyCode;

  const _CustomerAgingCard({
    required this.balance,
    required this.onTap,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final hasOverdue =
        balance.days31to60 > 0 ||
        balance.days61to90 > 0 ||
        balance.over90Days > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      balance.customer.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatAmount(balance.balance, currencyCode),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasOverdue ? colorScheme.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MiniAgingChip(
                    label: l10n.current,
                    amount: balance.current,
                    color: context.appColors.success,
                    currencyCode: currencyCode,
                  ),
                  const SizedBox(width: 4),
                  _MiniAgingChip(
                    label: l10n.days31To60Short,
                    amount: balance.days31to60,
                    color: context.appColors.warning,
                    currencyCode: currencyCode,
                  ),
                  const SizedBox(width: 4),
                  _MiniAgingChip(
                    label: l10n.days61To90Short,
                    amount: balance.days61to90,
                    color: context.appColors.warning,
                    currencyCode: currencyCode,
                  ),
                  const SizedBox(width: 4),
                  _MiniAgingChip(
                    label: l10n.days90PlusShort,
                    amount: balance.over90Days,
                    color: colorScheme.error,
                    currencyCode: currencyCode,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAgingChip extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final String currencyCode;

  const _MiniAgingChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAmount = amount > 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: hasAmount
              ? color.withValues(alpha: 0.1)
              : context.appColors.subtleText.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasAmount ? color : context.appColors.subtleText,
                fontSize: 9,
              ),
            ),
            Text(
              '${CurrencyFormatter.getCurrencySymbol(currencyCode)}${(amount / 100).toStringAsFixed(0)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasAmount ? color : context.appColors.subtleText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
