import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_reports/src/data/reports_service.dart';
import 'package:feature_reports/src/data/export_service.dart';

class ProfitAndLossScreen extends ConsumerWidget {
  const ProfitAndLossScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pnlDataAsync = ref.watch(profitAndLossProvider);
    final dateRange = ref.watch(pnlDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profitAndLoss),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: l10n.export,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'pdf', child: Text(l10n.exportToPDF)),
              PopupMenuItem(value: 'excel', child: Text(l10n.exportToExcel)),
            ],
            onSelected: (value) {
              final data = pnlDataAsync.value;
              if (data == null) return;
              final exportService = ref.read(exportServiceProvider);

              if (value == 'pdf') {
                exportService.printPnlPdf(data, l10n: l10n);
              } else if (value == 'excel') {
                exportService.exportPnlToExcel(data, l10n: l10n);
              }
            },
          ),
        ],
      ),
      body: pnlDataAsync.when(
        data: (data) => _buildPnlBody(context, l10n, data, dateRange),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildPnlBody(BuildContext context, AppLocalizations l10n,
      PnlData data, DateTimeRange dateRange) {
    final textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat.yMd();
    final dateString =
        "${formatter.format(dateRange.start)} - ${formatter.format(dateRange.end)}";

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(dateString,
            style: textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),

        Text(l10n.revenue,
            style: textTheme.titleLarge?.copyWith(color: Colors.green)),
        const Divider(),
        for (final line in data.revenueLines)
          ListTile(
            title: Text(line.accountName),
            trailing: Text(l10n.currencyFormat(line.balance),
                style: const TextStyle(
                    fontFamily: 'Amiri')),
          ),
        ListTile(
          title: Text(l10n.totalRevenue,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          trailing: Text(l10n.currencyFormat(data.totalRevenue),
              style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
        ),
        const SizedBox(height: 24),

        Text(l10n.expenses,
            style: textTheme.titleLarge?.copyWith(color: Colors.red)),
        const Divider(),
        for (final line in data.expenseLines)
          ListTile(
            title: Text(line.accountName),
            trailing: Text(l10n.currencyFormat(line.balance),
                style: const TextStyle(fontFamily: 'Amiri')),
          ),
        ListTile(
          title: Text(l10n.totalExpenses,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          trailing: Text(l10n.currencyFormat(data.totalExpenses),
              style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
        ),
        const SizedBox(height: 24),

        const Divider(thickness: 2),
        ListTile(
          title: Text(l10n.netIncome,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          trailing: Text(
            l10n.currencyFormat(data.netIncome),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
              color: data.netIncome >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}