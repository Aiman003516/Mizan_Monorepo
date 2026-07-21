import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_reports/src/data/reports_service.dart';
import 'package:feature_reports/src/data/export_service.dart';

class TrialBalanceScreen extends ConsumerWidget {
  final bool isStandalone;

  const TrialBalanceScreen({super.key, this.isStandalone = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tbDataAsync = ref.watch(trialBalanceProvider);

    return Scaffold(
      appBar: isStandalone
          ? AppBar(
              title: Text(l10n.trialBalance),
              actions: [
                PopupMenuButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: l10n.export,
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'pdf', child: Text(l10n.exportToPDF)),
                    PopupMenuItem(
                      value: 'excel',
                      child: Text(l10n.exportToExcel),
                    ),
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
            )
          : null,
      body: tbDataAsync.when(
        data: (data) => Column(
          children: [
            if (!isStandalone)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: PopupMenuButton<String>(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_outlined),
                      label: Text(l10n.export),
                      onPressed: null, // The PopupMenuButton handles the tap
                    ),
                    tooltip: l10n.export,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pdf',
                        child: Text(l10n.exportToPDF),
                      ),
                      PopupMenuItem(
                        value: 'excel',
                        child: Text(l10n.exportToExcel),
                      ),
                    ],
                    onSelected: (value) {
                      final exportService = ref.read(exportServiceProvider);
                      if (value == 'pdf') {
                        exportService.printTrialBalancePdf(data, l10n: l10n);
                      } else if (value == 'excel') {
                        exportService.exportTrialBalanceToExcel(
                          data,
                          l10n: l10n,
                        );
                      }
                    },
                  ),
                ),
              ),
            Expanded(child: _buildTrialBalanceBody(context, data)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildTrialBalanceBody(
    BuildContext context,
    List<TrialBalanceLine> data,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (final line in data) {
      totalDebit += line.debit;
      totalCredit += line.credit;
    }

    final debitColor = context.appColors.success;
    final creditColor = context.appColors.error;
    const numberStyle = TextStyle(fontFamily: 'Amiri');
    final boldDebitStyle = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
      fontFamily: 'Amiri',
      color: debitColor,
    );
    final boldCreditStyle = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
      fontFamily: 'Amiri',
      color: creditColor,
    );
    final boldHeaderStyle = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: DataTable(
        showBottomBorder: true,
        columns: [
          DataColumn(label: Text(l10n.account, style: boldHeaderStyle)),
          DataColumn(
            label: Text(l10n.debit, style: boldHeaderStyle),
            numeric: true,
          ),
          DataColumn(
            label: Text(l10n.credit, style: boldHeaderStyle),
            numeric: true,
          ),
        ],
        rows: [
          ...data.map(
            (line) => DataRow(
              cells: [
                DataCell(Text(line.accountName)),
                DataCell(
                  Text(
                    line.debit == 0 ? '-' : l10n.currencyFormat(line.debit),
                    style: line.debit > 0
                        ? numberStyle.copyWith(color: debitColor)
                        : numberStyle,
                  ),
                ),
                DataCell(
                  Text(
                    line.credit == 0 ? '-' : l10n.currencyFormat(line.credit),
                    style: line.credit > 0
                        ? numberStyle.copyWith(color: creditColor)
                        : numberStyle,
                  ),
                ),
              ],
            ),
          ),
          DataRow(
            cells: [
              DataCell(Text(l10n.total, style: boldHeaderStyle)),
              DataCell(
                Text(l10n.currencyFormat(totalDebit), style: boldDebitStyle),
              ),
              DataCell(
                Text(l10n.currencyFormat(totalCredit), style: boldCreditStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
