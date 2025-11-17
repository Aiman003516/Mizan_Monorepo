import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_reports/src/data/reports_service.dart';
import 'package:feature_reports/src/data/export_service.dart';

class BalanceSheetScreen extends ConsumerWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bsDataAsync = ref.watch(balanceSheetProvider);
    final asOfDate = ref.watch(balanceSheetDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.balanceSheet),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: l10n.export,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'pdf', child: Text(l10n.exportToPDF)),
              PopupMenuItem(value: 'excel', child: Text(l10n.exportToExcel)),
            ],
            onSelected: (value) {
              final data = bsDataAsync.value;
              if (data == null) return;
              final exportService = ref.read(exportServiceProvider);

              if (value == 'pdf') {
                exportService.printBalanceSheetPdf(data, l10n: l10n);
              } else if (value == 'excel') {
                exportService.exportBalanceSheetToExcel(data, l10n: l10n);
              }
            },
          ),
        ],
      ),
      body: bsDataAsync.when(
        data: (data) => _buildBalanceSheetBody(context, l10n, data, asOfDate),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildBalanceSheetBody(BuildContext context, AppLocalizations l10n,
      BalanceSheetData data, DateTime asOfDate) {
    final textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat.yMd();
    final dateString = "${l10n.asOf} ${formatter.format(asOfDate)}";

    const numberStyle = TextStyle(fontFamily: 'Amiri');
    final boldNumberStyle =
        textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'Amiri');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(dateString,
            style: textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text(l10n.assets,
            style: textTheme.titleLarge?.copyWith(color: Colors.green[700])),
        const Divider(),
        for (final line in data.assetLines)
          ListTile(
            title: Text(line.accountName),
            trailing: Text(l10n.currencyFormat(line.balance), style: numberStyle),
          ),
        ListTile(
          title: Text(l10n.totalAssets,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          trailing:
              Text(l10n.currencyFormat(data.totalAssets), style: boldNumberStyle),
        ),
        const SizedBox(height: 24),
        Text(l10n.liabilities,
            style: textTheme.titleLarge?.copyWith(color: Colors.red[700])),
        const Divider(),
        for (final line in data.liabilityLines)
          ListTile(
            title: Text(line.accountName),
            trailing: Text(l10n.currencyFormat(line.balance), style: numberStyle),
          ),
        ListTile(
          title: Text(l10n.totalLiabilities,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          trailing: Text(l10n.currencyFormat(data.totalLiabilities),
              style: boldNumberStyle),
        ),
        const SizedBox(height: 24),
        Text(l10n.equity,
            style: textTheme.titleLarge?.copyWith(color: Colors.blue[700])),
        const Divider(),
        for (final line in data.equityLines)
          ListTile(
            title: Text(line.accountName),
            trailing: Text(l10n.currencyFormat(line.balance), style: numberStyle),
          ),
        ListTile(
          title: Text(l10n.totalEquity,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          trailing:
              Text(l10n.currencyFormat(data.totalEquity), style: boldNumberStyle),
        ),
        const SizedBox(height: 24),
        const Divider(thickness: 2),
        ListTile(
          title: Text(l10n.totalLiabilitiesAndEquity,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          trailing: Text(
              l10n.currencyFormat(data.totalLiabilities + data.totalEquity),
              style: boldNumberStyle),
        ),
      ],
    );
  }
}