import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_reports/src/data/inventory_repository.dart';
import 'package:shared_ui/shared_ui.dart';

DateTimeRange _defaultOperationsRange() {
  final today = DateTime.now();
  final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
  return DateTimeRange(start: end.subtract(const Duration(days: 30)), end: end);
}

class LowStockReportScreen extends ConsumerWidget {
  const LowStockReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(reorderAlertsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lowStockAlertTitle),
        actions: [
          IconButton(
            tooltip: l10n.refreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(reorderAlertsProvider),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ReportError(message: l10n.errorLoadingData),
        data: (products) {
          if (products.isEmpty) {
            return _ReportEmpty(message: l10n.reportNoData);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              final isOut = product.quantityOnHand <= 0;
              final statusColor = isOut
                  ? colorScheme.error
                  : colorScheme.tertiary;
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    foregroundColor: statusColor,
                    child: Icon(
                      isOut ? Icons.remove_shopping_cart : Icons.warning_amber,
                    ),
                  ),
                  title: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${l10n.currentStock}: ${product.quantityOnHand}  •  '
                    '${l10n.reorderPoint}: ${product.reorderPoint}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  trailing: Text(
                    isOut ? l10n.outOfStock : l10n.lowStock,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
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

class StockVelocityReportScreen extends ConsumerWidget {
  const StockVelocityReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final range = _defaultOperationsRange();
    final velocityAsync = ref.watch(productVelocityProvider(range));
    final currencyCode = ref.watch(currentCurrencyCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stockVelocityTitle),
        actions: [
          IconButton(
            tooltip: l10n.refreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productVelocityProvider(range)),
          ),
        ],
      ),
      body: velocityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ReportError(message: l10n.errorLoadingData),
        data: (products) {
          if (products.isEmpty) {
            return _ReportEmpty(message: l10n.reportNoData);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            child: Text('${index + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text('${l10n.soldQuantity}: ${product.quantitySold}'),
                          Text('${l10n.currentStock}: ${product.currentStock}'),
                          Text(
                            '${l10n.totalRevenue}: ${CurrencyFormatter.formatAmount((product.totalRevenue * 100).round(), currencyCode)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class TaxLiabilityReportScreen extends ConsumerWidget {
  const TaxLiabilityReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final range = _defaultOperationsRange();
    final taxAsync = ref.watch(taxLiabilityProvider(range));
    final currencyCode = ref.watch(currentCurrencyCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taxLiabilityTitle),
        actions: [
          IconButton(
            tooltip: l10n.refreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(taxLiabilityProvider(range)),
          ),
        ],
      ),
      body: taxAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ReportError(message: l10n.errorLoadingData),
        data: (summary) {
          final values = [
            _TaxMetric(
              label: l10n.salesTaxCollected,
              amount: summary.salesTaxCents,
              color: Theme.of(context).colorScheme.primary,
            ),
            _TaxMetric(
              label: l10n.purchaseTaxPaid,
              amount: summary.purchaseTaxCents,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            _TaxMetric(
              label: l10n.netTaxDue,
              amount: summary.netTaxDueCents,
              color: summary.netTaxDueCents >= 0
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.tertiary,
            ),
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            children: [
              Text(
                l10n.dateRange,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_shortDate(range.start)} – ${_shortDate(range.end)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ...values.map(
                (metric) =>
                    _TaxMetricCard(metric: metric, currencyCode: currencyCode),
              ),
              const SizedBox(height: 8),
              _CountSummary(
                label: l10n.reportInvoicesCount(summary.invoiceCount),
                icon: Icons.receipt_long_outlined,
              ),
              _CountSummary(
                label: l10n.reportBillsCount(summary.billCount),
                icon: Icons.receipt_outlined,
              ),
            ],
          );
        },
      ),
    );
  }
}

class SalesByCashierReportScreen extends ConsumerWidget {
  const SalesByCashierReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final range = _defaultOperationsRange();
    final salesAsync = ref.watch(cashierSalesProvider(range));
    final currencyCode = ref.watch(currentCurrencyCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesByCashierTitle),
        actions: [
          IconButton(
            tooltip: l10n.refreshTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(cashierSalesProvider(range)),
          ),
        ],
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ReportError(message: l10n.errorLoadingData),
        data: (summaries) {
          if (summaries.isEmpty) {
            return _ReportEmpty(message: l10n.reportNoData);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            itemCount: summaries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final summary = summaries[index];
              final cashier = summary.cashierId == 'unassigned'
                  ? l10n.unassigned
                  : summary.cashierId;
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                    child: const Icon(Icons.badge_outlined),
                  ),
                  title: Text(
                    cashier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: summary.cashierId == 'unassigned'
                        ? null
                        : TextDirection.ltr,
                  ),
                  subtitle: Text(
                    l10n.ordersCount(summary.orderCount),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      CurrencyFormatter.formatAmount(
                        summary.totalSalesCents,
                        currencyCode,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

class _TaxMetric {
  const _TaxMetric({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;
}

class _TaxMetricCard extends StatelessWidget {
  const _TaxMetricCard({required this.metric, required this.currencyCode});

  final _TaxMetric metric;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: metric.color.withValues(alpha: 0.12),
          foregroundColor: metric.color,
          child: const Icon(Icons.calculate_outlined),
        ),
        title: Text(metric.label),
        trailing: Text(
          CurrencyFormatter.formatAmount(metric.amount, currencyCode),
          style: TextStyle(color: metric.color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _CountSummary extends StatelessWidget {
  const _CountSummary({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _ReportEmpty extends StatelessWidget {
  const _ReportEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
