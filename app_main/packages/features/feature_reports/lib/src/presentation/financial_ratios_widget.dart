import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import '../data/reports_service.dart';

/// Provider for financial ratios
final financialRatiosProvider = FutureProvider<FinancialRatios>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final reportsService = ref.watch(reportsServiceProvider);

  // Get balance sheet data
  final balanceSheet = await reportsService
      .watchBalanceSheet(DateTime.now())
      .first;

  // Get P&L data
  final now = DateTime.now();
  final pnl = await reportsService
      .watchProfitAndLoss(
        DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        ),
      )
      .first;

  // Get AR and AP totals
  final customers = await db.select(db.customers).get();
  double totalReceivables = 0;
  for (final c in customers) totalReceivables += c.balance / 100;

  final vendors = await db.select(db.vendors).get();
  double totalPayables = 0;
  for (final v in vendors) totalPayables += v.balance / 100;

  // Calculate ratios
  final currentAssets = balanceSheet.totalAssets; // Simplified
  final currentLiabilities = balanceSheet.totalLiabilities;
  final totalEquity = balanceSheet.totalEquity;
  final totalRevenue = pnl.totalRevenue;
  final netIncome = pnl.netIncome;

  final currentRatio = currentLiabilities != 0
      ? currentAssets / currentLiabilities
      : 0.0;
  final quickRatio = currentLiabilities != 0
      ? (currentAssets - 0) / currentLiabilities
      : 0.0; // No inventory deduction for now
  final debtToEquity = totalEquity != 0
      ? balanceSheet.totalLiabilities / totalEquity
      : 0.0;
  final netProfitMargin = totalRevenue != 0
      ? (netIncome / totalRevenue) * 100
      : 0.0;
  final returnOnAssets = balanceSheet.totalAssets != 0
      ? (netIncome / balanceSheet.totalAssets) * 100
      : 0.0;
  final workingCapital = currentAssets - currentLiabilities;
  final receivablesTurnover = totalReceivables != 0
      ? totalRevenue / totalReceivables
      : 0.0;

  return FinancialRatios(
    currentRatio: currentRatio,
    quickRatio: quickRatio,
    debtToEquity: debtToEquity,
    grossProfitMargin: 0, // Would need COGS
    netProfitMargin: netProfitMargin,
    returnOnAssets: returnOnAssets,
    workingCapital: workingCapital,
    receivablesTurnover: receivablesTurnover,
  );
});

/// 📊 Financial Ratios Widget for Dashboard
class FinancialRatiosWidget extends ConsumerWidget {
  const FinancialRatiosWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratiosAsync = ref.watch(financialRatiosProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ratiosAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
      ),
      data: (ratios) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Financial Ratios',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.analytics, color: colorScheme.primary),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Ratio Grid
              Row(
                children: [
                  Expanded(
                    child: _RatioTile(
                      label: 'Current Ratio',
                      value: ratios.currentRatio.toStringAsFixed(2),
                      icon: Icons.account_balance_wallet,
                      isGood: ratios.currentRatio >= 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RatioTile(
                      label: 'Debt/Equity',
                      value: ratios.debtToEquity.toStringAsFixed(2),
                      icon: Icons.balance,
                      isGood: ratios.debtToEquity < 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _RatioTile(
                      label: 'Net Margin',
                      value: '${ratios.netProfitMargin.toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                      isGood: ratios.netProfitMargin > 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RatioTile(
                      label: 'ROA',
                      value: '${ratios.returnOnAssets.toStringAsFixed(1)}%',
                      icon: Icons.pie_chart,
                      isGood: ratios.returnOnAssets > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Working Capital
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ratios.workingCapital >= 0
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Working Capital', style: theme.textTheme.bodyMedium),
                    Text(
                      '\$${ratios.workingCapital.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ratios.workingCapital >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatioTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isGood;

  const _RatioTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isGood ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
