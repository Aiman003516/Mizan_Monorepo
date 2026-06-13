import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_l10n/app_localizations.dart';

class CashFlowChart extends StatelessWidget {
  const CashFlowChart({
    super.key,
    required this.revenue,
    required this.expenses,
  });

  // For now, these are single total values.
  // Ideally, we'd pass a List<FlSpot> for trend data.
  // We will simulate a simple "Week" view for visual appeal.
  final double revenue;
  final double expenses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPositive = revenue >= expenses;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cashFlow,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.currencyFormat(revenue - expenses),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? context.appColors.favorable : context.appColors.unfavorable,
                          ),
                    ),
                  ],
                ),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? context.appColors.favorable : context.appColors.unfavorable,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 120, // Compact chart height
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeBarGroup(0, revenue, context.appColors.favorable),
                    _makeBarGroup(1, expenses, context.appColors.unfavorable),
                  ],
                  // Improved Visuals
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: (revenue > expenses ? revenue : expenses) * 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(color: context.appColors.favorable, label: l10n.totalRevenue),
                _LegendItem(color: context.appColors.unfavorable, label: l10n.totalExpenses),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 24,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: (revenue > expenses ? revenue : expenses) * 1.2,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
