import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:shared_ui/shared_ui.dart';

import 'vendor_detail_screen.dart';

/// 📊 AP Aging Report Screen
class APAgingReportScreen extends ConsumerWidget {
  const APAgingReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(apAgingReportProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.apAgingReport),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(apAgingReportProvider),
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
          if (report.totalPayables == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noOutstandingPayables,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.allBillsPaid,
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
                        colorScheme.tertiary,
                        colorScheme.tertiaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalPayables,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.formatAmount(report.totalPayables, currencyCode),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.vendorsWithBalances(report.vendorBalances.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
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
                        label: AppLocalizations.of(context)!.current0To30,
                        amount: report.current,
                        color: Colors.green,
                        currencyCode: currencyCode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AgingBucket(
                        label: AppLocalizations.of(context)!.days31To60,
                        amount: report.days31to60,
                        color: Colors.orange,
                        currencyCode: currencyCode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AgingBucket(
                        label: AppLocalizations.of(context)!.days61To90,
                        amount: report.days61to90,
                        color: Colors.deepOrange,
                        currencyCode: currencyCode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AgingBucket(
                        label: AppLocalizations.of(context)!.days90Plus,
                        amount: report.over90Days,
                        color: colorScheme.error,
                        currencyCode: currencyCode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  AppLocalizations.of(context)!.byVendor,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ...report.vendorBalances.map(
                  (vb) => _VendorAgingCard(
                    currencyCode: currencyCode,
                    balance: vb,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            VendorDetailScreen(vendorId: vb.vendor.id),
                      ),
                    ),
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

class _VendorAgingCard extends StatelessWidget {
  final VendorBalance balance;
  final VoidCallback onTap;
  final String currencyCode;
  const _VendorAgingCard({
    required this.balance,
    required this.onTap,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                      balance.vendor.name,
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
                    label: AppLocalizations.of(context)!.current,
                    amount: balance.current,
                    color: Colors.green,
                    currencyCode: currencyCode,
                  ),
                  const SizedBox(width: 4),
                  _MiniAgingChip(
                    label: AppLocalizations.of(context)!.days31To60Short,
                    amount: balance.days31to60,
                    color: Colors.orange,
                    currencyCode: currencyCode,
                  ),
                  const SizedBox(width: 4),
                  _MiniAgingChip(
                    label: AppLocalizations.of(context)!.days61To90Short,
                    amount: balance.days61to90,
                    color: Colors.deepOrange,
                    currencyCode: currencyCode,
                  ),
                  const SizedBox(width: 4),
                  _MiniAgingChip(
                    label: AppLocalizations.of(context)!.days90PlusShort,
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
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasAmount ? color : Colors.grey,
                fontSize: 9,
              ),
            ),
            Text(
              '${CurrencyFormatter.getCurrencySymbol(currencyCode)}${(amount / 100).toStringAsFixed(0)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasAmount ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
