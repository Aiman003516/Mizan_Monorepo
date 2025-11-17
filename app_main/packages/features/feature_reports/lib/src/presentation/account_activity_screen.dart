import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_database/core_database.dart' as c;
import 'package:feature_reports/src/data/report_models.dart';
import 'package:feature_reports/src/data/reports_service.dart';
import 'package:feature_reports/src/data/export_service.dart';

class AccountActivityScreen extends ConsumerStatefulWidget {
  const AccountActivityScreen({super.key});

  @override
  ConsumerState<AccountActivityScreen> createState() =>
      _AccountActivityScreenState();
}

class _AccountActivityScreenState extends ConsumerState<AccountActivityScreen> {
  ReportFilter _selectedReportFilter = ReportFilter.ALL;
  String _selectedClassification = c.kClassificationGeneral;

  Widget _buildExportButtons(
    List<TransactionDetail> details,
    String title,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: l10n.exportToPDF,
            onPressed: () {
              ref
                  .read(exportServiceProvider)
                  .printAccountActivityPdf(details, title, l10n: l10n);
            },
          ),
          IconButton(
            icon: Icon(Icons.description, color: Colors.green.shade700),
            tooltip: l10n.exportToExcel,
            onPressed: () {
              ref
                  .read(exportServiceProvider)
                  .exportAccountActivityExcel(details, title);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.excelExportSuccess)),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          color: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).primaryColor,
          child: Column(
            children: [
              TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: l10n.general),
                  Tab(text: l10n.clients),
                  Tab(text: l10n.suppliers),
                ],
                onTap: (index) {
                  setState(() {
                    _selectedClassification = [
                      c.kClassificationGeneral,
                      c.kClassificationClients,
                      c.kClassificationSuppliers
                    ][index];
                  });
                },
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: SegmentedButton<ReportFilter>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    selectedBackgroundColor: Colors.white,
                    selectedForegroundColor: Theme.of(context).primaryColor,
                  ),
                  segments: [
                    ButtonSegment(
                        value: ReportFilter.ALL,
                        label: Text(l10n.all),
                        icon: const Icon(Icons.all_inclusive)),
                    ButtonSegment(
                        value: ReportFilter.POS_ONLY,
                        label: Text(l10n.posSales),
                        icon: const Icon(Icons.point_of_sale)),
                    ButtonSegment(
                        value: ReportFilter.ACCOUNTS_ONLY,
                        label: Text(l10n.accounts),
                        icon: const Icon(Icons.account_balance_wallet)),
                  ],
                  selected: {_selectedReportFilter},
                  onSelectionChanged: (Set<ReportFilter> newSelection) {
                    setState(() {
                      _selectedReportFilter = newSelection.first;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _AccountActivityList(
                filter: TotalAmountsFilter(
                  reportFilter: _selectedReportFilter,
                  classificationName: c.kClassificationGeneral,
                ),
                exportBuilder: (details) => _buildExportButtons(
                  details,
                  '${l10n.accountActivity} - ${l10n.general}',
                ),
              ),
              _AccountActivityList(
                filter: TotalAmountsFilter(
                  reportFilter: _selectedReportFilter,
                  classificationName: c.kClassificationClients,
                ),
                exportBuilder: (details) => _buildExportButtons(
                  details,
                  '${l10n.accountActivity} - ${l10n.clients}',
                ),
              ),
              _AccountActivityList(
                filter: TotalAmountsFilter(
                  reportFilter: _selectedReportFilter,
                  classificationName: c.kClassificationSuppliers,
                ),
                exportBuilder: (details) => _buildExportButtons(
                  details,
                  '${l10n.accountActivity} - ${l10n.suppliers}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountActivityList extends ConsumerWidget {
  final TotalAmountsFilter filter;
  final Widget Function(List<TransactionDetail>) exportBuilder;

  const _AccountActivityList({
    required this.filter,
    required this.exportBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ledgerAsync = ref.watch(filteredTransactionDetailsProvider(filter));

    return ledgerAsync.when(
      data: (details) {
        if (details.isEmpty) {
          return Center(child: Text(l10n.noTransactionEntries));
        }

        return Column(
          children: [
            exportBuilder(details),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return _buildNarrowLayout(details, l10n);
                  } else {
                    return _buildWideLayout(details, l10n);
                  }
                },
              ),
            ),
          ],
        );
      },
      error: (err, stack) => Center(child: Text('${l10n.error} ${err.toString()}')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNarrowLayout(List<TransactionDetail> details, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.date)),
          DataColumn(label: Text(l10n.account)),
          DataColumn(label: Text(l10n.description)),
          DataColumn(label: Text(l10n.debit), numeric: true),
          DataColumn(label: Text(l10n.credit), numeric: true),
          DataColumn(label: Text(l10n.currency)),
        ],
        rows: details.map((detail) {
          final isDebit = detail.entryAmount > 0;
          return DataRow(
            cells: [
              DataCell(Text(DateFormat.yMd().format(detail.transactionDate))),
              DataCell(Text(detail.accountName)),
              DataCell(Text(detail.transactionDescription)),
              DataCell(
                Text(
                  isDebit ? detail.entryAmount.toStringAsFixed(2) : '',
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.right,
                ),
              ),
              DataCell(
                Text(
                  !isDebit ? detail.entryAmount.abs().toStringAsFixed(2) : '',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.right,
                ),
              ),
              DataCell(Text(detail.currencyCode)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWideLayout(List<TransactionDetail> details, AppLocalizations l10n) {
    return Column(
      children: [
        _buildWideHeader(l10n),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: details.length,
            itemBuilder: (context, index) {
              final detail = details[index];
              return _buildWideRow(detail);
            },
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildWideHeader(AppLocalizations l10n) {
    Widget headerText(String text,
        {required int flex, TextAlign align = TextAlign.start}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Row(
      children: [
        headerText(flex: 2, l10n.date),
        headerText(flex: 3, l10n.account),
        headerText(flex: 4, l10n.description),
        headerText(flex: 2, l10n.debit, align: TextAlign.end),
        headerText(flex: 2, l10n.credit, align: TextAlign.end),
        headerText(flex: 2, l10n.currency, align: TextAlign.end),
      ],
    );
  }

  Widget _buildWideRow(TransactionDetail detail) {
    final isDebit = detail.entryAmount > 0;

    Widget cellText(String text,
        {required int flex, TextAlign align = TextAlign.start, Color? color}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Text(
            text,
            textAlign: align,
            style: TextStyle(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Row(
      children: [
        cellText(flex: 2, DateFormat.yMd().format(detail.transactionDate)),
        cellText(flex: 3, detail.accountName),
        cellText(flex: 4, detail.transactionDescription),
        cellText(
          flex: 2,
          isDebit ? detail.entryAmount.toStringAsFixed(2) : '',
          align: TextAlign.end,
          color: Colors.green,
        ),
        cellText(
          flex: 2,
          !isDebit ? detail.entryAmount.abs().toStringAsFixed(2) : '',
          align: TextAlign.end,
          color: Colors.red,
        ),
        cellText(flex: 2, detail.currencyCode, align: TextAlign.end),
      ],
    );
  }
}