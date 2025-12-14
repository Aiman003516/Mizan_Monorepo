import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

/// 💰 AR/AP Summary Cards Widget
/// Shows accounts receivable and payable summaries side by side.
class ARAPSummaryCards extends ConsumerWidget {
  const ARAPSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arReportAsync = ref.watch(arAgingReportProvider);
    final apReportAsync = ref.watch(apAgingReportProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // AR Card
        Expanded(
          child: arReportAsync.when(
            loading: () => _SummaryCard(
              title: 'Receivables',
              icon: Icons.arrow_downward,
              color: colorScheme.primary,
              isLoading: true,
            ),
            error: (e, _) => _SummaryCard(
              title: 'Receivables',
              icon: Icons.arrow_downward,
              color: colorScheme.primary,
              error: e.toString(),
            ),
            data: (report) => _SummaryCard(
              title: 'Receivables',
              icon: Icons.arrow_downward,
              color: colorScheme.primary,
              total: report.totalReceivables,
              current: report.current,
              overdue:
                  report.days31to60 + report.days61to90 + report.over90Days,
              count: report.customerBalances.length,
              countLabel: 'customers',
            ),
          ),
        ),
        const SizedBox(width: 12),
        // AP Card
        Expanded(
          child: apReportAsync.when(
            loading: () => _SummaryCard(
              title: 'Payables',
              icon: Icons.arrow_upward,
              color: colorScheme.tertiary,
              isLoading: true,
            ),
            error: (e, _) => _SummaryCard(
              title: 'Payables',
              icon: Icons.arrow_upward,
              color: colorScheme.tertiary,
              error: e.toString(),
            ),
            data: (report) => _SummaryCard(
              title: 'Payables',
              icon: Icons.arrow_upward,
              color: colorScheme.tertiary,
              total: report.totalPayables,
              current: report.current,
              overdue:
                  report.days31to60 + report.days61to90 + report.over90Days,
              count: report.vendorBalances.length,
              countLabel: 'vendors',
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int? total;
  final int? current;
  final int? overdue;
  final int? count;
  final String? countLabel;
  final bool isLoading;
  final String? error;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.color,
    this.total,
    this.current,
    this.overdue,
    this.count,
    this.countLabel,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : error != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(title: title, icon: icon),
                const SizedBox(height: 8),
                Text(
                  'Error',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(title: title, icon: icon),
                const SizedBox(height: 12),
                Text(
                  '\$${((total ?? 0) / 100).toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Current vs Overdue bar
                if ((total ?? 0) > 0) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: current ?? 1,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      if ((overdue ?? 0) > 0)
                        Expanded(
                          flex: overdue ?? 0,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.red.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        'Overdue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade200,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${count ?? 0} $countLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final IconData icon;

  const _Header({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
