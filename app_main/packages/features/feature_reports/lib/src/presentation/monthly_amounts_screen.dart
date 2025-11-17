import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_database/core_database.dart' as c;
import 'package:feature_reports/src/data/report_models.dart';
import 'package:feature_reports/src/data/reports_service.dart';
import 'package:feature_reports/src/data/export_service.dart';

// We will create this package soon. This error is expected.
import 'package:feature_dashboard/feature_dashboard.dart';

class MonthlyAmountsScreen extends ConsumerStatefulWidget {
  const MonthlyAmountsScreen({super.key});

  @override
  ConsumerState<MonthlyAmountsScreen> createState() =>
      _MonthlyAmountsScreenState();
}

class _MonthlyAmountsScreenState extends ConsumerState<MonthlyAmountsScreen> {
  ReportFilter _selectedReportFilter = ReportFilter.ALL;
  String _selectedClassification = c.kClassificationGeneral;

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildExportButtons(
    List<MonthlySummary> summaries,
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
                  .printMonthlyAmountsPdf(summaries, title, l10n: l10n);
            },
          ),
          IconButton(
            icon: Icon(Icons.description, color: Colors.green.shade700),
            tooltip: l10n.exportToExcel,
            onPressed: () {
              ref
                  .read(exportServiceProvider)
                  .exportMonthlyAmountsExcel(summaries, title);
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

    // This provider will be defined in feature_dashboard. This error is expected.
    final searchQuery = ref.watch(mainDashboardSearchProvider); 

    final filter = TotalAmountsFilter(
      reportFilter: _selectedReportFilter,
      classificationName: _selectedClassification,
    );

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
              _MonthlyAmountsListView(
                filter: filter.copyWith(
                    classificationName: c.kClassificationGeneral),
                searchQuery: searchQuery,
                exportBuilder: (summaries) => _buildExportButtons(
                  summaries,
                  l10n.monthlyAmounts(c.kClassificationGeneral),
                ),
              ),
              _MonthlyAmountsListView(
                filter: filter.copyWith(
                    classificationName: c.kClassificationClients),
                searchQuery: searchQuery,
                exportBuilder: (summaries) => _buildExportButtons(
                  summaries,
                  l10n.monthlyAmounts(c.kClassificationClients),
                ),
              ),
              _MonthlyAmountsListView(
                filter: filter.copyWith(
                    classificationName: c.kClassificationSuppliers),
                searchQuery: searchQuery,
                exportBuilder: (summaries) => _buildExportButtons(
                  summaries,
                  l10n.monthlyAmounts(c.kClassificationSuppliers),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyAmountsListView extends ConsumerWidget {
  final TotalAmountsFilter filter;
  final String searchQuery;
  final Widget Function(List<MonthlySummary>) exportBuilder;

  const _MonthlyAmountsListView({
    required this.filter,
    required this.searchQuery,
    required this.exportBuilder,
  });

  String _getMonthName(int month, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateTime(DateTime.now().year, month, 1);
    return DateFormat.MMMM(locale).format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(monthlyAmountsSummaryProvider(filter));

    return summaryAsync.when(
      data: (summaries) {
        final filteredSummaries = summaries.where((summary) {
          if (searchQuery.isEmpty) return true;
          final monthName = _getMonthName(summary.month, context).toLowerCase();
          final year = summary.year.toString();
          final query = searchQuery.toLowerCase();
          return monthName.contains(query) || year.contains(query);
        }).toList();

        if (filteredSummaries.isEmpty) {
          return Center(
              child: Text(searchQuery.isEmpty
                  ? l10n.noMonthlyTotals
                  : l10n.noResultsFound(searchQuery)));
        }

        return Column(
          children: [
            exportBuilder(filteredSummaries),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(l10n.month,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      flex: 2,
                      child: Text(l10n.debit,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end)),
                  Expanded(
                      flex: 2,
                      child: Text(l10n.credit,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end)),
                  Expanded(
                      flex: 2,
                      child: Text(l10n.balance,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: filteredSummaries.length,
                itemBuilder: (context, index) {
                  final summary = filteredSummaries[index];
                  final isDebitBalance = summary.netBalance >= 0;
                  final balanceColor =
                      isDebitBalance ? Colors.red : Colors.green;
                  final monthName = _getMonthName(summary.month, context);

                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    title: Text('$monthName ${summary.year}'),
                    subtitle: Text('${l10n.currencyLabel} ${summary.currencyCode}',
                        style:
                            TextStyle(color: Theme.of(context).primaryColor)),
                    onTap: () {},
                    trailing: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text(
                                  summary.totalDebit.toStringAsFixed(2),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: Colors.green))),
                          Expanded(
                              flex: 2,
                              child: Text(
                                  summary.totalCredit.toStringAsFixed(2),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: Colors.red))),
                          Expanded(
                              flex: 2,
                              child: Text(
                                  summary.netBalance.abs().toStringAsFixed(2),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: balanceColor))),
                        ],
                      ),
                    ),
                  );
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
}