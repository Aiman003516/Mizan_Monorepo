import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_reports/src/data/reports_service.dart';
import 'package:feature_reports/src/data/export_service.dart';

class TrialBalanceScreen extends ConsumerWidget {
  const TrialBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tbDataAsync = ref.watch(trialBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trialBalance),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: l10n.export,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'pdf', child: Text(l10n.exportToPDF)),
              PopupMenuItem(value: 'excel', child: Text(l10n.exportToExcel)),
            ],
            onSelected: (value) {
              final data = tbDataAsync.value;
              if (data == null) return;
              final exportService = ref.read(exportServiceProvider);

              if (value == 'pdf') {
                exportService.printTrialBalancePdf(data, l10n: l10n);
              } else if (value == 'excel') {
                exportService.exportTrialBalanceToExcel(data, l10n: l10n);
              }
            },
          ),
        ],
      ),
      body: tbDataAsync.when(
        data: (data) => _buildTrialBalanceBody(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildTrialBalanceBody(
      BuildContext context, List<TrialBalanceLine> data) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (final line in data) {
      totalDebit += line.debit;
      totalCredit += line.credit;
    }

    const numberStyle = TextStyle(fontFamily: 'Amiri');
    final boldNumberStyle =
        textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'Amiri');
    final boldHeaderStyle = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: DataTable(
        showBottomBorder: true,
        columns: [
          DataColumn(
              label: Text(l10n.account,
                  style: boldHeaderStyle)),
          DataColumn(
              label: Text(l10n.debit,
                  style: boldHeaderStyle),
              numeric: true),
          DataColumn(
              label: Text(l10n.credit,
                  style: boldHeaderStyle),
              numeric: true),
        ],
        rows: [
          ...data.map(
            (line) => DataRow(
              cells: [
                DataCell(Text(line.accountName)),
                DataCell(Text(
                    line.debit == 0
                        ? '-'
                        : l10n.currencyFormat(line.debit),
                    style: numberStyle)),
                DataCell(Text(
                    line.credit == 0
                        ? '-'
                        : l10n.currencyFormat(line.credit),
                    style: numberStyle)),
              ],
            ),
          ),
          DataRow(
            cells: [
              DataCell(
                  Text(l10n.total, style: boldHeaderStyle)),
              DataCell(Text(l10n.currencyFormat(totalDebit),
                  style: boldNumberStyle)),
              DataCell(Text(l10n.currencyFormat(totalCredit),
                  style: boldNumberStyle)),
            ],
          ),
        ],
      ),
    );
  }
}