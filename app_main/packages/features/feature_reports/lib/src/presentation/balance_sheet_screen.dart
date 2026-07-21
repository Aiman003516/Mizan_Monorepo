import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_reports/src/data/reports_service.dart';
import 'package:feature_reports/src/data/export_service.dart';

class BalanceSheetScreen extends ConsumerWidget {
  final bool isStandalone;

  const BalanceSheetScreen({super.key, this.isStandalone = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bsDataAsync = ref.watch(balanceSheetProvider);
    final asOfDate = ref.watch(balanceSheetDateProvider);

    return Scaffold(
      appBar: isStandalone
          ? AppBar(
              title: Text(l10n.balanceSheet),
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
            )
          : null,
      body: bsDataAsync.when(
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
                        exportService.printBalanceSheetPdf(data, l10n: l10n);
                      } else if (value == 'excel') {
                        exportService.exportBalanceSheetToExcel(
                          data,
                          l10n: l10n,
                        );
                      }
                    },
                  ),
                ),
              ),
            Expanded(
              child: _buildBalanceSheetBody(context, l10n, data, asOfDate),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildBalanceSheetBody(
    BuildContext context,
    AppLocalizations l10n,
    BalanceSheetData data,
    DateTime asOfDate,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat.yMd();
    final dateString = "${l10n.asOf} ${formatter.format(asOfDate)}";

    const numberStyle = TextStyle(fontFamily: 'Amiri');
    final boldNumberStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontFamily: 'Amiri',
    );
    final assetColor = context.appColors.success;
    final liabilityColor = context.appColors.error;
    final equityColor = context.appColors.success;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          dateString,
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.assets,
          style: textTheme.titleLarge?.copyWith(color: assetColor),
        ),
        const Divider(),
        for (final line in data.assetLines)
          ListTile(
            title: Text(line.accountName),
            trailing: Text(
              l10n.currencyFormat(line.balance),
              style: numberStyle.copyWith(color: assetColor),
            ),
          ),
        ListTile(
          title: Text(
            l10n.totalAssets,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            l10n.currencyFormat(data.totalAssets),
            style: boldNumberStyle?.copyWith(color: assetColor),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.liabilities,
          style: textTheme.titleLarge?.copyWith(color: liabilityColor),
        ),
        const Divider(),
        for (final line in data.liabilityLines)
          ListTile(
            title: Text(line.accountName),
            trailing: Text(
              l10n.currencyFormat(line.balance),
              style: numberStyle.copyWith(color: liabilityColor),
            ),
          ),
        ListTile(
          title: Text(
            l10n.totalLiabilities,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            l10n.currencyFormat(data.totalLiabilities),
            style: boldNumberStyle?.copyWith(color: liabilityColor),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.equity,
          style: textTheme.titleLarge?.copyWith(color: equityColor),
        ),
        const Divider(),
        for (final line in data.equityLines)
          ListTile(
            title: Text(line.accountName),
            trailing: Text(
              l10n.currencyFormat(line.balance),
              style: numberStyle.copyWith(color: equityColor),
            ),
          ),
        ListTile(
          title: Text(
            l10n.totalEquity,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            l10n.currencyFormat(data.totalEquity),
            style: boldNumberStyle?.copyWith(color: equityColor),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(thickness: 2),
        ListTile(
          title: Text(
            l10n.totalLiabilitiesAndEquity,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            l10n.currencyFormat(data.totalLiabilities + data.totalEquity),
            style: boldNumberStyle,
          ),
        ),
      ],
    );
  }
}
