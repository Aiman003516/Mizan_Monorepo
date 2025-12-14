// FILE: packages/features/feature_reports/lib/src/presentation/tools/financial_ratios_screen.dart
// Purpose: Financial Ratios Dashboard for comprehensive ratio analysis

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Ratios'),
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
        data: (ratios) => _buildRatiosDashboard(context, ratios),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading ratios', style: theme.textTheme.titleMedium),
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
            'Liquidity Ratios',
            Icons.water_drop,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildLiquidityRatios(ratios),
          const SizedBox(height: 24),

          // Activity Ratios
          _buildSectionHeader(
            context,
            'Activity Ratios',
            Icons.speed,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildActivityRatios(ratios),
          const SizedBox(height: 24),

          // Profitability Ratios
          _buildSectionHeader(
            context,
            'Profitability Ratios',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildProfitabilityRatios(ratios),
          const SizedBox(height: 24),

          // Leverage Ratios
          _buildSectionHeader(
            context,
            'Leverage Ratios',
            Icons.balance,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildLeverageRatios(ratios),
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
            color: color.withOpacity(0.1),
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

  Widget _buildLiquidityRatios(FinancialRatiosResult ratios) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildRatioCard(
          title: 'Current Ratio',
          value: ratios.currentRatio,
          format: RatioFormat.ratio,
          benchmark: 2.0,
          description: 'Current Assets ÷ Current Liabilities',
          goodAbove: 1.5,
          warningBelow: 1.0,
        ),
        _buildRatioCard(
          title: 'Quick Ratio',
          value: ratios.quickRatio,
          format: RatioFormat.ratio,
          benchmark: 1.0,
          description: '(Cash + Receivables) ÷ Current Liabilities',
          goodAbove: 1.0,
          warningBelow: 0.5,
        ),
        _buildRatioCard(
          title: 'Cash Ratio',
          value: ratios.cashRatio,
          format: RatioFormat.ratio,
          benchmark: 0.5,
          description: 'Cash ÷ Current Liabilities',
          goodAbove: 0.5,
          warningBelow: 0.2,
        ),
        _buildRatioCard(
          title: 'Working Capital',
          value: ratios.workingCapital.toDouble(),
          format: RatioFormat.currency,
          description: 'Current Assets - Current Liabilities',
          goodAbove: 0,
          warningBelow: 0,
        ),
      ],
    );
  }

  Widget _buildActivityRatios(FinancialRatiosResult ratios) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildRatioCard(
          title: 'Inventory Turnover',
          value: ratios.inventoryTurnover,
          format: RatioFormat.times,
          benchmark: 6.0,
          description: 'COGS ÷ Average Inventory',
          goodAbove: 4.0,
          warningBelow: 2.0,
        ),
        _buildRatioCard(
          title: 'Days Sales in Inventory',
          value: ratios.daysSalesInInventory.toDouble(),
          format: RatioFormat.days,
          description: '365 ÷ Inventory Turnover',
          goodAbove: 0,
          warningBelow: 90,
          invertColors: true, // Lower is better
        ),
        _buildRatioCard(
          title: 'Receivables Turnover',
          value: ratios.receivablesTurnover,
          format: RatioFormat.times,
          benchmark: 8.0,
          description: 'Net Sales ÷ Average Receivables',
          goodAbove: 6.0,
          warningBelow: 4.0,
        ),
        _buildRatioCard(
          title: 'Days Sales Outstanding',
          value: ratios.daysSalesOutstanding.toDouble(),
          format: RatioFormat.days,
          description: '365 ÷ Receivables Turnover',
          goodAbove: 0,
          warningBelow: 45,
          invertColors: true,
        ),
        _buildRatioCard(
          title: 'Cash Conversion Cycle',
          value: ratios.cashConversionCycle.toDouble(),
          format: RatioFormat.days,
          description: 'DSI + DSO - DPO',
          goodAbove: 0,
          warningBelow: 60,
          invertColors: true,
        ),
        _buildRatioCard(
          title: 'Asset Turnover',
          value: ratios.assetTurnover,
          format: RatioFormat.times,
          benchmark: 1.5,
          description: 'Net Sales ÷ Average Total Assets',
          goodAbove: 1.0,
          warningBelow: 0.5,
        ),
      ],
    );
  }

  Widget _buildProfitabilityRatios(FinancialRatiosResult ratios) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildRatioCard(
          title: 'Gross Profit Margin',
          value: ratios.grossProfitMargin,
          format: RatioFormat.percent,
          benchmark: 0.35,
          description: '(Revenue - COGS) ÷ Revenue',
          goodAbove: 0.30,
          warningBelow: 0.20,
        ),
        _buildRatioCard(
          title: 'Operating Profit Margin',
          value: ratios.operatingProfitMargin,
          format: RatioFormat.percent,
          benchmark: 0.15,
          description: 'Operating Income ÷ Revenue',
          goodAbove: 0.10,
          warningBelow: 0.05,
        ),
        _buildRatioCard(
          title: 'Net Profit Margin',
          value: ratios.netProfitMargin,
          format: RatioFormat.percent,
          benchmark: 0.10,
          description: 'Net Income ÷ Revenue',
          goodAbove: 0.08,
          warningBelow: 0.03,
        ),
        _buildRatioCard(
          title: 'Return on Assets (ROA)',
          value: ratios.returnOnAssets,
          format: RatioFormat.percent,
          benchmark: 0.10,
          description: 'Net Income ÷ Average Total Assets',
          goodAbove: 0.08,
          warningBelow: 0.05,
        ),
        _buildRatioCard(
          title: 'Return on Equity (ROE)',
          value: ratios.returnOnEquity,
          format: RatioFormat.percent,
          benchmark: 0.15,
          description: 'Net Income ÷ Average Equity',
          goodAbove: 0.12,
          warningBelow: 0.08,
        ),
        _buildRatioCard(
          title: 'EBITDA Margin',
          value: ratios.ebitdaMargin,
          format: RatioFormat.percent,
          benchmark: 0.20,
          description: 'EBITDA ÷ Revenue',
          goodAbove: 0.15,
          warningBelow: 0.10,
        ),
      ],
    );
  }

  Widget _buildLeverageRatios(FinancialRatiosResult ratios) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildRatioCard(
          title: 'Debt-to-Equity Ratio',
          value: ratios.debtToEquityRatio,
          format: RatioFormat.ratio,
          benchmark: 1.0,
          description: 'Total Liabilities ÷ Shareholders\' Equity',
          goodAbove: 0,
          warningBelow: 2.0,
          invertColors: true, // Lower is better
        ),
        _buildRatioCard(
          title: 'Debt-to-Assets Ratio',
          value: ratios.debtToAssetsRatio,
          format: RatioFormat.percent,
          benchmark: 0.40,
          description: 'Total Liabilities ÷ Total Assets',
          goodAbove: 0,
          warningBelow: 0.60,
          invertColors: true,
        ),
        _buildRatioCard(
          title: 'Equity Multiplier',
          value: ratios.equityMultiplier,
          format: RatioFormat.ratio,
          benchmark: 2.0,
          description: 'Total Assets ÷ Shareholders\' Equity',
          goodAbove: 0,
          warningBelow: 3.0,
          invertColors: true,
        ),
        _buildRatioCard(
          title: 'Interest Coverage',
          value: ratios.interestCoverageRatio == double.infinity
              ? 999
              : ratios.interestCoverageRatio,
          format: RatioFormat.times,
          benchmark: 5.0,
          description: 'EBIT ÷ Interest Expense',
          goodAbove: 3.0,
          warningBelow: 1.5,
        ),
        _buildRatioCard(
          title: 'Times Interest Earned',
          value: ratios.timesInterestEarned == double.infinity
              ? 999
              : ratios.timesInterestEarned,
          format: RatioFormat.times,
          benchmark: 5.0,
          description: '(Net Income + Interest + Tax) ÷ Interest',
          goodAbove: 3.0,
          warningBelow: 1.5,
        ),
      ],
    );
  }

  Widget _buildRatioCard({
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

    return SizedBox(
      width: 200,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(statusIcon, color: statusColor, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _formatValue(value, format),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              if (benchmark != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Benchmark: ${_formatValue(benchmark, format)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double value, RatioFormat format) {
    if (value.isNaN || value.isInfinite) return 'N/A';

    switch (format) {
      case RatioFormat.ratio:
        return value.toStringAsFixed(2);
      case RatioFormat.percent:
        return '${(value * 100).toStringAsFixed(1)}%';
      case RatioFormat.times:
        return '${value.toStringAsFixed(1)}x';
      case RatioFormat.days:
        return '${value.round()} days';
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
