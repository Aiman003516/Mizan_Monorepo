// FILE: packages/features/feature_reports/lib/src/presentation/tools/financial_ratios_screen.dart
// Purpose: Financial Ratios Dashboard for comprehensive ratio analysis

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';

/// Financial Ratios Dashboard Screen
class FinancialRatiosScreen extends ConsumerStatefulWidget {
  const FinancialRatiosScreen({super.key});

  @override
  ConsumerState<FinancialRatiosScreen> createState() =>
      _FinancialRatiosScreenState();
}

class _FinancialRatiosScreenState extends ConsumerState<FinancialRatiosScreen> {
  late DateTimeRange _selectedPeriod;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedPeriod = DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, 12, 31),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratiosAsync = ref.watch(financialRatiosProvider(_selectedPeriod));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financialRatiosTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectPeriod,
            tooltip: 'Select Period',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(financialRatiosProvider(_selectedPeriod)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ratiosAsync.when(
        data: (ratios) => _buildRatiosDashboard(context, ratios, l10n),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(l10n.errorLoadingRatios, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(error.toString(), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectPeriod() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedPeriod,
    );
    if (picked != null) {
      setState(() => _selectedPeriod = picked);
    }
  }

  Widget _buildRatiosDashboard(
    BuildContext context,
    FinancialRatiosResult ratios,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period indicator
          _buildPeriodCard(),
          const SizedBox(height: 24),

          // Liquidity Ratios
          _buildSectionHeader(
            context,
            l10n.liquidityRatios,
            Icons.water_drop,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildLiquidityRatios(ratios, l10n),
          const SizedBox(height: 24),

          // Activity Ratios
          _buildSectionHeader(
            context,
            l10n.activityRatios,
            Icons.speed,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildActivityRatios(ratios, l10n),
          const SizedBox(height: 24),

          // Profitability Ratios
          _buildSectionHeader(
            context,
            l10n.profitabilityRatios,
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildProfitabilityRatios(ratios, l10n),
          const SizedBox(height: 24),

          // Leverage Ratios
          _buildSectionHeader(
            context,
            l10n.leverageRatios,
            Icons.balance,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildLeverageRatios(ratios, l10n),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPeriodCard() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analysis Period', style: theme.textTheme.labelMedium),
                  Text(
                    '${_formatDate(_selectedPeriod.start)} - ${_formatDate(_selectedPeriod.end)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _selectPeriod,
              icon: const Icon(Icons.edit),
              label: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidityRatios(
    FinancialRatiosResult ratios,
    AppLocalizations l10n,
  ) {
    return _buildRatioDataTable(context, [
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.currentRatio,
        value: ratios.currentRatio,
        format: RatioFormat.ratio,
        benchmark: 2.0,
        description: l10n.formulaCurrentRatio,
        goodAbove: 1.5,
        warningBelow: 1.0,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.quickRatio,
        value: ratios.quickRatio,
        format: RatioFormat.ratio,
        benchmark: 1.0,
        description: l10n.formulaQuickRatio,
        goodAbove: 1.0,
        warningBelow: 0.5,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.cashRatio,
        value: ratios.cashRatio,
        format: RatioFormat.ratio,
        benchmark: 0.5,
        description: l10n.formulaCashRatio,
        goodAbove: 0.5,
        warningBelow: 0.2,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: 'Working Capital',
        value: ratios.workingCapital.toDouble(),
        format: RatioFormat.currency,
        description: l10n.formulaWorkingCapital,
        goodAbove: 0,
        warningBelow: 0,
      ),
    ]);
  }

  Widget _buildActivityRatios(
    FinancialRatiosResult ratios,
    AppLocalizations l10n,
  ) {
    return _buildRatioDataTable(context, [
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.inventoryTurnover,
        value: ratios.inventoryTurnover,
        format: RatioFormat.times,
        benchmark: 6.0,
        description: l10n.formulaInventoryTurnover,
        goodAbove: 4.0,
        warningBelow: 2.0,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.daysSalesInInventory,
        value: ratios.daysSalesInInventory.toDouble(),
        format: RatioFormat.days,
        description: l10n.formulaDaysSalesInInventory,
        goodAbove: 0,
        warningBelow: 90,
        invertColors: true, // Lower is better
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.receivablesTurnover,
        value: ratios.receivablesTurnover,
        format: RatioFormat.times,
        benchmark: 8.0,
        description: l10n.formulaReceivablesTurnover,
        goodAbove: 6.0,
        warningBelow: 4.0,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.daysSalesOutstanding,
        value: ratios.daysSalesOutstanding.toDouble(),
        format: RatioFormat.days,
        description: l10n.formulaDaysSalesOutstanding,
        goodAbove: 0,
        warningBelow: 45,
        invertColors: true,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.cashConversionCycle,
        value: ratios.cashConversionCycle.toDouble(),
        format: RatioFormat.days,
        description: l10n.formulaCashConversionCycle,
        goodAbove: 0,
        warningBelow: 60,
        invertColors: true,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.assetTurnover,
        value: ratios.assetTurnover,
        format: RatioFormat.times,
        benchmark: 1.5,
        description: l10n.formulaAssetTurnover,
        goodAbove: 1.0,
        warningBelow: 0.5,
      ),
    ]);
  }

  Widget _buildProfitabilityRatios(
    FinancialRatiosResult ratios,
    AppLocalizations l10n,
  ) {
    return _buildRatioDataTable(context, [
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.grossProfitMargin,
        value: ratios.grossProfitMargin,
        format: RatioFormat.percent,
        benchmark: 0.35,
        description: l10n.formulaGrossProfitMargin,
        goodAbove: 0.30,
        warningBelow: 0.20,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.operatingProfitMargin,
        value: ratios.operatingProfitMargin,
        format: RatioFormat.percent,
        benchmark: 0.15,
        description: l10n.formulaOperatingProfitMargin,
        goodAbove: 0.10,
        warningBelow: 0.05,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.netProfitMargin,
        value: ratios.netProfitMargin,
        format: RatioFormat.percent,
        benchmark: 0.10,
        description: l10n.formulaNetProfitMargin,
        goodAbove: 0.08,
        warningBelow: 0.03,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.returnOnAssets,
        value: ratios.returnOnAssets,
        format: RatioFormat.percent,
        benchmark: 0.10,
        description: l10n.formulaReturnOnAssets,
        goodAbove: 0.08,
        warningBelow: 0.05,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.returnOnEquity,
        value: ratios.returnOnEquity,
        format: RatioFormat.percent,
        benchmark: 0.15,
        description: l10n.formulaReturnOnEquity,
        goodAbove: 0.12,
        warningBelow: 0.08,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.ebitdaMargin,
        value: ratios.ebitdaMargin,
        format: RatioFormat.percent,
        benchmark: 0.20,
        description: l10n.formulaEbitdaMargin,
        goodAbove: 0.15,
        warningBelow: 0.10,
      ),
    ]);
  }

  Widget _buildLeverageRatios(
    FinancialRatiosResult ratios,
    AppLocalizations l10n,
  ) {
    return _buildRatioDataTable(context, [
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.debtToEquityRatio,
        value: ratios.debtToEquityRatio,
        format: RatioFormat.ratio,
        benchmark: 1.0,
        description: l10n.formulaDebtToEquity,
        goodAbove: 0,
        warningBelow: 2.0,
        invertColors: true, // Lower is better
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.debtToAssetsRatio,
        value: ratios.debtToAssetsRatio,
        format: RatioFormat.percent,
        benchmark: 0.40,
        description: l10n.formulaDebtToAssets,
        goodAbove: 0,
        warningBelow: 0.60,
        invertColors: true,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.equityMultiplier,
        value: ratios.equityMultiplier,
        format: RatioFormat.ratio,
        benchmark: 2.0,
        description: l10n.formulaEquityMultiplier,
        goodAbove: 0,
        warningBelow: 3.0,
        invertColors: true,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.interestCoverage,
        value: ratios.interestCoverageRatio,
        format: RatioFormat.times,
        benchmark: 5.0,
        description: l10n.formulaInterestCoverage,
        goodAbove: 3.0,
        warningBelow: 1.5,
      ),
      _buildRatioDataRow(
        l10n: l10n,
        title: l10n.timesInterestEarned,
        value: ratios.timesInterestEarned,
        format: RatioFormat.times,
        benchmark: 5.0,
        description: l10n.formulaTimesInterestEarned,
        goodAbove: 3.0,
        warningBelow: 1.5,
      ),
    ]);
  }

  Widget _buildRatioDataTable(BuildContext context, List<DataRow> rows) {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingTextStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Ratio')),
            DataColumn(label: Text('Value')),
            DataColumn(label: Text('Benchmark')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Description')),
          ],
          rows: rows,
        ),
      ),
    );
  }

  DataRow _buildRatioDataRow({
    required AppLocalizations l10n,
    required String title,
    required double value,
    required RatioFormat format,
    required String description,
    double? benchmark,
    required double goodAbove,
    required double warningBelow,
    bool invertColors = false,
  }) {
    final theme = Theme.of(context);

    // Determine status color
    Color statusColor;
    IconData statusIcon;

    if (invertColors) {
      // For ratios where lower is better
      if (value <= goodAbove || value <= warningBelow) {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      } else if (value > warningBelow * 1.5) {
        statusColor = Colors.red;
        statusIcon = Icons.error;
      } else {
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
      }
    } else {
      // For ratios where higher is better
      if (value >= goodAbove) {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      } else if (value < warningBelow) {
        statusColor = Colors.red;
        statusIcon = Icons.error;
      } else {
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
      }
    }

    final formattedValue = _formatValue(value, format, l10n);
    final formattedBenchmark = benchmark != null
        ? _formatValue(benchmark, format, l10n)
        : '-';

    return DataRow(
      cells: [
        DataCell(
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataCell(
          Text(
            formattedValue,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        DataCell(Text(formattedBenchmark)),
        DataCell(Icon(statusIcon, color: statusColor, size: 24)),
        DataCell(
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              description,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(double value, RatioFormat format, AppLocalizations l10n) {
    if (value.isNaN || value.isInfinite) return l10n.notAvailable;

    switch (format) {
      case RatioFormat.ratio:
        return value.toStringAsFixed(2);
      case RatioFormat.percent:
        return '${(value * 100).toStringAsFixed(1)}%';
      case RatioFormat.times:
        return '${value.toStringAsFixed(1)}x';
      case RatioFormat.days:
        return '${value.round()} ${l10n.daysSuffix}';
      case RatioFormat.currency:
        return '\$${_formatNumber(value)}';
    }
  }

  String _formatNumber(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

enum RatioFormat { ratio, percent, times, days, currency }
