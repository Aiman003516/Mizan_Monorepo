import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/feature_accounts.dart';
import 'package:feature_reports/src/data/report_models.dart';
import 'package:feature_reports/src/data/reports_service.dart' show TrialBalanceLine, PnlData, BalanceSheetData;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref);
});

class ExportService {
  final Ref _ref;
  ExportService(this._ref);

  Future<pw.ThemeData> _loadFonts() async {
    // This is a temporary solution. We'll need to create a shared_assets package
    // or ensure assets are loaded from the main app.
    // For now, this assumes the font asset is available to the runner.
    try {
      final font = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
      final boldFont = await rootBundle.load("assets/fonts/Amiri-Bold.ttf");

      return pw.ThemeData.withFont(
        base: pw.Font.ttf(font),
        bold: pw.Font.ttf(boldFont),
      );
    } catch (e) {
      print("Error loading fonts for PDF: $e");
      print("Falling back to default font.");
      // Fallback theme
      return pw.ThemeData.withFont();
    }
  }

  Future<void> printTotalAmountsPdf(
    List<AccountSummary> summaries,
    String title, {
    required AppLocalizations l10n,
  }) async {
    final pdf = pw.Document();
    final theme = await _loadFonts();
    final isRtl = l10n.localeName == 'ar';
    final alignLeft = isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
    final alignRight = isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (context) => _buildPdfHeader(title, isRtl: isRtl, l10n: l10n),
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              headers: [
                l10n.name,
                l10n.currency,
                l10n.debit,
                l10n.credit,
                l10n.balance
              ],
              data: summaries
                  .map((s) => [
                        s.accountName,
                        s.currencyCode,
                        s.totalDebit.toStringAsFixed(2),
                        s.totalCredit.toStringAsFixed(2),
                        s.netBalance.toStringAsFixed(2),
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: alignLeft,
                1: pw.Alignment.center,
                2: alignRight,
                3: alignRight,
                4: alignRight,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> printMonthlyAmountsPdf(
    List<MonthlySummary> summaries,
    String title, {
    required AppLocalizations l10n,
  }) async {
    final pdf = pw.Document();
    final theme = await _loadFonts();
    final isRtl = l10n.localeName == 'ar';
    final alignLeft = isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
    final alignRight = isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight;

    final dateFormat = DateFormat.MMMM(l10n.localeName);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (context) => _buildPdfHeader(title, isRtl: isRtl, l10n: l10n),
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              headers: [
                l10n.month,
                l10n.year,
                l10n.currency,
                l10n.debit,
                l10n.credit,
                l10n.balance
              ],
              data: summaries
                  .map((s) => [
                        dateFormat.format(DateTime(s.year, s.month)),
                        s.year.toString(),
                        s.currencyCode,
                        s.totalDebit.toStringAsFixed(2),
                        s.totalCredit.toStringAsFixed(2),
                        s.netBalance.toStringAsFixed(2),
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: alignLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: alignRight,
                4: alignRight,
                5: alignRight,
              },
            ),
          ];
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> printAccountActivityPdf(
    List<TransactionDetail> details,
    String title, {
    required AppLocalizations l10n,
  }) async {
    final pdf = pw.Document();
    final theme = await _loadFonts();
    final isRtl = l10n.localeName == 'ar';
    final alignLeft = isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
    final alignRight = isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight;

    final dateFormat = DateFormat.yMd(l10n.localeName);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (context) => _buildPdfHeader(title, isRtl: isRtl, l10n: l10n),
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              headers: [
                l10n.date,
                l10n.account,
                l10n.description,
                l10n.currency,
                l10n.exchangeRateShort,
                l10n.debit,
                l10n.credit
              ],
              data: details
                  .map((d) => [
                        dateFormat.format(d.transactionDate),
                        d.accountName,
                        d.transactionDescription,
                        d.currencyCode,
                        d.currencyRate.toStringAsFixed(2),
                        d.entryAmount > 0
                            ? d.entryAmount.toStringAsFixed(2)
                            : '0.00',
                        d.entryAmount < 0
                            ? d.entryAmount.abs().toStringAsFixed(2)
                            : '0.00',
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: alignLeft,
                1: alignLeft,
                2: alignLeft,
                3: pw.Alignment.center,
                4: alignRight,
                5: alignRight,
                6: alignRight,
              },
            ),
          ];
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> printDashboardPdf(
    List<CalculatedAccountBalance> balances,
    String title, {
    required AppLocalizations l10n,
  }) async {
    final pdf = pw.Document();
    final theme = await _loadFonts();
    final isRtl = l10n.localeName == 'ar';
    final alignLeft = isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
    final alignRight = isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight;

    final allCurrencies = <String>{};
    for (final b in balances) {
      for (final s in b.currencySummaries) {
        allCurrencies.add(s.currencyCode);
      }
    }
    final sortedCurrencies = allCurrencies.toList()..sort();

    final headers = [l10n.accountName, '${l10n.total} (${l10n.local})'];
    headers.addAll(sortedCurrencies);

    final List<List<String>> data = [];
    for (final b in balances) {
      final currencyMap = {
        for (var s in b.currencySummaries) s.currencyCode: s.netBalance
      };

      final row = [
        b.account.name,
        b.totalCombinedBalance.toStringAsFixed(2),
      ];
      row.addAll(sortedCurrencies
          .map((c) => (currencyMap[c] ?? 0.0).toStringAsFixed(2)));
      data.add(row);
    }

    final cellAlignments = <int, pw.Alignment>{
      0: alignLeft,
      1: alignRight,
    };
    for (int i = 0; i < sortedCurrencies.length; i++) {
      cellAlignments[i + 2] = alignRight;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: sortedCurrencies.length > 3
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4,
        theme: theme,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (context) => _buildPdfHeader(title, isRtl: isRtl, l10n: l10n),
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: cellAlignments,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> printPnlPdf(PnlData data,
      {required AppLocalizations l10n}) async {
    final pdf = pw.Document();
    final theme = await _loadFonts();
    final isRtl = l10n.localeName == 'ar';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (context) => _buildPdfHeader(l10n.profitAndLoss, isRtl: isRtl, l10n: l10n),
        build: (pw.Context context) {
          return [
            pw.Text(l10n.revenue,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.Divider(),
            for (final line in data.revenueLines)
              _buildPdfRow(line.accountName, line.balance, isRtl: isRtl, l10n: l10n),
            _buildPdfTotalRow(l10n.totalRevenue, data.totalRevenue, isRtl: isRtl, l10n: l10n),
            pw.SizedBox(height: 24),

            pw.Text(l10n.expenses,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.Divider(),
            for (final line in data.expenseLines)
              _buildPdfRow(line.accountName, line.balance, isRtl: isRtl, l10n: l10n),
            _buildPdfTotalRow(l10n.totalExpenses, data.totalExpenses, isRtl: isRtl, l10n: l10n),
            pw.SizedBox(height: 24),

            pw.Divider(thickness: 2),
            _buildPdfTotalRow(l10n.netIncome, data.netIncome, isRtl: isRtl, l10n: l10n,
                isLarge: true),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> printBalanceSheetPdf(BalanceSheetData data,
      {required AppLocalizations l10n}) async {
    final pdf = pw.Document();
    final theme = await _loadFonts();
    final isRtl = l10n.localeName == 'ar';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (context) => _buildPdfHeader(l10n.balanceSheet, isRtl: isRtl, l10n: l10n),
        build: (pw.Context context) {
          return [
            pw.Text(l10n.assets,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.Divider(),
            for (final line in data.assetLines)
              _buildPdfRow(line.accountName, line.balance, isRtl: isRtl, l10n: l10n),
            _buildPdfTotalRow(l10n.totalAssets, data.totalAssets, isRtl: isRtl, l10n: l10n),
            pw.SizedBox(height: 24),

            pw.Text(l10n.liabilities,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.Divider(),
            for (final line in data.liabilityLines)
              _buildPdfRow(line.accountName, line.balance, isRtl: isRtl, l10n: l10n),
            _buildPdfTotalRow(l10n.totalLiabilities, data.totalLiabilities,
                isRtl: isRtl, l10n: l10n),
            pw.SizedBox(height: 24),

            pw.Text(l10n.equity,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.Divider(),
            for (final line in data.equityLines)
              _buildPdfRow(line.accountName, line.balance, isRtl: isRtl, l10n: l10n),
            _buildPdfTotalRow(l10n.totalEquity, data.totalEquity, isRtl: isRtl, l10n: l10n),
            pw.SizedBox(height: 24),

            pw.Divider(thickness: 2),
            _buildPdfTotalRow(
                l10n.totalLiabilitiesAndEquity,
                data.totalLiabilities + data.totalEquity,
                isRtl: isRtl, l10n: l10n,
                isLarge: true),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> printTrialBalancePdf(List<TrialBalanceLine> data,
      {required AppLocalizations l10n}) async {
    final pdf = pw.Document();
    final theme = await _loadFonts();
    final isRtl = l10n.localeName == 'ar';
    final alignLeft = isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
    final alignRight = isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight;
    final textAlignRight = isRtl ? pw.TextAlign.left : pw.TextAlign.right;

    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (final line in data) {
      totalDebit += line.debit;
      totalCredit += line.credit;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (context) => _buildPdfHeader(l10n.trialBalance, isRtl: isRtl, l10n: l10n),
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              headers: [l10n.account, l10n.debit, l10n.credit],
              data: data
                  .map((line) => [
                        line.accountName,
                        line.debit == 0 ? '-' : l10n.currencyFormat(line.debit),
                        line.credit == 0 ? '-' : l10n.currencyFormat(line.credit),
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: alignLeft,
                1: alignRight,
                2: alignRight,
              },
            ),
            pw.Divider(),
            pw.Row(
              children: [
                pw.Expanded(
                    child: pw.Text(l10n.total,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Container(
                    width: 80,
                    child: pw.Text(l10n.currencyFormat(totalDebit),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: textAlignRight)),
                pw.Container(
                    width: 80,
                    child: pw.Text(l10n.currencyFormat(totalCredit),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: textAlignRight)),
              ],
            )
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfRow(String title, double value,
      {required bool isRtl, required AppLocalizations l10n}) {
    final textAlignLeft = isRtl ? pw.TextAlign.right : pw.TextAlign.left;
    final textAlignRight = isRtl ? pw.TextAlign.left : pw.TextAlign.right;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        children: [
          pw.Expanded(
              child: pw.Text(title,
                  textAlign: textAlignLeft)),
          pw.Text(l10n.currencyFormat(value),
              textAlign: textAlignRight),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTotalRow(String title, double value,
      {required bool isRtl, required AppLocalizations l10n, bool isLarge = false}) {
    final textAlignLeft = isRtl ? pw.TextAlign.right : pw.TextAlign.left;
    final textAlignRight = isRtl ? pw.TextAlign.left : pw.TextAlign.right;

    final style = isLarge
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)
        : pw.TextStyle(fontWeight: pw.FontWeight.bold);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8.0),
      child: pw.Row(
        children: [
          pw.Expanded(
              child: pw.Text(title,
                  style: style,
                  textAlign: textAlignLeft)),
          pw.Text(l10n.currencyFormat(value),
              style: style,
              textAlign: textAlignRight),
        ],
      ),
    );
  }

  Future<void> exportTotalAmountsExcel(
      List<AccountSummary> summaries, String title) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel[excel.getDefaultSheet()!];
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);

    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0),
        customValue: TextCellValue(title));
    sheet.appendRow([
      TextCellValue('Account Name'),
      TextCellValue('Currency'),
      TextCellValue('Debit'),
      TextCellValue('Credit'),
      TextCellValue('Balance'),
    ]);

    for (final s in summaries) {
      sheet.appendRow([
        TextCellValue(s.accountName),
        TextCellValue(s.currencyCode),
        DoubleCellValue(s.totalDebit),
        DoubleCellValue(s.totalCredit),
        DoubleCellValue(s.netBalance),
      ]);
    }
    await _saveAndOpenFile(excel, 'total_amounts_report.xlsx');
  }

  Future<void> exportMonthlyAmountsExcel(
      List<MonthlySummary> summaries, String title) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel[excel.getDefaultSheet()!];
    sheet.setColumnWidth(0, 15);
    sheet.setColumnWidth(1, 10);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 15);

    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
        customValue: TextCellValue(title));
    sheet.appendRow([
      TextCellValue('Month'),
      TextCellValue('Year'),
      TextCellValue('Currency'),
      TextCellValue('Debit'),
      TextCellValue('Credit'),
      TextCellValue('Balance'),
    ]);

    final dateFormat = DateFormat.MMMM();
    for (final s in summaries) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(DateTime(s.year, s.month))),
        IntCellValue(s.year),
        TextCellValue(s.currencyCode),
        DoubleCellValue(s.totalDebit),
        DoubleCellValue(s.totalCredit),
        DoubleCellValue(s.netBalance),
      ]);
    }
    await _saveAndOpenFile(excel, 'monthly_amounts_report.xlsx');
  }

  Future<void> exportAccountActivityExcel(
      List<TransactionDetail> details, String title) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel[excel.getDefaultSheet()!];
    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 25);
    sheet.setColumnWidth(2, 40);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 15);

    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0),
        customValue: TextCellValue(title));
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Account'),
      TextCellValue('Description'),
      TextCellValue('Currency'),
      TextCellValue('Rate'),
      TextCellValue('Debit'),
      TextCellValue('Credit'),
    ]);

    final dateFormat = DateFormat.yMd();
    for (final d in details) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(d.transactionDate)),
        TextCellValue(d.accountName),
        TextCellValue(d.transactionDescription),
        TextCellValue(d.currencyCode),
        DoubleCellValue(d.currencyRate),
        DoubleCellValue(d.entryAmount > 0 ? d.entryAmount : 0.0),
        DoubleCellValue(d.entryAmount < 0 ? d.entryAmount.abs() : 0.0),
      ]);
    }
    await _saveAndOpenFile(excel, 'account_activity_report.xlsx');
  }

  Future<void> exportDashboardExcel(
      List<CalculatedAccountBalance> balances, String title) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel[excel.getDefaultSheet()!];

    final allCurrencies = <String>{};
    for (final b in balances) {
      for (final s in b.currencySummaries) {
        allCurrencies.add(s.currencyCode);
      }
    }
    final sortedCurrencies = allCurrencies.toList()..sort();

    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 18);
    for (int i = 0; i < sortedCurrencies.length; i++) {
      sheet.setColumnWidth(i + 2, 15);
    }

    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(
            columnIndex: 1 + sortedCurrencies.length, rowIndex: 0),
        customValue: TextCellValue(title));

    final headers = [
      TextCellValue('Account Name'),
      TextCellValue('Total (Local)'),
    ];
    headers.addAll(sortedCurrencies.map((c) => TextCellValue(c)));
    sheet.appendRow(headers);

    for (final b in balances) {
      final currencyMap = {
        for (var s in b.currencySummaries) s.currencyCode: s.netBalance
      };
      final row = [
        TextCellValue(b.account.name),
        DoubleCellValue(b.totalCombinedBalance),
      ];
      row.addAll(
          sortedCurrencies.map((c) => DoubleCellValue(currencyMap[c] ?? 0.0)));
      sheet.appendRow(row);
    }
    await _saveAndOpenFile(excel, 'dashboard_balances_report.xlsx');
  }

  Future<void> exportPnlToExcel(PnlData data,
      {required AppLocalizations l10n}) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel[excel.getDefaultSheet()!];
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 18);

    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
        customValue: TextCellValue(l10n.profitAndLoss));

    sheet.appendRow([TextCellValue(l10n.revenue)]);
    for (final line in data.revenueLines) {
      sheet.appendRow([TextCellValue(line.accountName), DoubleCellValue(line.balance)]);
    }
    sheet.appendRow([TextCellValue(l10n.totalRevenue), DoubleCellValue(data.totalRevenue)]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue(l10n.expenses)]);
    for (final line in data.expenseLines) {
      sheet.appendRow([TextCellValue(line.accountName), DoubleCellValue(line.balance)]);
    }
    sheet.appendRow([TextCellValue(l10n.totalExpenses), DoubleCellValue(data.totalExpenses)]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue(l10n.netIncome), DoubleCellValue(data.netIncome)]);

    await _saveAndOpenFile(excel, 'profit_and_loss_report.xlsx');
  }

  Future<void> exportBalanceSheetToExcel(BalanceSheetData data,
      {required AppLocalizations l10n}) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel[excel.getDefaultSheet()!];
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 18);

    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
        customValue: TextCellValue(l10n.balanceSheet));
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue(l10n.assets)]);
    for (final line in data.assetLines) {
      sheet.appendRow([TextCellValue(line.accountName), DoubleCellValue(line.balance)]);
    }
    sheet.appendRow([TextCellValue(l10n.totalAssets), DoubleCellValue(data.totalAssets)]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue(l10n.liabilities)]);
    for (final line in data.liabilityLines) {
      sheet.appendRow([TextCellValue(line.accountName), DoubleCellValue(line.balance)]);
    }
    sheet.appendRow([TextCellValue(l10n.totalLiabilities), DoubleCellValue(data.totalLiabilities)]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue(l10n.equity)]);
    for (final line in data.equityLines) {
      sheet.appendRow([TextCellValue(line.accountName), DoubleCellValue(line.balance)]);
    }
    sheet.appendRow([TextCellValue(l10n.totalEquity), DoubleCellValue(data.totalEquity)]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue(l10n.totalLiabilitiesAndEquity), DoubleCellValue(data.totalLiabilities + data.totalEquity)]);

    await _saveAndOpenFile(excel, 'balance_sheet_report.xlsx');
  }

  Future<void> exportTrialBalanceToExcel(List<TrialBalanceLine> data,
      {required AppLocalizations l10n}) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel[excel.getDefaultSheet()!];
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 18);

    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
        customValue: TextCellValue(l10n.trialBalance));

    sheet.appendRow([
      TextCellValue(l10n.account),
      TextCellValue(l10n.debit),
      TextCellValue(l10n.credit),
    ]);

    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (final line in data) {
      sheet.appendRow([
        TextCellValue(line.accountName),
        DoubleCellValue(line.debit),
        DoubleCellValue(line.credit),
      ]);
      totalDebit += line.debit;
      totalCredit += line.credit;
    }

    sheet.appendRow([
      TextCellValue(l10n.total),
      DoubleCellValue(totalDebit),
      DoubleCellValue(totalCredit),
    ]);

    await _saveAndOpenFile(excel, 'trial_balance_report.xlsx');
  }

  pw.Widget _buildPdfHeader(String title, {required bool isRtl, required AppLocalizations l10n}) {
    return pw.Container(
      alignment: isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.only(bottom: 16.0),
      child: pw.Column(
        crossAxisAlignment:
            isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(l10n.mizanAccounting, // Use l10n key
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              l10n.generatedOn(DateFormat.yMd().add_jm().format(DateTime.now())), // Use l10n key
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  Future<void> _saveAndOpenFile(Excel excel, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final fileBytes = excel.save();
    if (fileBytes != null) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $path';
      }
    }
  }
}